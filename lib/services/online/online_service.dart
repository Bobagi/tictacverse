import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/cpu_difficulty.dart';
import '../../models/game_mode.dart';
import '../../models/online_match.dart';
import '../progression_engine.dart';
import '../progression_service.dart';
import 'fake_online_api.dart';
import 'online_api.dart';

/// Regras de recompensa do online, puras e com relógio injetável (mesmo
/// padrão do ProgressionEngine). Cada partida paga UMA vez, só se foi jogada
/// de verdade, e há teto diário: sem isso dois aparelhos combinados virariam
/// fábrica de XP e moedas.
class OnlineRewardRules {
  const OnlineRewardRules();

  /// Jogadas mínimas para a partida contar (3 de cada lado).
  static const int minMoves = 6;

  /// Partidas online que rendem XP por dia.
  static const int dailyCap = 15;

  static const int _remember = 200;

  /// Devolve o resultado a creditar, ou null se não paga. Muta [ledger].
  OnlineOutcome? claim(
      OnlineMatch match, OnlineRewardLedger ledger, DateTime now) {
    final OnlineOutcome? outcome = match.outcome;
    if (outcome == null || match.moves.length < minMoves) {
      return null;
    }
    if (ledger.paid.contains(match.id)) {
      return null;
    }
    final String today = _day(now);
    if (ledger.day != today) {
      ledger.day = today;
      ledger.countToday = 0;
    }
    // Marca como vista mesmo acima do teto: não paga depois, na virada do dia.
    ledger.paid.add(match.id);
    while (ledger.paid.length > _remember) {
      ledger.paid.removeAt(0);
    }
    if (ledger.countToday >= dailyCap) {
      return null;
    }
    ledger.countToday++;
    return outcome;
  }

  static String _day(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}

class OnlineRewardLedger {
  OnlineRewardLedger({List<String>? paid, this.day = '', this.countToday = 0})
      : paid = paid ?? <String>[];

  final List<String> paid;
  String day;
  int countToday;
}

/// Porta do app para o online: guarda o token anônimo, fala com o servidor,
/// sabe quais partidas já pagaram e recebe o código que chegou por link.
class OnlineService {
  OnlineService._();

  static final OnlineService instance = OnlineService._();

  static const bool _fake = bool.fromEnvironment('FAKE_ONLINE');

  OnlineApi api = _fake ? FakeOnlineApi() : HttpOnlineApi();

  static const String _tokenKey = 'online.token';
  static const String _paidKey = 'online.rewarded';
  static const String _dayKey = 'online.rewardDay';
  static const String _countKey = 'online.rewardCount';

  /// Código de convite que chegou por link e ainda não foi aberto.
  final ValueNotifier<String?> pendingCode = ValueNotifier<String?>(null);

  /// Partidas em que é a vez do jogador (selo na home).
  final ValueNotifier<int> myTurnCount = ValueNotifier<int>(0);

  final ValueNotifier<OnlineProfile?> profile =
      ValueNotifier<OnlineProfile?>(null);

  DateTime Function() clock = DateTime.now;

  Future<String>? _registering;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Só existe token depois do primeiro uso do online: quem nunca abriu o modo
  /// não manda nada ao servidor.
  Future<bool> get hasAccount async =>
      ((await _prefs).getString(_tokenKey) ?? '').isNotEmpty;

  Future<String> _token() async {
    final String? saved = (await _prefs).getString(_tokenKey);
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    return _registering ??= () async {
      try {
        final OnlineRegistration r = await api.register();
        await (await _prefs).setString(_tokenKey, r.token);
        profile.value = r.profile;
        return r.token;
      } finally {
        _registering = null;
      }
    }();
  }

  /// Roda [call] com o token; se o servidor não conhece mais o token (dados
  /// apagados, banco zerado), cadastra de novo uma vez.
  Future<T> _authed<T>(Future<T> Function(String token) call) async {
    try {
      return await call(await _token());
    } on OnlineApiException catch (e) {
      if (e.status != 401) {
        rethrow;
      }
      await (await _prefs).remove(_tokenKey);
      return call(await _token());
    }
  }

  Future<OnlineProfile> refreshProfile() async {
    final OnlineProfile p = await _authed(api.me);
    profile.value = p;
    return p;
  }

  Future<List<OnlineMatch>> myMatches() async {
    final List<OnlineMatch> list = await _authed(api.matches);
    myTurnCount.value = list.where((OnlineMatch m) => m.isMyTurn).length;
    return list;
  }

  /// Selo da home sem cadastrar ninguém: só pergunta se já tem conta.
  Future<void> refreshBadge() async {
    if (!await hasAccount) {
      return;
    }
    try {
      await myMatches();
    } catch (_) {
      // Sem rede: o selo fica como estava.
    }
  }

  Future<OnlineMatch> create() => _authed(api.create);

  Future<OnlineMatch> join(String code) =>
      _authed((String t) => api.join(t, code));

  Future<OnlineMatch> fetch(String id, {int? since}) =>
      _authed((String t) => api.fetch(t, id, since: since));

  Future<OnlineMatch> move(String id, int board, int cell, int version) =>
      _authed((String t) => api.move(t, id, board, cell, version));

  Future<OnlineMatch> resign(String id) =>
      _authed((String t) => api.resign(t, id));

  Future<OnlineMatch> rematch(String id) =>
      _authed((String t) => api.rematch(t, id));

  /// Apaga tudo do online no servidor e no aparelho. Sem conta, nada a fazer.
  Future<void> deleteMyData() async {
    final SharedPreferences prefs = await _prefs;
    final String? token = prefs.getString(_tokenKey);
    if (token != null && token.isNotEmpty) {
      try {
        await api.deleteMe(token);
      } on OnlineApiException catch (e) {
        if (e.status != 401) {
          rethrow;
        }
      }
    }
    await prefs.remove(_tokenKey);
    profile.value = null;
    myTurnCount.value = 0;
  }

  /// Credita XP e moedas de uma partida terminada, uma vez só. Devolve o que
  /// mudou (para o modal de fim) ou null se a partida não paga.
  Future<ProgressionResult?> settleReward(OnlineMatch match) async {
    final SharedPreferences prefs = await _prefs;
    final OnlineRewardLedger ledger = OnlineRewardLedger(
      paid: prefs.getStringList(_paidKey),
      day: prefs.getString(_dayKey) ?? '',
      countToday: prefs.getInt(_countKey) ?? 0,
    );
    final int paidBefore = ledger.paid.length;
    final OnlineOutcome? outcome =
        const OnlineRewardRules().claim(match, ledger, clock());
    if (ledger.paid.length != paidBefore || outcome != null) {
      await prefs.setStringList(_paidKey, ledger.paid);
      await prefs.setString(_dayKey, ledger.day);
      await prefs.setInt(_countKey, ledger.countToday);
    }
    if (outcome == null) {
      return null;
    }
    return ProgressionService.instance.registerMatch(MatchOutcome(
      mode: GameModeType.ultimate2,
      // Online é contra gente: a vitória vale XP de vitória, mas não entra nas
      // sequências e conquistas "contra a máquina".
      vsCpu: false,
      difficulty: CpuDifficulty.medium,
      humanWon: outcome == OnlineOutcome.win,
      isDraw: outcome == OnlineOutcome.draw,
    ));
  }

  /// Extrai o código de um link de convite (https ou tictacverse://).
  static String? codeFromLink(String? link) {
    if (link == null) {
      return null;
    }
    final Uri? uri = Uri.tryParse(link.trim());
    if (uri == null) {
      return null;
    }
    final List<String> parts = <String>[
      if (uri.scheme == 'tictacverse' && uri.host == 'm') ...uri.pathSegments,
      if ((uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host == 'tictacverse.bobagi.space' &&
          uri.pathSegments.length == 2 &&
          uri.pathSegments.first == 'm')
        uri.pathSegments.last,
    ];
    if (parts.length != 1) {
      return null;
    }
    return normalizeCode(parts.single);
  }

  /// Código digitado ou colado: maiúsculas, sem espaço/traço; null se inválido.
  static String? normalizeCode(String raw) {
    final String code = raw.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}$').hasMatch(code)
        ? code
        : null;
  }

  static String linkFor(String code) =>
      'https://tictacverse.bobagi.space/m/$code';
}

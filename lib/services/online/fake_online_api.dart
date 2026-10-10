import 'dart:async';
import 'dart:math';

import '../../controllers/modes/ultimate2_engine.dart';
import '../../models/online_match.dart';
import '../../models/player_marker.dart';
import 'online_api.dart';

/// Servidor de mentira, em memória, com um "amigo" robô que entra no convite e
/// joga sozinho. Serve aos testes de widget e ao QA visual na web
/// (`--dart-define=FAKE_ONLINE=true`); nunca vai para a loja.
class FakeOnlineApi implements OnlineApi {
  FakeOnlineApi({
    this.friendJoinsAfter = const Duration(seconds: 8),
    this.friendThinks = const Duration(milliseconds: 1200),
    this.autoFriend = true,
    Random? random,
  }) : _random = random ?? Random(7);

  final Duration friendJoinsAfter;
  final Duration friendThinks;
  final bool autoFriend;
  final Random _random;

  final Map<String, _FakeMatch> _matches = <String, _FakeMatch>{};
  final StreamController<String> _changes =
      StreamController<String>.broadcast();
  int _wins = 0, _losses = 0, _draws = 0;
  int _seq = 0;
  bool deleted = false;

  static const String token = 'fake-token-0000000000000000000000000000000000';

  @override
  Future<OnlineRegistration> register() async {
    deleted = false;
    return const OnlineRegistration(token, OnlineProfile(avatar: 0, tag: 42));
  }

  @override
  Future<OnlineProfile> me(String t) async {
    _auth(t);
    return OnlineProfile(
        avatar: 0, tag: 42, wins: _wins, losses: _losses, draws: _draws);
  }

  @override
  Future<void> deleteMe(String t) async {
    _auth(t);
    deleted = true;
    _matches.clear();
  }

  void _auth(String t) {
    if (t != token || deleted) {
      throw const OnlineApiException(401, 'unauthorized');
    }
  }

  @override
  Future<List<OnlineMatch>> matches(String t) async {
    _auth(t);
    final List<_FakeMatch> list = _matches.values.toList()
      ..sort(
          (_FakeMatch a, _FakeMatch b) => b.updatedAt.compareTo(a.updatedAt));
    return list.map((_FakeMatch m) => m.view()).toList();
  }

  @override
  Future<OnlineMatch> create(String t) async {
    _auth(t);
    final _FakeMatch m = _FakeMatch(
      id: (++_seq).toRadixString(16).padLeft(20, '0'),
      code: 'K7P${_seq.toString().padLeft(3, '2')}'.substring(0, 6),
      you: PlayerMarker.cross,
    );
    _matches[m.id] = m;
    if (autoFriend) {
      Timer(friendJoinsAfter, () => friendJoins(m.id));
    }
    return m.view();
  }

  /// O "amigo" aceita o convite (os testes chamam direto).
  void friendJoins(String id) {
    final _FakeMatch? m = _matches[id];
    if (m == null || m.status != OnlineStatus.waiting) {
      return;
    }
    m.status = OnlineStatus.active;
    m.opponent = const OnlineOpponent(avatar: 5, tag: 77);
    _touch(m);
    _scheduleFriend(m);
  }

  @override
  Future<OnlineMatch> join(String t, String code) async {
    _auth(t);
    if (code == 'ZZZZZZ') {
      throw const OnlineApiException(404, 'not_found');
    }
    final _FakeMatch m = _FakeMatch(
      id: (++_seq).toRadixString(16).padLeft(20, '0'),
      code: code,
      you: PlayerMarker.nought,
    )
      ..status = OnlineStatus.active
      ..opponent = const OnlineOpponent(avatar: 11, tag: 31);
    _matches[m.id] = m;
    _scheduleFriend(m);
    return m.view();
  }

  @override
  Future<OnlineMatch> fetch(String t, String id, {int? since}) async {
    _auth(t);
    final _FakeMatch? m = _matches[id];
    if (m == null) {
      throw const OnlineApiException(404, 'not_found');
    }
    if (since != null && m.version <= since) {
      await _changes.stream
          .firstWhere((String changed) => changed == id)
          .timeout(const Duration(seconds: 25), onTimeout: () => id);
    }
    return m.view();
  }

  @override
  Future<OnlineMatch> move(
      String t, String id, int board, int cell, int version) async {
    _auth(t);
    final _FakeMatch m = _matches[id]!;
    if (m.version != version) {
      throw OnlineApiException(409, 'stale', match: m.view());
    }
    final OnlineMatch v = m.view();
    if (!v.isMyTurn || !v.toState().isCellPlayable(board, cell)) {
      throw OnlineApiException(409, 'illegal_move', match: v);
    }
    _apply(m, board, cell);
    _scheduleFriend(m);
    return m.view();
  }

  @override
  Future<OnlineMatch> resign(String t, String id) async {
    _auth(t);
    final _FakeMatch m = _matches[id]!;
    if (m.status == OnlineStatus.waiting) {
      m.status = OnlineStatus.expired;
      m.endReason = 'cancelled';
    } else if (m.status == OnlineStatus.active) {
      _finish(m, m.you == PlayerMarker.cross ? 'o' : 'x', 'resign');
    }
    _touch(m);
    return m.view();
  }

  @override
  Future<OnlineMatch> rematch(String t, String id) async {
    _auth(t);
    final _FakeMatch prev = _matches[id]!;
    if (prev.rematchId != null) {
      return _matches[prev.rematchId]!.view();
    }
    final _FakeMatch next = _FakeMatch(
      id: (++_seq).toRadixString(16).padLeft(20, '0'),
      code: 'R${_seq.toString().padLeft(5, '2')}',
      you: prev.you.opponent,
    )
      ..status = OnlineStatus.active
      ..opponent = prev.opponent
      ..rematchOf = prev.id;
    _matches[next.id] = next;
    prev.rematchId = next.id;
    _touch(prev);
    _scheduleFriend(next);
    return next.view();
  }

  void _scheduleFriend(_FakeMatch m) {
    if (!autoFriend) {
      return;
    }
    final OnlineMatch v = m.view();
    if (v.status != OnlineStatus.active || v.isMyTurn) {
      return;
    }
    Timer(friendThinks, () => friendMoves(m.id));
  }

  /// O "amigo" faz uma jogada legal qualquer (os testes chamam direto).
  void friendMoves(String id) {
    final _FakeMatch? m = _matches[id];
    if (m == null) {
      return;
    }
    final OnlineMatch v = m.view();
    if (v.status != OnlineStatus.active || v.isMyTurn) {
      return;
    }
    final Ultimate2State state = v.toState();
    final List<(int, int)> legal = <(int, int)>[
      for (int b = 0; b < 9; b++)
        for (int c = 0; c < 9; c++)
          if (state.isCellPlayable(b, c)) (b, c),
    ];
    if (legal.isEmpty) {
      return;
    }
    final (int, int) pick = legal[_random.nextInt(legal.length)];
    _apply(m, pick.$1, pick.$2);
  }

  void _apply(_FakeMatch m, int board, int cell) {
    m.moves.add((board, cell));
    final Ultimate2State after = m.view().toState();
    if (after.result.isFinal) {
      _finish(
        m,
        after.result.winner == null
            ? 'draw'
            : (after.result.winner == PlayerMarker.cross ? 'x' : 'o'),
        after.result.winner == null ? 'draw' : 'line',
      );
    }
    _touch(m);
  }

  void _finish(_FakeMatch m, String result, String reason) {
    m.status = OnlineStatus.finished;
    m.result = result;
    m.endReason = reason;
    final OnlineOutcome? o = m.view().outcome;
    if (o == OnlineOutcome.win) {
      _wins++;
    } else if (o == OnlineOutcome.loss) {
      _losses++;
    } else {
      _draws++;
    }
  }

  void _touch(_FakeMatch m) {
    m.version++;
    m.updatedAt = DateTime.now();
    _changes.add(m.id);
  }
}

class _FakeMatch {
  _FakeMatch({required this.id, required this.code, required this.you});

  final String id;
  final String code;
  final PlayerMarker you;
  OnlineStatus status = OnlineStatus.waiting;
  OnlineOpponent? opponent;
  final List<(int, int)> moves = <(int, int)>[];
  int version = 1;
  String? result;
  String? endReason;
  String? rematchId;
  String? rematchOf;
  DateTime updatedAt = DateTime.now();

  OnlineMatch view() => OnlineMatch(
        id: id,
        code: code,
        status: status,
        you: you,
        opponent: opponent,
        moves: List<(int, int)>.of(moves),
        version: version,
        result: result,
        endReason: endReason,
        deadline: DateTime.now().add(const Duration(days: 3)),
        rematchId: rematchId,
        rematchOf: rematchOf,
        updatedAt: updatedAt,
      );
}

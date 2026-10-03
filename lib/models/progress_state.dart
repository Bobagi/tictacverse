import 'dart:math' as math;

import 'game_mode.dart';

/// Estado persistido da progressão (XP, contadores e conquistas desbloqueadas).
///
/// Fica separado do [StorageService] de propósito: o motor de progressão opera
/// sobre este objeto sem tocar em `shared_preferences`, então dá para testar a
/// regra inteira sem plugin nem widget.
class ProgressState {
  ProgressState({
    this.xp = 0,
    this.matches = 0,
    this.cpuWins = 0,
    this.ultimateWins = 0,
    this.hardWins = 0,
    this.currentWinStreak = 0,
    this.bestWinStreak = 0,
    this.dailyStreak = 0,
    this.bestDailyStreak = 0,
    this.hasFastWin = false,
    this.lastPlayedDay,
    this.coins = 0,
    this.equippedSkin = defaultSkinId,
    this.lastDailyClaimDay,
    this.dailyClaimStreak = 0,
    this.adCoinsDay,
    this.adCoinsClaimsToday = 0,
    Set<GameModeType>? modesPlayed,
    Set<String>? unlockedAchievements,
    Set<String>? ownedSkins,
  })  : modesPlayed = modesPlayed ?? <GameModeType>{},
        unlockedAchievements = unlockedAchievements ?? <String>{},
        ownedSkins = ownedSkins ?? <String>{defaultSkinId};

  /// Visual de peças que todo jogador tem desde o início.
  static const String defaultSkinId = 'aurora';

  /// XP acumulado. Só cresce; o nível é derivado dele.
  int xp;

  /// Partidas concluídas em qualquer modo, contra a máquina ou contra amigo.
  int matches;

  /// Vitórias do humano **contra a máquina** (ver nota no catálogo).
  int cpuWins;

  /// Vitórias contra a máquina no Super Jogo da Velha.
  int ultimateWins;

  /// Vitórias contra a máquina com a dificuldade no Impossível.
  int hardWins;

  int currentWinStreak;
  int bestWinStreak;

  /// Dias consecutivos com pelo menos uma partida.
  int dailyStreak;
  int bestDailyStreak;

  /// Venceu o Clássico com o mínimo de jogadas possível (3).
  bool hasFastWin;

  /// Último dia jogado, no formato `yyyy-mm-dd` em horário local.
  String? lastPlayedDay;

  final Set<GameModeType> modesPlayed;
  final Set<String> unlockedAchievements;

  /// Moedas: ganhas jogando, no bônus diário e em anúncio premiado opt-in;
  /// gastas só na loja de visuais. Nunca ficam negativas.
  int coins;

  /// Visuais de peça comprados (o padrão sempre incluso) e o que está em uso.
  final Set<String> ownedSkins;
  String equippedSkin;

  /// Último dia (`yyyy-mm-dd`, local) em que o bônus diário foi resgatado e
  /// quantos dias seguidos o jogador resgatou até ele.
  String? lastDailyClaimDay;
  int dailyClaimStreak;

  /// Teto diário das moedas por anúncio premiado na loja: dia da contagem e
  /// quantos resgates já foram feitos nele.
  String? adCoinsDay;
  int adCoinsClaimsToday;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'xp': xp,
        'matches': matches,
        'cpuWins': cpuWins,
        'ultimateWins': ultimateWins,
        'hardWins': hardWins,
        'currentWinStreak': currentWinStreak,
        'bestWinStreak': bestWinStreak,
        'dailyStreak': dailyStreak,
        'bestDailyStreak': bestDailyStreak,
        'hasFastWin': hasFastWin,
        'lastPlayedDay': lastPlayedDay,
        'modesPlayed': modesPlayed.map((GameModeType m) => m.name).toList(),
        'unlocked': unlockedAchievements.toList(),
        'coins': coins,
        'ownedSkins': ownedSkins.toList(),
        'equippedSkin': equippedSkin,
        'lastDailyClaimDay': lastDailyClaimDay,
        'dailyClaimStreak': dailyClaimStreak,
        'adCoinsDay': adCoinsDay,
        'adCoinsClaimsToday': adCoinsClaimsToday,
      };

  /// Leitura tolerante a campo com tipo errado.
  ///
  /// Cada campo cai no padrão por conta própria em vez de lançar: um `cast`
  /// estourando aqui seria engolido pelo `try` do [StorageService] e apagaria a
  /// progressão INTEIRA por causa de um único valor estranho.
  static ProgressState fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ProgressState();
    }
    final Set<GameModeType> modes = <GameModeType>{};
    for (final Object? raw in _asList(json['modesPlayed'])) {
      for (final GameModeType mode in GameModeType.values) {
        if (mode.name == raw) {
          modes.add(mode);
        }
      }
    }
    return ProgressState(
      xp: _asInt(json['xp']),
      matches: _asInt(json['matches']),
      cpuWins: _asInt(json['cpuWins']),
      ultimateWins: _asInt(json['ultimateWins']),
      hardWins: _asInt(json['hardWins']),
      currentWinStreak: _asInt(json['currentWinStreak']),
      bestWinStreak: _asInt(json['bestWinStreak']),
      dailyStreak: _asInt(json['dailyStreak']),
      bestDailyStreak: _asInt(json['bestDailyStreak']),
      hasFastWin: json['hasFastWin'] is bool && json['hasFastWin'] as bool,
      lastPlayedDay: json['lastPlayedDay'] is String
          ? json['lastPlayedDay'] as String
          : null,
      modesPlayed: modes,
      unlockedAchievements: <String>{
        for (final Object? raw in _asList(json['unlocked']))
          if (raw is String) raw,
      },
      coins: math.max(0, _asInt(json['coins'])),
      ownedSkins: <String>{
        defaultSkinId,
        for (final Object? raw in _asList(json['ownedSkins']))
          if (raw is String) raw,
      },
      equippedSkin: json['equippedSkin'] is String
          ? json['equippedSkin'] as String
          : defaultSkinId,
      lastDailyClaimDay: _asString(json['lastDailyClaimDay']),
      dailyClaimStreak: _asInt(json['dailyClaimStreak']),
      adCoinsDay: _asString(json['adCoinsDay']),
      adCoinsClaimsToday: _asInt(json['adCoinsClaimsToday']),
    );
  }

  static int _asInt(Object? value) => value is num ? value.toInt() : 0;

  static String? _asString(Object? value) => value is String ? value : null;

  static List<Object?> _asList(Object? value) =>
      value is List<Object?> ? value : const <Object?>[];
}

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
    Set<GameModeType>? modesPlayed,
    Set<String>? unlockedAchievements,
  })  : modesPlayed = modesPlayed ?? <GameModeType>{},
        unlockedAchievements = unlockedAchievements ?? <String>{};

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
      lastPlayedDay:
          json['lastPlayedDay'] is String ? json['lastPlayedDay'] as String : null,
      modesPlayed: modes,
      unlockedAchievements: <String>{
        for (final Object? raw in _asList(json['unlocked']))
          if (raw is String) raw,
      },
    );
  }

  static int _asInt(Object? value) => value is num ? value.toInt() : 0;

  static List<Object?> _asList(Object? value) =>
      value is List<Object?> ? value : const <Object?>[];
}

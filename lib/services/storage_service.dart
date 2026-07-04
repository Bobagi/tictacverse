import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cpu_difficulty.dart';
import '../models/game_mode.dart';
import '../models/game_result.dart';
import '../models/player_marker.dart';

class ModeStats {
  ModeStats({this.matches = 0, this.xWins = 0, this.oWins = 0, this.draws = 0});

  int matches;
  int xWins;
  int oWins;
  int draws;

  Map<String, int> toJson() => <String, int>{
        'matches': matches,
        'xWins': xWins,
        'oWins': oWins,
        'draws': draws,
      };

  static ModeStats fromJson(Map<String, dynamic>? json) => ModeStats(
        matches: (json?['matches'] as num?)?.toInt() ?? 0,
        xWins: (json?['xWins'] as num?)?.toInt() ?? 0,
        oWins: (json?['oWins'] as num?)?.toInt() ?? 0,
        draws: (json?['draws'] as num?)?.toInt() ?? 0,
      );
}

/// Persistência local (shared_preferences): estatísticas de partidas,
/// preferências de áudio/idioma/dificuldade e flags (pedido de avaliação).
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _statsKey = 'stats.v1';
  static const String _mutedKey = 'settings.muted';
  static const String _volumeKey = 'settings.volume';
  static const String _localeKey = 'settings.locale';
  static const String _difficultyKey = 'settings.cpuDifficulty';
  static const String _vsCpuKey = 'settings.playAgainstCpu';
  static const String _sessionsKey = 'meta.sessions';
  static const String _reviewAskedKey = 'meta.reviewAsked.v1';

  SharedPreferences? _prefs;

  final Map<GameModeType, ModeStats> statsByMode = <GameModeType, ModeStats>{
    for (final GameModeType mode in GameModeType.values) mode: ModeStats(),
  };
  int cpuWins = 0;
  int cpuLosses = 0;
  int cpuDraws = 0;
  int winStreak = 0;
  int bestWinStreak = 0;
  int sessions = 0;

  bool get isLoaded => _prefs != null;

  int get totalMatches =>
      statsByMode.values.fold(0, (int sum, ModeStats stats) => sum + stats.matches);

  bool get reviewAsked => _prefs?.getBool(_reviewAskedKey) ?? false;
  bool get audioMuted => _prefs?.getBool(_mutedKey) ?? false;
  double get audioVolume => _prefs?.getDouble(_volumeKey) ?? 1.0;
  String? get localeCode => _prefs?.getString(_localeKey);
  bool get playAgainstCpu => _prefs?.getBool(_vsCpuKey) ?? false;
  CpuDifficulty get cpuDifficulty => cpuDifficultyFromName(_prefs?.getString(_difficultyKey));

  Future<void> load() async {
    if (isLoaded) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _parseStats(prefs.getString(_statsKey));
    sessions = (prefs.getInt(_sessionsKey) ?? 0) + 1;
    await prefs.setInt(_sessionsKey, sessions);
  }

  void _parseStats(String? raw) {
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, dynamic>? modes = data['modes'] as Map<String, dynamic>?;
      for (final GameModeType mode in GameModeType.values) {
        statsByMode[mode] =
            ModeStats.fromJson(modes?[mode.name] as Map<String, dynamic>?);
      }
      cpuWins = (data['cpuWins'] as num?)?.toInt() ?? 0;
      cpuLosses = (data['cpuLosses'] as num?)?.toInt() ?? 0;
      cpuDraws = (data['cpuDraws'] as num?)?.toInt() ?? 0;
      winStreak = (data['winStreak'] as num?)?.toInt() ?? 0;
      bestWinStreak = (data['bestWinStreak'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // Dados corrompidos: recomeça as estatísticas em vez de quebrar o app.
    }
  }

  Future<void> _saveStats() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await prefs.setString(
      _statsKey,
      jsonEncode(<String, dynamic>{
        'modes': <String, dynamic>{
          for (final MapEntry<GameModeType, ModeStats> entry in statsByMode.entries)
            entry.key.name: entry.value.toJson(),
        },
        'cpuWins': cpuWins,
        'cpuLosses': cpuLosses,
        'cpuDraws': cpuDraws,
        'winStreak': winStreak,
        'bestWinStreak': bestWinStreak,
      }),
    );
  }

  /// Registra o fim de uma partida. No modo vs CPU o humano é sempre o X.
  void recordMatch({
    required GameModeType mode,
    required GameResult result,
    required bool vsCpu,
  }) {
    final ModeStats stats = statsByMode[mode]!;
    stats.matches += 1;
    if (result.resolution == GameResolution.draw) {
      stats.draws += 1;
    } else if (result.winner == PlayerMarker.cross) {
      stats.xWins += 1;
    } else if (result.winner == PlayerMarker.nought) {
      stats.oWins += 1;
    }

    if (vsCpu) {
      if (result.resolution == GameResolution.victory &&
          result.winner == PlayerMarker.cross) {
        cpuWins += 1;
        winStreak += 1;
        if (winStreak > bestWinStreak) {
          bestWinStreak = winStreak;
        }
      } else if (result.resolution == GameResolution.victory) {
        cpuLosses += 1;
        winStreak = 0;
      } else {
        cpuDraws += 1;
        winStreak = 0;
      }
    }
    _saveStats();
  }

  Future<void> markReviewAsked() async {
    await _prefs?.setBool(_reviewAskedKey, true);
  }

  Future<void> saveAudioSettings({required bool muted, required double volume}) async {
    await _prefs?.setBool(_mutedKey, muted);
    await _prefs?.setDouble(_volumeKey, volume);
  }

  Future<void> saveLocale(String languageCode) async {
    await _prefs?.setString(_localeKey, languageCode);
  }

  Future<void> saveCpuDifficulty(CpuDifficulty difficulty) async {
    await _prefs?.setString(_difficultyKey, difficulty.name);
  }

  Future<void> savePlayAgainstCpu(bool value) async {
    await _prefs?.setBool(_vsCpuKey, value);
  }
}

import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cpu_difficulty.dart';
import '../models/game_mode.dart';
import '../models/game_result.dart';
import '../models/player_marker.dart';
import '../models/progress_state.dart';

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
  static const String _hapticsKey = 'settings.haptics';
  static const String _localeKey = 'settings.locale';
  static const String _langSuggestedKey = 'settings.langSuggested';
  static const String _difficultyKey = 'settings.cpuDifficulty';
  static const String _vsCpuKey = 'settings.playAgainstCpu';
  static const String _sessionsKey = 'meta.sessions';
  static const String _reviewAskedKey = 'meta.reviewAsked.v1';
  static const String _progressKey = 'progress.v1';
  static const String _installIdKey = 'meta.installId';
  static const String _lastPingDayKey = 'meta.lastPingDay';
  static const String _starterShowsKey = 'offer.starter.shows';
  static const String _starterLastDayKey = 'offer.starter.lastDay';
  static const String _tutorialUltimateKey = 'tutorial.ultimate2.done';

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

  /// Progressão (XP, nível e conquistas). Guardada numa chave própria para que
  /// um dado de estatística corrompido não leve a progressão junto.
  ProgressState progress = ProgressState();

  bool get isLoaded => _prefs != null;

  int get totalMatches => statsByMode.values
      .fold(0, (int sum, ModeStats stats) => sum + stats.matches);

  bool get reviewAsked => _prefs?.getBool(_reviewAskedKey) ?? false;
  bool get audioMuted => _prefs?.getBool(_mutedKey) ?? false;
  double get audioVolume => _prefs?.getDouble(_volumeKey) ?? 1.0;

  /// Vibração de resposta (haptics). Ligada por padrão: é parte do "juice".
  bool get hapticsEnabled => _prefs?.getBool(_hapticsKey) ?? true;
  String? get localeCode => _prefs?.getString(_localeKey);
  bool get playAgainstCpu => _prefs?.getBool(_vsCpuKey) ?? false;
  CpuDifficulty get cpuDifficulty =>
      cpuDifficultyFromName(_prefs?.getString(_difficultyKey));

  Future<void> load() async {
    if (isLoaded) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    _parseStats(prefs.getString(_statsKey));
    _parseProgress(prefs.getString(_progressKey));
    sessions = (prefs.getInt(_sessionsKey) ?? 0) + 1;
    await prefs.setInt(_sessionsKey, sessions);
  }

  void _parseProgress(String? raw) {
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      progress =
          ProgressState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Dados corrompidos: recomeça a progressão em vez de quebrar o app.
      progress = ProgressState();
    }
  }

  Future<void> saveProgress() async {
    await _prefs?.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  void _parseStats(String? raw) {
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, dynamic>? modes =
          data['modes'] as Map<String, dynamic>?;
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
          for (final MapEntry<GameModeType, ModeStats> entry
              in statsByMode.entries)
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

  /// Id aleatório desta instalação (UUID v4), criado na primeira abertura.
  /// Não identifica a pessoa nem o aparelho: some ao desinstalar. O servidor
  /// de compras usa para amarrar a compra a quem a fez, e o ping diário para
  /// medir retenção.
  String get installId {
    final String? stored = _prefs?.getString(_installIdKey);
    if (stored != null && isValidInstallId(stored)) {
      return stored;
    }
    final String created = newInstallId();
    _prefs?.setString(_installIdKey, created);
    return created;
  }

  static final RegExp _uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  static bool isValidInstallId(String value) => _uuidV4.hasMatch(value);

  /// UUID v4 com gerador criptográfico (o id não pode ser adivinhado).
  static String newInstallId([Random? random]) {
    final Random rng = random ?? Random.secure();
    final List<int> b = List<int>.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final String hex =
        b.map((int v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  String? get lastPingDay => _prefs?.getString(_lastPingDayKey);
  Future<void> saveLastPingDay(String day) async =>
      _prefs?.setString(_lastPingDayKey, day);

  int get starterOfferShows => _prefs?.getInt(_starterShowsKey) ?? 0;
  String? get starterOfferLastDay => _prefs?.getString(_starterLastDayKey);
  Future<void> markStarterOfferShown(String day) async {
    await _prefs?.setInt(_starterShowsKey, starterOfferShows + 1);
    await _prefs?.setString(_starterLastDayKey, day);
  }

  bool get ultimateTutorialDone =>
      _prefs?.getBool(_tutorialUltimateKey) ?? false;
  Future<void> markUltimateTutorialDone() async =>
      _prefs?.setBool(_tutorialUltimateKey, true);

  Future<void> markReviewAsked() async {
    await _prefs?.setBool(_reviewAskedKey, true);
  }

  Future<void> saveAudioSettings(
      {required bool muted, required double volume}) async {
    await _prefs?.setBool(_mutedKey, muted);
    await _prefs?.setDouble(_volumeKey, volume);
  }

  Future<void> saveHapticsEnabled(bool value) async {
    await _prefs?.setBool(_hapticsKey, value);
  }

  Future<void> saveLocale(String languageCode) async {
    await _prefs?.setString(_localeKey, languageCode);
  }

  bool get languageSuggestionShown =>
      _prefs?.getBool(_langSuggestedKey) ?? false;

  Future<void> markLanguageSuggestionShown() async {
    await _prefs?.setBool(_langSuggestedKey, true);
  }

  Future<void> saveCpuDifficulty(CpuDifficulty difficulty) async {
    await _prefs?.setString(_difficultyKey, difficulty.name);
  }

  Future<void> savePlayAgainstCpu(bool value) async {
    await _prefs?.setBool(_vsCpuKey, value);
  }
}

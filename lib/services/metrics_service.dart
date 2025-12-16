import '../models/game_mode.dart';

class MetricsService {
  int totalMatches = 0;
  int sessionsStarted = 0;
  final Map<GameModeType, int> matchesPerMode = <GameModeType, int>{
    GameModeType.classic: 0,
    GameModeType.shift: 0,
    GameModeType.chaos: 0,
    GameModeType.ultimateMini: 0,
  };
  int adsShown = 0;

  void recordMatch(GameModeType mode) {
    totalMatches += 1;
    matchesPerMode[mode] = (matchesPerMode[mode] ?? 0) + 1;
  }

  void recordSessionStart() {
    sessionsStarted += 1;
  }

  void recordAdImpression() {
    adsShown += 1;
  }
}

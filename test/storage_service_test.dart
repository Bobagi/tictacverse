import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictacverse/models/game_mode.dart';
import 'package:tictacverse/models/game_result.dart';
import 'package:tictacverse/models/player_marker.dart';
import 'package:tictacverse/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('records matches, streak and best streak vs CPU', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final StorageService storage = StorageService.instance;
      await storage.load();

      GameResult win() => GameResult(
          resolution: GameResolution.victory, winner: PlayerMarker.cross);
      GameResult loss() => GameResult(
          resolution: GameResolution.victory, winner: PlayerMarker.nought);
      GameResult draw() => GameResult(resolution: GameResolution.draw);

      storage.recordMatch(mode: GameModeType.classic, result: win(), vsCpu: true);
      storage.recordMatch(mode: GameModeType.classic, result: win(), vsCpu: true);
      expect(storage.winStreak, 2);
      expect(storage.bestWinStreak, 2);

      storage.recordMatch(mode: GameModeType.chaos, result: loss(), vsCpu: true);
      expect(storage.winStreak, 0);
      expect(storage.bestWinStreak, 2);

      storage.recordMatch(mode: GameModeType.shift, result: draw(), vsCpu: true);
      expect(storage.cpuWins, 2);
      expect(storage.cpuLosses, 1);
      expect(storage.cpuDraws, 1);
      expect(storage.totalMatches, 4);
      expect(storage.statsByMode[GameModeType.classic]!.xWins, 2);
      expect(storage.statsByMode[GameModeType.chaos]!.oWins, 1);
      expect(storage.statsByMode[GameModeType.shift]!.draws, 1);
    });

    test('two-player matches do not touch the CPU streak', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final StorageService storage = StorageService.instance;
      await storage.load();
      final int streakBefore = storage.winStreak;
      storage.recordMatch(
        mode: GameModeType.classic,
        result: GameResult(
            resolution: GameResolution.victory, winner: PlayerMarker.cross),
        vsCpu: false,
      );
      expect(storage.winStreak, streakBefore);
    });
  });
}

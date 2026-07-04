// Smoke tests for the core game logic.
//
// The previous file was the default Flutter counter template referencing a
// non-existent `MyApp`/counter UI, which failed analysis. These tests exercise
// the pure win-detection logic instead (no platform plugins required).

import 'package:flutter_test/flutter_test.dart';

import 'package:tictacverse/controllers/win_checker.dart';
import 'package:tictacverse/models/game_result.dart';
import 'package:tictacverse/models/player_marker.dart';

void main() {
  group('WinChecker.evaluateBoard', () {
    test('detects a row victory', () {
      final List<PlayerMarker?> board = <PlayerMarker?>[
        PlayerMarker.cross, PlayerMarker.cross, PlayerMarker.cross, //
        null, PlayerMarker.nought, null, //
        PlayerMarker.nought, null, null, //
      ];

      final GameResult result = WinChecker.evaluateBoard(board);

      expect(result.resolution, GameResolution.victory);
      expect(result.winner, PlayerMarker.cross);
      expect(result.winningLine, <int>[0, 1, 2]);
    });

    test('detects a draw on a full board with no line', () {
      final List<PlayerMarker?> board = <PlayerMarker?>[
        PlayerMarker.cross, PlayerMarker.nought, PlayerMarker.cross, //
        PlayerMarker.cross, PlayerMarker.nought, PlayerMarker.nought, //
        PlayerMarker.nought, PlayerMarker.cross, PlayerMarker.cross, //
      ];

      final GameResult result = WinChecker.evaluateBoard(board);

      expect(result.resolution, GameResolution.draw);
      expect(result.isFinal, isTrue);
    });

    test('reports ongoing when the board is not yet decided', () {
      final List<PlayerMarker?> board = List<PlayerMarker?>.filled(9, null);
      board[0] = PlayerMarker.cross;

      final GameResult result = WinChecker.evaluateBoard(board);

      expect(result.resolution, GameResolution.ongoing);
      expect(result.isFinal, isFalse);
    });
  });
}

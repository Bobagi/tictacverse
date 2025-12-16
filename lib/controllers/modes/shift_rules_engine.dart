import '../../models/game_result.dart';
import '../../models/game_state.dart';
import '../../models/player_marker.dart';
import '../win_checker.dart';
import 'game_rules_engine.dart';

class ShiftRulesEngine implements GameRulesEngine {
  static const int pieceLimitPerPlayer = 3;

  @override
  GameState start() => GameState(
        board: List<PlayerMarker?>.filled(9, null),
        currentPlayer: PlayerMarker.cross,
        result: GameResult(resolution: GameResolution.ongoing),
        playerMoves: <PlayerMarker, List<int>>{
          PlayerMarker.cross: <int>[],
          PlayerMarker.nought: <int>[],
        },
      );

  @override
  GameState handlePlayerMove(GameState currentState, int selectedIndex) {
    if (!currentState.isCellAvailable(selectedIndex) || currentState.result.isFinal) {
      return currentState;
    }
    final List<PlayerMarker?> updatedBoard = List<PlayerMarker?>.from(currentState.board);
    final Map<PlayerMarker, List<int>> updatedMoveOrder = <PlayerMarker, List<int>>{
      for (final MapEntry<PlayerMarker, List<int>> entry in currentState.playerMoves.entries)
        entry.key: List<int>.from(entry.value),
    };

    final List<int> movesForPlayer = updatedMoveOrder[currentState.currentPlayer] ?? <int>[];
    if (movesForPlayer.length >= pieceLimitPerPlayer) {
      final int cellToClear = movesForPlayer.removeAt(0);
      updatedBoard[cellToClear] = null;
    }
    movesForPlayer.add(selectedIndex);
    updatedMoveOrder[currentState.currentPlayer] = movesForPlayer;

    updatedBoard[selectedIndex] = currentState.currentPlayer;
    final GameResult newResult = WinChecker.evaluateBoard(updatedBoard);
    final PlayerMarker nextPlayer = currentState.currentPlayer.opponent;
    return currentState.copyWith(
      board: updatedBoard,
      currentPlayer: nextPlayer,
      result: newResult,
      playerMoves: updatedMoveOrder,
    );
  }
}

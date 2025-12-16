import '../../models/game_result.dart';
import '../../models/game_state.dart';
import '../../models/player_marker.dart';
import '../win_checker.dart';
import 'game_rules_engine.dart';

class ClassicRulesEngine implements GameRulesEngine {
  @override
  GameState start() => GameState(
        board: List<PlayerMarker?>.filled(9, null),
        currentPlayer: PlayerMarker.cross,
        result: GameResult(resolution: GameResolution.ongoing),
      );

  @override
  GameState handlePlayerMove(GameState currentState, int selectedIndex) {
    if (!currentState.isCellAvailable(selectedIndex) || currentState.result.isFinal) {
      return currentState;
    }
    final List<PlayerMarker?> updatedBoard = List<PlayerMarker?>.from(currentState.board);
    updatedBoard[selectedIndex] = currentState.currentPlayer;
    final GameResult newResult = WinChecker.evaluateBoard(updatedBoard);
    final PlayerMarker nextPlayer = currentState.currentPlayer.opponent;
    return currentState.copyWith(
      board: updatedBoard,
      currentPlayer: nextPlayer,
      result: newResult,
    );
  }
}

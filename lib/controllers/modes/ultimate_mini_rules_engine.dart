import 'dart:math';

import '../../models/game_result.dart';
import '../../models/game_state.dart';
import '../../models/player_marker.dart';
import '../../models/ultimate_condition.dart';
import '../win_checker.dart';
import 'game_rules_engine.dart';

class UltimateMiniRulesEngine implements GameRulesEngine {
  UltimateMiniRulesEngine({int? randomSeed}) : _randomGenerator = Random(randomSeed);

  final Random _randomGenerator;
  static const int defaultMoveLimit = 6;

  @override
  GameState start() {
    final UltimateCondition selectedCondition = _selectCondition();
    final int? movesRemaining =
        selectedCondition.type == UltimateConditionType.limitedMoves ? defaultMoveLimit : null;

    return GameState(
      board: List<PlayerMarker?>.filled(9, null),
      currentPlayer: PlayerMarker.cross,
      result: GameResult(resolution: GameResolution.ongoing),
      activeUltimateCondition: selectedCondition,
      movesRemaining: movesRemaining,
    );
  }

  @override
  GameState handlePlayerMove(GameState currentState, int selectedIndex) {
    if (!currentState.isCellAvailable(selectedIndex) || currentState.result.isFinal) {
      return currentState;
    }
    final UltimateCondition? condition = currentState.activeUltimateCondition;
    if (condition != null && !condition.isMoveAllowed(selectedIndex)) {
      return currentState;
    }

    final List<PlayerMarker?> updatedBoard = List<PlayerMarker?>.from(currentState.board);
    updatedBoard[selectedIndex] = currentState.currentPlayer;

    int? movesRemaining = currentState.movesRemaining;
    if (movesRemaining != null) {
      movesRemaining -= 1;
    }

    GameResult tentativeResult = WinChecker.evaluateBoard(updatedBoard);
    if (condition != null && tentativeResult.resolution == GameResolution.victory) {
      if (!condition.isBoardValid(updatedBoard)) {
        tentativeResult = GameResult(resolution: GameResolution.ongoing);
      }
    }

    if (movesRemaining != null && movesRemaining <= 0 && tentativeResult.resolution == GameResolution.ongoing) {
      tentativeResult = GameResult(resolution: GameResolution.draw);
    }

    final PlayerMarker nextPlayer = currentState.currentPlayer.opponent;
    return currentState.copyWith(
      board: updatedBoard,
      currentPlayer: nextPlayer,
      result: tentativeResult,
      movesRemaining: movesRemaining,
    );
  }

  UltimateCondition _selectCondition() {
    final List<UltimateConditionType> types = <UltimateConditionType>[
      UltimateConditionType.avoidCenter,
      UltimateConditionType.limitedMoves,
      UltimateConditionType.cornersOnly,
    ];
    final UltimateConditionType chosen = types[_randomGenerator.nextInt(types.length)];
    switch (chosen) {
      case UltimateConditionType.limitedMoves:
        return UltimateCondition(type: chosen, allowedMoves: defaultMoveLimit);
      default:
        return UltimateCondition(type: chosen);
    }
  }
}

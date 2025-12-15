import 'dart:math';

import '../../models/chaos_event.dart';
import '../../models/game_result.dart';
import '../../models/game_state.dart';
import '../../models/player_marker.dart';
import '../win_checker.dart';
import 'game_rules_engine.dart';

class ChaosRulesEngine implements GameRulesEngine {
  ChaosRulesEngine({int? randomSeed}) : _randomGenerator = Random(randomSeed);

  final Random _randomGenerator;
  int _turnsUntilChaos = 2;
  bool _swapSymbolsNextTurn = false;

  @override
  GameState start() {
    _turnsUntilChaos = 2;
    _swapSymbolsNextTurn = false;
    return GameState(
      board: List<PlayerMarker?>.filled(9, null),
      currentPlayer: PlayerMarker.cross,
      result: GameResult(resolution: GameResolution.ongoing),
    );
  }

  @override
  GameState handlePlayerMove(GameState currentState, int selectedIndex) {
    if (!currentState.isCellAvailable(selectedIndex) || currentState.result.isFinal) {
      return currentState;
    }

    final PlayerMarker markerForTurn = _swapSymbolsNextTurn
        ? currentState.currentPlayer.opponent
        : currentState.currentPlayer;
    _swapSymbolsNextTurn = false;

    final List<PlayerMarker?> updatedBoard = List<PlayerMarker?>.from(currentState.board);
    updatedBoard[selectedIndex] = markerForTurn;

    GameResult newResult = WinChecker.evaluateBoard(updatedBoard);
    ChaosEvent? triggeredEvent;
    List<int> newBlockedCells = <int>[];

    if (!newResult.isFinal) {
      _turnsUntilChaos -= 1;
      if (_turnsUntilChaos <= 0) {
        triggeredEvent = _createChaosEvent(updatedBoard);
        switch (triggeredEvent.type) {
          case ChaosEffectType.removePiece:
            _removeRandomPiece(updatedBoard);
            newResult = WinChecker.evaluateBoard(updatedBoard);
            break;
          case ChaosEffectType.blockCell:
            final int? blockedIndex = _findRandomEmptyIndex(updatedBoard);
            if (blockedIndex != null) {
              newBlockedCells = <int>[blockedIndex];
              triggeredEvent = ChaosEvent(type: ChaosEffectType.blockCell, targetIndex: blockedIndex);
            }
            break;
          case ChaosEffectType.swapSymbols:
            _swapSymbolsNextTurn = true;
            break;
        }
        _turnsUntilChaos = _turnsUntilChaos == 0 ? 3 : 2;
      }
    }

    final PlayerMarker nextPlayer = currentState.currentPlayer.opponent;
    return currentState.copyWith(
      board: updatedBoard,
      currentPlayer: nextPlayer,
      result: newResult,
      activeChaosEvent: triggeredEvent,
      blockedCells: newBlockedCells,
    );
  }

  ChaosEvent _createChaosEvent(List<PlayerMarker?> board) {
    final List<ChaosEffectType> availableEffects = <ChaosEffectType>[
      ChaosEffectType.removePiece,
      ChaosEffectType.blockCell,
      ChaosEffectType.swapSymbols,
    ];
    return ChaosEvent(type: availableEffects[_randomGenerator.nextInt(availableEffects.length)]);
  }

  void _removeRandomPiece(List<PlayerMarker?> board) {
    final List<int> occupied = <int>[];
    for (int i = 0; i < board.length; i++) {
      if (board[i] != null) {
        occupied.add(i);
      }
    }
    if (occupied.isEmpty) {
      return;
    }
    final int removalIndex = occupied[_randomGenerator.nextInt(occupied.length)];
    board[removalIndex] = null;
  }

  int? _findRandomEmptyIndex(List<PlayerMarker?> board) {
    final List<int> emptyCells = <int>[];
    for (int i = 0; i < board.length; i++) {
      if (board[i] == null) {
        emptyCells.add(i);
      }
    }
    if (emptyCells.isEmpty) {
      return null;
    }
    return emptyCells[_randomGenerator.nextInt(emptyCells.length)];
  }
}

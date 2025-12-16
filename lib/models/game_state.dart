import 'chaos_event.dart';
import 'game_result.dart';
import 'player_marker.dart';
import 'ultimate_condition.dart';

class GameState {
  GameState({
    required this.board,
    required this.currentPlayer,
    required this.result,
    this.blockedCells = const <int>[],
    this.activeChaosEvent,
    this.activeUltimateCondition,
    this.movesRemaining,
    this.playerMoves = const <PlayerMarker, List<int>>{},
  });

  final List<PlayerMarker?> board;
  final PlayerMarker currentPlayer;
  final GameResult result;
  final List<int> blockedCells;
  final ChaosEvent? activeChaosEvent;
  final UltimateCondition? activeUltimateCondition;
  final int? movesRemaining;
  final Map<PlayerMarker, List<int>> playerMoves;

  GameState copyWith({
    List<PlayerMarker?>? board,
    PlayerMarker? currentPlayer,
    GameResult? result,
    List<int>? blockedCells,
    ChaosEvent? activeChaosEvent,
    UltimateCondition? activeUltimateCondition,
    int? movesRemaining,
    Map<PlayerMarker, List<int>>? playerMoves,
  }) {
    return GameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      result: result ?? this.result,
      blockedCells: blockedCells ?? this.blockedCells,
      activeChaosEvent: activeChaosEvent ?? this.activeChaosEvent,
      activeUltimateCondition: activeUltimateCondition ?? this.activeUltimateCondition,
      movesRemaining: movesRemaining ?? this.movesRemaining,
      playerMoves: playerMoves ?? this.playerMoves,
    );
  }

  bool isCellAvailable(int index) => board[index] == null && !blockedCells.contains(index);
}

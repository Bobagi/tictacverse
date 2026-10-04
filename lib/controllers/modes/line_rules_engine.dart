import '../../models/game_mode.dart';
import '../../models/game_result.dart';
import '../../models/game_state.dart';
import '../../models/player_marker.dart';
import '../win_checker.dart';
import 'game_rules_engine.dart';

/// Regras de "N em linha" num tabuleiro quadrado maior que o 3x3: cada um
/// joga uma peça por vez numa casa livre, vence quem alinhar [winLength]
/// (ou mais) em linha, coluna ou diagonal, e o tabuleiro cheio sem linha
/// empata. Serve o 4x4 (4 em linha) e o Cinco em linha (Gomoku 10x10, regra
/// livre: seis seguidas também valem).
class LineRulesEngine implements GameRulesEngine {
  LineRulesEngine({required this.size, required this.winLength})
      : assert(size >= 3, 'tabuleiro pequeno demais'),
        assert(winLength >= 3 && winLength <= size, 'linha impossível');

  /// Engine com o formato do [mode] (ver [GameModeBoardShape]).
  factory LineRulesEngine.forMode(GameModeType mode) =>
      LineRulesEngine(size: mode.boardSize, winLength: mode.winLength);

  final int size;
  final int winLength;

  @override
  GameState start() => GameState(
        board: List<PlayerMarker?>.filled(size * size, null),
        currentPlayer: PlayerMarker.cross,
        result: GameResult(resolution: GameResolution.ongoing),
      );

  @override
  GameState handlePlayerMove(GameState currentState, int selectedIndex) {
    if (selectedIndex < 0 ||
        selectedIndex >= currentState.board.length ||
        currentState.result.isFinal ||
        !currentState.isCellAvailable(selectedIndex)) {
      return currentState;
    }
    final List<PlayerMarker?> updatedBoard =
        List<PlayerMarker?>.from(currentState.board);
    updatedBoard[selectedIndex] = currentState.currentPlayer;
    final GameResult newResult = WinChecker.evaluateLines(
      updatedBoard,
      size: size,
      winLength: winLength,
    );
    return currentState.copyWith(
      board: updatedBoard,
      currentPlayer: currentState.currentPlayer.opponent,
      result: newResult,
    );
  }
}

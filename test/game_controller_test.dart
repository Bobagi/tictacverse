import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/controllers/game_controller.dart';
import 'package:tictacverse/models/game_mode.dart';
import 'package:tictacverse/models/game_result.dart';
import 'package:tictacverse/models/player_marker.dart';

GameModeDefinition _classicMode() => createGameModes()
    .firstWhere((GameModeDefinition mode) => mode.type == GameModeType.classic);

void main() {
  group('GameController pós-fim de partida', () {
    test('selectCell é no-op depois que a partida termina', () {
      final GameController controller = GameController(
        modeDefinition: _classicMode(),
        playAgainstCpu: false,
      );

      // X vence com a linha de cima: X 0, O 3, X 1, O 4, X 2.
      for (final int index in <int>[0, 3, 1, 4, 2]) {
        controller.selectCell(index);
      }
      expect(controller.state.result.isFinal, isTrue);
      expect(controller.state.result.winner, PlayerMarker.cross);

      final List<PlayerMarker?> boardAfterWin =
          List<PlayerMarker?>.from(controller.state.board);
      final GameResult resultAfterWin = controller.state.result;

      // Toques depois do fim não podem mudar o tabuleiro nem o resultado
      // (era o bug de stats infladas: re-contava a partida encerrada).
      controller.selectCell(5);
      controller.selectCell(8);

      expect(controller.state.board, boardAfterWin);
      expect(controller.state.result, same(resultAfterWin));
    });
  });

  group('GameController com CPU adiada (pausa de "pensamento")', () {
    test('selectCellHumanOnly não dispara a CPU; performPendingCpuMove sim',
        () {
      final GameController controller = GameController(
        modeDefinition: _classicMode(),
        playAgainstCpu: true,
      );

      controller.selectCellHumanOnly(0);
      // Só a marca do humano no tabuleiro — a CPU ainda não respondeu.
      expect(
        controller.state.board.where((PlayerMarker? m) => m != null).length,
        1,
      );
      expect(controller.state.currentPlayer, PlayerMarker.nought);
      expect(controller.isCpuMovePending, isTrue);

      controller.performPendingCpuMove();
      expect(
        controller.state.board.where((PlayerMarker? m) => m != null).length,
        2,
      );
      expect(controller.state.currentPlayer, PlayerMarker.cross);
      expect(controller.isCpuMovePending, isFalse);
    });

    test('performPendingCpuMove é no-op sem jogada pendente ou pós-fim', () {
      final GameController controller = GameController(
        modeDefinition: _classicMode(),
        playAgainstCpu: true,
      );

      // Turno do humano: nada pendente, nada muda.
      controller.performPendingCpuMove();
      expect(
        controller.state.board.every((PlayerMarker? m) => m == null),
        isTrue,
      );

      // Sem CPU (vs amigo) nunca há jogada pendente.
      final GameController friendController = GameController(
        modeDefinition: _classicMode(),
        playAgainstCpu: false,
      );
      friendController.selectCellHumanOnly(0);
      expect(friendController.isCpuMovePending, isFalse);
    });
  });
}

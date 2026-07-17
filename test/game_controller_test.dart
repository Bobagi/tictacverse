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
}

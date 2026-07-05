import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/controllers/modes/ultimate2_engine.dart';
import 'package:tictacverse/models/game_result.dart';
import 'package:tictacverse/models/player_marker.dart';

void main() {
  final Ultimate2Engine engine = Ultimate2Engine();

  test('a casa jogada define o board do oponente', () {
    Ultimate2State s = engine.start();
    s = engine.handleMove(s, 4, 7); // X joga no board 4, casa 7
    expect(s.activeBoard, 7);
    expect(s.currentPlayer, PlayerMarker.nought);
    expect(engine.handleMove(s, 3, 0), same(s)); // board errado é rejeitado
  });

  test('vencer o board interno conquista a casa do macro', () {
    Ultimate2State s = engine.start();
    // X fecha a linha 0-1-2 do board 0; O joga sempre no board destino casa 8.
    s = engine.handleMove(s, 0, 0); // X → destino 0
    s = engine.handleMove(s, 0, 8); // O → destino 8
    s = engine.handleMove(s, 8, 0); // X → destino 0
    expect(s.activeBoard, 0);
    s = engine.handleMove(s, 0, 1); // O no board 0?! casa 1 — O de olho
    // agora X foi mandado pro board 1
    s = engine.handleMove(s, 1, 0); // X → destino 0
    s = engine.handleMove(s, 0, 7); // O
    s = engine.handleMove(s, 7, 0); // X → destino 0
    s = engine.handleMove(s, 0, 6); // O fecha 6-7-8 no board 0!
    expect(s.macro[0], PlayerMarker.nought); // casa 0 do macro conquistada
    expect(s.result.resolution, GameResolution.ongoing); // jogo segue
  });

  test('macro win encerra o jogo', () {
    Ultimate2State s = Ultimate2State.initial();
    // monta macro quase vencido manualmente via jogadas diretas no board 2:
    // X vence boards 0 e 1 fora do teste (setup manual):
    for (final int b in <int>[0, 1]) {
      s.macro[b] = PlayerMarker.cross;
    }
    // X prestes a vencer board 2: casas 0 e 1 já dele.
    s.boards[2][0] = PlayerMarker.cross;
    s.boards[2][1] = PlayerMarker.cross;
    final Ultimate2State freed = Ultimate2State(
      boards: s.boards,
      macro: s.macro,
      drawnBoards: s.drawnBoards,
      activeBoard: 2,
      currentPlayer: PlayerMarker.cross,
      result: GameResult(resolution: GameResolution.ongoing),
    );
    final Ultimate2State done = engine.handleMove(freed, 2, 2);
    expect(done.macro[2], PlayerMarker.cross);
    expect(done.result.resolution, GameResolution.victory);
    expect(done.result.winner, PlayerMarker.cross);
  });

  test('destino fechado libera jogada livre', () {
    Ultimate2State s = Ultimate2State.initial();
    s.macro[5] = PlayerMarker.nought; // board 5 já conquistado
    final Ultimate2State freed = Ultimate2State(
      boards: s.boards,
      macro: s.macro,
      drawnBoards: s.drawnBoards,
      activeBoard: null,
      currentPlayer: PlayerMarker.cross,
      result: GameResult(resolution: GameResolution.ongoing),
    );
    final Ultimate2State after = engine.handleMove(freed, 0, 5);
    expect(after.activeBoard, isNull); // destino 5 fechado → livre
  });
}

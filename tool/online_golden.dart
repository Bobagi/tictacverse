// Gera partidas-gabarito do Super Jogo da Velha a partir do motor do app, para
// o servidor (tictacverse-api) provar que a cópia das regras em JS dá o MESMO
// resultado jogada a jogada. Rodar quando mudar a regra do Super:
//   /opt/flutter/bin/dart run tool/online_golden.dart > ../tictacverse-api/test/fixtures/ultimate-golden.json
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:tictacverse/controllers/modes/ultimate2_engine.dart';
import 'package:tictacverse/models/game_result.dart';
import 'package:tictacverse/models/player_marker.dart';

String? _mark(PlayerMarker? m) =>
    m == null ? null : (m == PlayerMarker.cross ? 'x' : 'o');

void main() {
  final Random random = Random(20261009);
  final Ultimate2Engine engine = Ultimate2Engine();
  final List<Map<String, Object?>> games = <Map<String, Object?>>[];
  for (int g = 0; g < 400; g++) {
    Ultimate2State state = engine.start();
    final List<List<int>> moves = <List<int>>[];
    final List<List<int>> illegal = <List<int>>[];
    while (!state.result.isFinal) {
      // De vez em quando registra uma jogada ilegal para o servidor recusar.
      if (random.nextInt(6) == 0) {
        final int b = random.nextInt(9), c = random.nextInt(9);
        if (!state.isCellPlayable(b, c)) {
          illegal.add(<int>[moves.length, b, c]);
        }
      }
      final List<List<int>> legal = <List<int>>[
        for (int b = 0; b < 9; b++)
          for (int c = 0; c < 9; c++)
            if (state.isCellPlayable(b, c)) <int>[b, c],
      ];
      final List<int> move = legal[random.nextInt(legal.length)];
      moves.add(move);
      state = engine.handleMove(state, move[0], move[1]);
    }
    games.add(<String, Object?>{
      'moves': moves,
      'illegal': illegal,
      'result': state.result.resolution == GameResolution.draw
          ? 'draw'
          : _mark(state.result.winner),
      'winningLine': state.result.winningLine,
      'macro': state.macro.map(_mark).toList(),
    });
  }
  stdout.writeln(jsonEncode(games));
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/controllers/cpu_strategy.dart';
import 'package:tictacverse/controllers/modes/classic_rules_engine.dart';
import 'package:tictacverse/models/cpu_difficulty.dart';
import 'package:tictacverse/models/game_mode.dart';
import 'package:tictacverse/models/game_result.dart';
import 'package:tictacverse/models/game_state.dart';
import 'package:tictacverse/models/player_marker.dart';
import 'package:tictacverse/models/ultimate_condition.dart';

GameState _stateFromBoard(
  List<PlayerMarker?> board, {
  PlayerMarker currentPlayer = PlayerMarker.nought,
  UltimateCondition? condition,
  Map<PlayerMarker, List<int>> playerMoves = const <PlayerMarker, List<int>>{},
}) {
  return GameState(
    board: board,
    currentPlayer: currentPlayer,
    result: GameResult(resolution: GameResolution.ongoing),
    activeUltimateCondition: condition,
    playerMoves: playerMoves,
  );
}

void main() {
  const PlayerMarker x = PlayerMarker.cross;
  const PlayerMarker o = PlayerMarker.nought;

  group('CpuStrategy medium', () {
    test('takes the winning move', () {
      final CpuStrategy strategy = CpuStrategy(random: Random(1));
      // O O _ / X X _ / _ _ _  → O vence em 2.
      final GameState state = _stateFromBoard(<PlayerMarker?>[
        o, o, null,
        x, x, null,
        null, null, null,
      ]);
      expect(
        strategy.chooseMove(
            state: state, mode: GameModeType.classic, difficulty: CpuDifficulty.medium),
        2,
      );
    });

    test('blocks the opponent winning move', () {
      final CpuStrategy strategy = CpuStrategy(random: Random(1));
      // X X _ / _ O _ / _ _ _ → precisa bloquear em 2.
      final GameState state = _stateFromBoard(<PlayerMarker?>[
        x, x, null,
        null, o, null,
        null, null, null,
      ]);
      expect(
        strategy.chooseMove(
            state: state, mode: GameModeType.classic, difficulty: CpuDifficulty.medium),
        2,
      );
    });
  });

  group('CpuStrategy hard (classic minimax)', () {
    test('never loses against random play across many seeded games', () {
      int cpuLosses = 0;
      for (int seed = 0; seed < 150; seed++) {
        final Random humanRandom = Random(seed);
        final CpuStrategy strategy = CpuStrategy(random: Random(seed + 999));
        final ClassicRulesEngine engine = ClassicRulesEngine();
        GameState state = engine.start();
        while (!state.result.isFinal) {
          if (state.currentPlayer == x) {
            final List<int> moves = <int>[
              for (int i = 0; i < 9; i++)
                if (state.isCellAvailable(i)) i,
            ];
            state = engine.handlePlayerMove(
                state, moves[humanRandom.nextInt(moves.length)]);
          } else {
            final int? move = strategy.chooseMove(
              state: state,
              mode: GameModeType.classic,
              difficulty: CpuDifficulty.hard,
            );
            state = engine.handlePlayerMove(state, move!);
          }
        }
        if (state.result.winner == x) {
          cpuLosses += 1;
        }
      }
      expect(cpuLosses, 0, reason: 'minimax perfeito não pode perder no clássico');
    });
  });

  group('CpuStrategy mode awareness', () {
    test('shift: sees the win opened by its own oldest piece leaving', () {
      // O tem 3 peças (0,1,4 — 0 é a mais antiga). Jogar em 2 remove a peça 0:
      // tabuleiro vira _ O O com O em 2 → linha 0-1-2 NÃO fecha (0 esvaziou).
      // Mas jogar em 7 remove 0 e fecha 1-4-7 (coluna).
      final GameState state = _stateFromBoard(
        <PlayerMarker?>[
          o, o, null,
          x, o, x,
          null, null, x,
        ],
        playerMoves: <PlayerMarker, List<int>>{
          o: <int>[0, 1, 4],
          x: <int>[3, 5, 8],
        },
      );
      final CpuStrategy strategy = CpuStrategy(random: Random(7));
      expect(
        strategy.chooseMove(
            state: state, mode: GameModeType.shift, difficulty: CpuDifficulty.hard),
        7,
      );
    });

    test('ultimate avoidCenter: hard never plays the center', () {
      final UltimateCondition condition =
          UltimateCondition(type: UltimateConditionType.avoidCenter);
      for (int seed = 0; seed < 30; seed++) {
        final CpuStrategy strategy = CpuStrategy(random: Random(seed));
        final GameState state = _stateFromBoard(
          <PlayerMarker?>[
            x, null, null,
            null, null, null,
            null, null, null,
          ],
          condition: condition,
        );
        final int? move = strategy.chooseMove(
          state: state,
          mode: GameModeType.ultimateMini,
          difficulty: CpuDifficulty.hard,
        );
        expect(move, isNot(4),
            reason: 'ocupar o centro invalida qualquer vitória futura');
      }
    });
  });
}

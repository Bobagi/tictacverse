import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/controllers/cpu_strategy.dart';
import 'package:tictacverse/controllers/game_controller.dart';
import 'package:tictacverse/controllers/line_cpu.dart';
import 'package:tictacverse/controllers/modes/line_rules_engine.dart';
import 'package:tictacverse/controllers/win_checker.dart';
import 'package:tictacverse/models/cpu_difficulty.dart';
import 'package:tictacverse/models/game_mode.dart';
import 'package:tictacverse/models/game_result.dart';
import 'package:tictacverse/models/game_state.dart';
import 'package:tictacverse/models/player_marker.dart';
import 'package:tictacverse/services/progression_engine.dart';

const PlayerMarker x = PlayerMarker.cross;
const PlayerMarker o = PlayerMarker.nought;

/// Tabuleiro a partir de linhas de texto: `X`, `O` e `.` (vazio).
List<PlayerMarker?> boardFrom(List<String> rows) {
  final int size = rows.length;
  final List<PlayerMarker?> board = <PlayerMarker?>[];
  for (final String row in rows) {
    expect(row.length, size, reason: 'linha "$row" fora do tamanho');
    for (final String ch in row.split('')) {
      board.add(ch == 'X' ? x : (ch == 'O' ? o : null));
    }
  }
  return board;
}

/// Tabuleiro vazio [size]x[size] com [cells] (linha, coluna) de [who].
List<PlayerMarker?> emptyWith(
  int size,
  Map<PlayerMarker, List<(int, int)>> cells,
) {
  final List<PlayerMarker?> board = List<PlayerMarker?>.filled(size * size, null);
  cells.forEach((PlayerMarker who, List<(int, int)> list) {
    for (final (int r, int c) in list) {
      board[r * size + c] = who;
    }
  });
  return board;
}

int at(int r, int c, [int size = 10]) => r * size + c;

GameResult gomoku(List<PlayerMarker?> board) =>
    WinChecker.evaluateLines(board, size: 10, winLength: 5);

GameResult four(List<PlayerMarker?> board) =>
    WinChecker.evaluateLines(board, size: 4, winLength: 4);

GameModeDefinition modeOf(GameModeType type) => createGameModes()
    .firstWhere((GameModeDefinition mode) => mode.type == type);

void main() {
  group('formato dos modos', () {
    test('4x4 e Cinco em linha têm tabuleiro e linha próprios; o resto é 3x3', () {
      expect(GameModeType.fourByFour.boardSize, 4);
      expect(GameModeType.fourByFour.winLength, 4);
      expect(GameModeType.gomoku.boardSize, 10);
      expect(GameModeType.gomoku.winLength, 5);
      for (final GameModeType mode in <GameModeType>[
        GameModeType.classic,
        GameModeType.shift,
        GameModeType.chaos,
        GameModeType.ultimateMini,
      ]) {
        expect(mode.boardSize, 3, reason: mode.name);
        expect(mode.winLength, 3, reason: mode.name);
        expect(mode.isLineMode, isFalse, reason: mode.name);
      }
    });

    test('os dois modos novos entram no menu depois dos antigos, carro-chefe primeiro', () {
      final List<GameModeType> order =
          createGameModes().map((GameModeDefinition d) => d.type).toList();
      expect(order.first, GameModeType.ultimate2);
      expect(order.sublist(order.length - 2),
          <GameModeType>[GameModeType.fourByFour, GameModeType.gomoku]);
      expect(order.toSet(), GameModeType.values.toSet());
    });
  });

  group('vitória no 4x4', () {
    test('linha', () {
      final GameResult r = four(boardFrom(<String>[
        'O.O.',
        'XXXX',
        '.O..',
        '....',
      ]));
      expect(r.resolution, GameResolution.victory);
      expect(r.winner, x);
      expect(r.winningLine, <int>[4, 5, 6, 7]);
    });

    test('coluna', () {
      final GameResult r = four(boardFrom(<String>[
        '.O..',
        'XO..',
        'XO..',
        'XO.X',
      ]));
      expect(r.winner, o);
      expect(r.winningLine, <int>[1, 5, 9, 13]);
    });

    test('diagonal principal', () {
      final GameResult r = four(boardFrom(<String>[
        'X.OO',
        '.X..',
        '.OX.',
        '...X',
      ]));
      expect(r.winner, x);
      expect(r.winningLine, <int>[0, 5, 10, 15]);
    });

    test('diagonal secundária', () {
      final GameResult r = four(boardFrom(<String>[
        'XX.O',
        '..O.',
        '.O..',
        'O..X',
      ]));
      expect(r.winner, o);
      expect(r.winningLine, <int>[3, 6, 9, 12]);
    });

    test('três seguidas não vencem no 4x4', () {
      final GameResult r = four(boardFrom(<String>[
        'XXX.',
        'O...',
        'O...',
        'O..X',
      ]));
      expect(r.resolution, GameResolution.ongoing);
    });

    test('tabuleiro cheio sem linha é empate', () {
      final GameResult r = four(boardFrom(<String>[
        'XXOO',
        'OOXX',
        'XXOO',
        'OOXX',
      ]));
      expect(r.resolution, GameResolution.draw);
    });
  });

  group('vitória no Cinco em linha (10x10)', () {
    test('horizontal', () {
      final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        x: <(int, int)>[(3, 2), (3, 3), (3, 4), (3, 5), (3, 6)],
        o: <(int, int)>[(4, 4), (5, 5)],
      });
      final GameResult r = gomoku(b);
      expect(r.winner, x);
      expect(r.winningLine, <int>[32, 33, 34, 35, 36]);
    });

    test('vertical', () {
      final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        o: <(int, int)>[(5, 9), (6, 9), (7, 9), (8, 9), (9, 9)],
      });
      final GameResult r = gomoku(b);
      expect(r.winner, o);
      expect(r.winningLine, <int>[59, 69, 79, 89, 99]);
    });

    test('diagonal descendo para a direita', () {
      final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        x: <(int, int)>[(1, 1), (2, 2), (3, 3), (4, 4), (5, 5)],
      });
      expect(gomoku(b).winningLine, <int>[11, 22, 33, 44, 55]);
    });

    test('diagonal descendo para a esquerda', () {
      final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        o: <(int, int)>[(0, 8), (1, 7), (2, 6), (3, 5), (4, 4)],
      });
      final GameResult r = gomoku(b);
      expect(r.winner, o);
      expect(r.winningLine, <int>[8, 17, 26, 35, 44]);
    });

    test('seis seguidas também vencem (regra livre) e a linha traz as seis', () {
      final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        x: <(int, int)>[(7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6)],
      });
      final GameResult r = gomoku(b);
      expect(r.resolution, GameResolution.victory);
      expect(r.winningLine, <int>[71, 72, 73, 74, 75, 76]);
    });

    test('quatro seguidas não vencem', () {
      final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        x: <(int, int)>[(7, 1), (7, 2), (7, 3), (7, 4)],
        o: <(int, int)>[(2, 2), (3, 3), (4, 4), (5, 5)],
      });
      expect(gomoku(b).resolution, GameResolution.ongoing);
    });

    test('casas 8, 9, 10, 11 e 12 NÃO são linha (atravessam a borda)', () {
      final List<PlayerMarker?> b = List<PlayerMarker?>.filled(100, null);
      for (final int i in <int>[8, 9, 10, 11, 12]) {
        b[i] = x;
      }
      expect(gomoku(b).resolution, GameResolution.ongoing);
    });

    test('diagonal que dá a volta na borda também não conta', () {
      // Passo 11 a partir do 7: (0,7) (1,8) (2,9) (4,0) (5,1).
      final List<PlayerMarker?> b = List<PlayerMarker?>.filled(100, null);
      for (final int i in <int>[7, 18, 29, 40, 51]) {
        b[i] = o;
      }
      expect(gomoku(b).resolution, GameResolution.ongoing);
    });

    test('completesLine enxerga as quatro retas pela casa jogada', () {
      final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        x: <(int, int)>[(5, 1), (5, 2), (5, 4), (5, 5)],
      });
      expect(
          WinChecker.completesLine(b, at(5, 3), x, size: 10, winLength: 5), isTrue);
      expect(
          WinChecker.completesLine(b, at(5, 3), o, size: 10, winLength: 5), isFalse);
      expect(
          WinChecker.completesLine(b, at(5, 6), x, size: 10, winLength: 5), isFalse);
    });
  });

  group('LineRulesEngine', () {
    test('começa vazio com o X e no tamanho do modo', () {
      final GameState four = LineRulesEngine.forMode(GameModeType.fourByFour).start();
      final GameState go = LineRulesEngine.forMode(GameModeType.gomoku).start();
      expect(four.board.length, 16);
      expect(go.board.length, 100);
      expect(go.board.every((PlayerMarker? c) => c == null), isTrue);
      expect(go.currentPlayer, x);
    });

    test('alterna a vez e recusa casa ocupada', () {
      final LineRulesEngine engine = LineRulesEngine.forMode(GameModeType.gomoku);
      GameState s = engine.start();
      s = engine.handlePlayerMove(s, 55);
      expect(s.board[55], x);
      expect(s.currentPlayer, o);
      final GameState rejected = engine.handlePlayerMove(s, 55);
      expect(rejected, same(s), reason: 'casa ocupada não pode ser jogada');
      expect(engine.handlePlayerMove(s, 100), same(s));
      s = engine.handlePlayerMove(s, 56);
      expect(s.board[56], o);
      expect(s.currentPlayer, x);
    });

    test('vence com cinco e ignora jogadas depois do fim', () {
      final LineRulesEngine engine = LineRulesEngine.forMode(GameModeType.gomoku);
      GameState s = engine.start();
      // X: 0..4 na primeira linha; O: 10..13 na segunda.
      for (final int i in <int>[0, 10, 1, 11, 2, 12, 3, 13, 4]) {
        s = engine.handlePlayerMove(s, i);
      }
      expect(s.result.winner, x);
      expect(s.result.winningLine, <int>[0, 1, 2, 3, 4]);
      expect(engine.handlePlayerMove(s, 14), same(s));
    });

    test('tabuleiro 4x4 cheio sem linha termina empatado', () {
      final LineRulesEngine engine = LineRulesEngine.forMode(GameModeType.fourByFour);
      GameState s = engine.start();
      // Fecha em XXOO / OOXX / XXOO / OOXX.
      const List<int> order = <int>[0, 2, 1, 3, 6, 4, 7, 5, 8, 10, 9, 11, 14, 12, 15, 13];
      for (int k = 0; k < order.length; k++) {
        expect(s.result.isFinal, isFalse, reason: 'acabou cedo na jogada $k');
        s = engine.handlePlayerMove(s, order[k]);
      }
      expect(s.result.resolution, GameResolution.draw);
    });

    test('GameController usa a engine de linha e a CPU responde', () {
      final GameController controller = GameController(
        modeDefinition: modeOf(GameModeType.gomoku),
        playAgainstCpu: true,
        cpuDifficulty: CpuDifficulty.hard,
        random: Random(3),
      );
      expect(controller.state.board.length, 100);
      controller.selectCell(44);
      expect(controller.state.board.where((PlayerMarker? c) => c == o).length, 1);
      expect(controller.state.currentPlayer, x);

      final GameController four = GameController(
        modeDefinition: modeOf(GameModeType.fourByFour),
        playAgainstCpu: false,
      );
      expect(four.state.board.length, 16);
    });
  });

  group('LineCpu', () {
    int? choose(
      List<PlayerMarker?> board,
      CpuDifficulty difficulty, {
      int size = 10,
      int winLength = 5,
      PlayerMarker me = o,
      int seed = 1,
    }) {
      return LineCpu(random: Random(seed)).chooseMove(
        board: board,
        size: size,
        winLength: winLength,
        me: me,
        difficulty: difficulty,
      );
    }

    test('nunca escolhe casa ocupada (partidas inteiras, todas as dificuldades)', () {
      for (final GameModeType mode in <GameModeType>[
        GameModeType.fourByFour,
        GameModeType.gomoku,
      ]) {
        for (int seed = 0; seed < 12; seed++) {
          final Random rng = Random(seed);
          final LineCpu cpu = LineCpu(random: rng);
          final LineRulesEngine engine = LineRulesEngine.forMode(mode);
          GameState s = engine.start();
          while (!s.result.isFinal) {
            final CpuDifficulty level =
                CpuDifficulty.values[rng.nextInt(CpuDifficulty.values.length)];
            final int? move = cpu.chooseMove(
              board: s.board,
              size: mode.boardSize,
              winLength: mode.winLength,
              me: s.currentPlayer,
              difficulty: level,
            );
            expect(move, isNotNull);
            expect(s.board[move!], isNull,
                reason: '${mode.name} seed $seed: casa $move ocupada');
            s = engine.handlePlayerMove(s, move);
          }
        }
      }
    });

    test('fácil joga colado nas peças; no tabuleiro vazio, no centro', () {
      final List<PlayerMarker?> lone = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        x: <(int, int)>[(2, 7)],
      });
      for (int seed = 0; seed < 30; seed++) {
        final int move = choose(lone, CpuDifficulty.easy, seed: seed)!;
        expect((move ~/ 10 - 2).abs() <= 1 && (move % 10 - 7).abs() <= 1, isTrue,
            reason: 'jogou longe: $move');
      }
      for (int seed = 0; seed < 10; seed++) {
        expect(<int>[44, 45, 54, 55],
            contains(choose(List<PlayerMarker?>.filled(100, null), CpuDifficulty.easy,
                seed: seed)));
      }
    });

    // O vence em (5,4); o X ameaça vencer em (7,4). Vencer vem antes.
    final List<PlayerMarker?> winOrBlock = emptyWith(10, <PlayerMarker, List<(int, int)>>{
      o: <(int, int)>[(5, 0), (5, 1), (5, 2), (5, 3)],
      x: <(int, int)>[(7, 0), (7, 1), (7, 2), (7, 3), (2, 2)],
    });

    for (final CpuDifficulty level in <CpuDifficulty>[
      CpuDifficulty.medium,
      CpuDifficulty.hard,
    ]) {
      test('${level.name}: vence quando pode (antes de bloquear)', () {
        for (int seed = 0; seed < 10; seed++) {
          expect(choose(winOrBlock, level, seed: seed), at(5, 4));
        }
      });

      test('${level.name}: bloqueia a vitória imediata do rival', () {
        // X fecha em (2,6); a outra ponta já está tapada pelo O.
        final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
          x: <(int, int)>[(2, 2), (2, 3), (2, 4), (2, 5), (8, 8)],
          o: <(int, int)>[(2, 1), (6, 6), (7, 1), (0, 9)],
        });
        for (int seed = 0; seed < 10; seed++) {
          expect(choose(b, level, seed: seed), at(2, 6));
        }
      });

      test('${level.name}: no 4x4 vence e bloqueia', () {
        final List<PlayerMarker?> win = boardFrom(<String>[
          'OOO.',
          'XX.X',
          '....',
          '....',
        ]);
        expect(choose(win, level, size: 4, winLength: 4), 3);
        final List<PlayerMarker?> block = boardFrom(<String>[
          'X...',
          'X.O.',
          'X..O',
          '....',
        ]);
        expect(choose(block, level, size: 4, winLength: 4), 12);
      });
    }

    test('difícil: contra quatro aberto, tapa uma das pontas', () {
      final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        x: <(int, int)>[(6, 2), (6, 3), (6, 4), (6, 5)],
        o: <(int, int)>[(1, 1), (2, 8), (9, 9)],
      });
      for (int seed = 0; seed < 10; seed++) {
        expect(<int>[at(6, 1), at(6, 6)], contains(choose(b, CpuDifficulty.hard, seed: seed)));
      }
    });

    test('difícil: fecha o três aberto numa ponta colada', () {
      final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        x: <(int, int)>[(4, 3), (4, 4), (4, 5)],
        o: <(int, int)>[(8, 1), (0, 9)],
      });
      for (int seed = 0; seed < 20; seed++) {
        expect(<int>[at(4, 2), at(4, 6)],
            contains(choose(b, CpuDifficulty.hard, seed: seed)),
            reason: 'seed $seed');
      }
    });

    test('difícil: fecha o três aberto quebrado na diagonal (X X _ X)', () {
      final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        x: <(int, int)>[(2, 2), (3, 3), (5, 5)],
        o: <(int, int)>[(9, 0), (0, 9)],
      });
      for (int seed = 0; seed < 20; seed++) {
        expect(choose(b, CpuDifficulty.hard, seed: seed), at(4, 4), reason: 'seed $seed');
      }
    });

    test('difícil: cria quatro aberto quando pode (ameaça dupla)', () {
      final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        o: <(int, int)>[(5, 3), (5, 4), (5, 5)],
        x: <(int, int)>[(1, 1), (1, 2), (8, 8)],
      });
      for (int seed = 0; seed < 10; seed++) {
        expect(<int>[at(5, 2), at(5, 6)], contains(choose(b, CpuDifficulty.hard, seed: seed)));
      }
    });

    test('difícil: bloquear a vitória do rival vem antes de armar o próprio quatro aberto', () {
      // O tem três aberto (podia fazer quatro aberto), mas o X ganha em (2,6).
      final List<PlayerMarker?> b = emptyWith(10, <PlayerMarker, List<(int, int)>>{
        o: <(int, int)>[(7, 3), (7, 4), (7, 5), (2, 1)],
        x: <(int, int)>[(2, 2), (2, 3), (2, 4), (2, 5), (9, 9)],
      });
      for (int seed = 0; seed < 10; seed++) {
        expect(choose(b, CpuDifficulty.hard, seed: seed), at(2, 6));
      }
    });

    test('difícil: arma o quatro aberto (vitória forçada) em vez de só se defender', () {
      // Posição real de partida: O fecha a coluna 2 em (3,2) com as duas
      // pontas livres; o X tem um três aberto na coluna 5, que não ganha a
      // tempo. Se defender ali, o O joga fora a vitória.
      final List<PlayerMarker?> b = boardFrom(<String>[
        '..........',
        '..O.......',
        '..O.......',
        '..........',
        '..OXXXO...',
        '....OX....',
        '.....XX...',
        '..........',
        '..........',
        '..........',
      ]);
      for (int seed = 0; seed < 10; seed++) {
        expect(choose(b, CpuDifficulty.hard, seed: seed), at(3, 2));
      }
    });

    test('difícil: fecha o três aberto colado; o bloqueio de longe perde', () {
      // Posição real: o O tem três aberto na coluna 7 (linhas 3 a 5). Tapar
      // (1,7) deixa (2,7)+(6,7)+(7,7) e o O faz quatro aberto em (6,7).
      final List<PlayerMarker?> b = boardFrom(<String>[
        '..........',
        '....X.....',
        '....X.....',
        '...X.O.O..',
        '....OX.OO.',
        '...O.X.O..',
        '..X.XOO.X.',
        '.....X....',
        '.....X....',
        '......O...',
      ]);
      for (int seed = 0; seed < 20; seed++) {
        expect(<int>[at(2, 7), at(6, 7)],
            contains(choose(b, CpuDifficulty.hard, me: x, seed: seed)),
            reason: 'seed $seed');
      }
    });

    test('difícil responde em menos de 50 ms num 10x10 de meio de jogo', () {
      final Random rng = Random(42);
      final LineCpu cpu = LineCpu(random: Random(7));
      final List<List<PlayerMarker?>> positions = <List<PlayerMarker?>>[];
      while (positions.length < 8) {
        // Meio de jogo de verdade: 36 lances "fáceis" a partir do centro.
        final LineRulesEngine engine = LineRulesEngine.forMode(GameModeType.gomoku);
        GameState s = engine.start();
        final LineCpu filler = LineCpu(random: rng);
        for (int k = 0; k < 36 && !s.result.isFinal; k++) {
          s = engine.handlePlayerMove(
            s,
            filler.chooseMove(
              board: s.board,
              size: 10,
              winLength: 5,
              me: s.currentPlayer,
              difficulty: CpuDifficulty.easy,
            )!,
          );
        }
        if (!s.result.isFinal) {
          positions.add(s.board);
        }
      }
      // Aquece o JIT para medir a jogada, não a compilação.
      cpu.chooseMove(
          board: positions.first, size: 10, winLength: 5, me: o, difficulty: CpuDifficulty.hard);
      for (final List<PlayerMarker?> board in positions) {
        final Stopwatch watch = Stopwatch()..start();
        final int? move = cpu.chooseMove(
            board: board, size: 10, winLength: 5, me: o, difficulty: CpuDifficulty.hard);
        watch.stop();
        expect(board[move!], isNull);
        expect(watch.elapsedMilliseconds, lessThan(50));
      }
    });

    test('difícil contra fácil no Gomoku: o difícil não perde', () {
      for (int seed = 0; seed < 6; seed++) {
        final LineRulesEngine engine = LineRulesEngine.forMode(GameModeType.gomoku);
        final LineCpu hard = LineCpu(random: Random(seed));
        final LineCpu easy = LineCpu(random: Random(seed + 100));
        GameState s = engine.start();
        while (!s.result.isFinal) {
          final bool hardTurn = s.currentPlayer == o;
          final int move = (hardTurn ? hard : easy).chooseMove(
            board: s.board,
            size: 10,
            winLength: 5,
            me: s.currentPlayer,
            difficulty: hardTurn ? CpuDifficulty.hard : CpuDifficulty.easy,
          )!;
          s = engine.handlePlayerMove(s, move);
        }
        expect(s.result.winner, isNot(x), reason: 'seed $seed');
      }
    });

    test('CpuStrategy manda os modos de linha para a LineCpu', () {
      final CpuStrategy strategy = CpuStrategy(random: Random(1));
      final GameState state = GameState(
        board: winOrBlock,
        currentPlayer: o,
        result: GameResult(resolution: GameResolution.ongoing),
      );
      expect(
        strategy.chooseMove(
            state: state, mode: GameModeType.gomoku, difficulty: CpuDifficulty.hard),
        at(5, 4),
      );
    });
  });

  group('XP dos modos novos', () {
    int xpFor(GameModeType mode) => ProgressionEngine.xpForMatch(MatchOutcome(
          mode: mode,
          vsCpu: true,
          difficulty: CpuDifficulty.hard,
          humanWon: true,
          isDraw: false,
        ));

    test('4x4 paga como o Clássico; Cinco em linha +25%, abaixo do carro-chefe', () {
      expect(xpFor(GameModeType.fourByFour), xpFor(GameModeType.classic));
      expect(xpFor(GameModeType.gomoku), (xpFor(GameModeType.classic) * 1.25).round());
      expect(xpFor(GameModeType.gomoku), lessThan(xpFor(GameModeType.ultimate2)));
    });
  });
}

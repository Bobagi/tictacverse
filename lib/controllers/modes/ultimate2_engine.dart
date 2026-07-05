import 'dart:math';

import '../../models/cpu_difficulty.dart';
import '../../models/game_result.dart';
import '../../models/player_marker.dart';
import '../win_checker.dart';

/// Estado do Tic Tac Toe 2 (Ultimate): um macro 3×3 onde cada casa contém um
/// jogo da velha interno. A posição jogada no board interno define o board em
/// que o oponente joga; board fechado ⇒ jogada livre.
class Ultimate2State {
  Ultimate2State({
    required this.boards,
    required this.macro,
    required this.drawnBoards,
    required this.activeBoard,
    required this.currentPlayer,
    required this.result,
    this.lastBoard,
    this.lastCell,
  });

  factory Ultimate2State.initial() => Ultimate2State(
        boards: List<List<PlayerMarker?>>.generate(
            9, (_) => List<PlayerMarker?>.filled(9, null)),
        macro: List<PlayerMarker?>.filled(9, null),
        drawnBoards: const <int>{},
        activeBoard: null,
        currentPlayer: PlayerMarker.cross,
        result: GameResult(resolution: GameResolution.ongoing),
      );

  final List<List<PlayerMarker?>> boards;
  final List<PlayerMarker?> macro;
  final Set<int> drawnBoards;

  /// Board onde o jogador atual DEVE jogar; null = livre.
  final int? activeBoard;
  final PlayerMarker currentPlayer;
  final GameResult result;
  final int? lastBoard;
  final int? lastCell;

  bool isBoardClosed(int board) =>
      macro[board] != null ||
      drawnBoards.contains(board) ||
      !boards[board].contains(null);

  bool isBoardPlayable(int board) =>
      !result.isFinal &&
      !isBoardClosed(board) &&
      (activeBoard == null || activeBoard == board);

  bool isCellPlayable(int board, int cell) =>
      isBoardPlayable(board) && boards[board][cell] == null;
}

class Ultimate2Engine {
  Ultimate2State start() => Ultimate2State.initial();

  Ultimate2State handleMove(Ultimate2State state, int board, int cell) {
    if (!state.isCellPlayable(board, cell)) {
      return state;
    }
    final List<List<PlayerMarker?>> boards = <List<PlayerMarker?>>[
      for (final List<PlayerMarker?> b in state.boards) List<PlayerMarker?>.from(b),
    ];
    final List<PlayerMarker?> macro = List<PlayerMarker?>.from(state.macro);
    final Set<int> drawn = Set<int>.from(state.drawnBoards);

    boards[board][cell] = state.currentPlayer;

    final GameResult miniResult = WinChecker.evaluateBoard(boards[board]);
    if (miniResult.resolution == GameResolution.victory) {
      macro[board] = miniResult.winner;
    } else if (!boards[board].contains(null)) {
      drawn.add(board);
    }

    GameResult result = WinChecker.evaluateBoard(macro);
    if (result.resolution != GameResolution.victory) {
      final bool allDecided = List<int>.generate(9, (int i) => i).every(
          (int i) => macro[i] != null || drawn.contains(i) || !boards[i].contains(null));
      result = allDecided
          ? GameResult(resolution: GameResolution.draw)
          : GameResult(resolution: GameResolution.ongoing);
    }

    // A casa jogada manda o oponente para o board de mesmo índice.
    int? nextActive = cell;
    final bool destinationClosed = macro[nextActive] != null ||
        drawn.contains(nextActive) ||
        !boards[nextActive].contains(null);
    if (destinationClosed) {
      nextActive = null;
    }

    return Ultimate2State(
      boards: boards,
      macro: macro,
      drawnBoards: drawn,
      activeBoard: result.isFinal ? null : nextActive,
      currentPlayer: state.currentPlayer.opponent,
      result: result,
      lastBoard: board,
      lastCell: cell,
    );
  }
}

/// CPU do Tic Tac Toe 2.
class Ultimate2Cpu {
  Ultimate2Cpu({Random? random}) : _random = random ?? Random();

  final Random _random;

  (int, int)? chooseMove(Ultimate2State state, CpuDifficulty difficulty) {
    final List<(int, int)> moves = _playableMoves(state);
    if (moves.isEmpty) {
      return null;
    }
    if (difficulty == CpuDifficulty.easy) {
      return moves[_random.nextInt(moves.length)];
    }
    final PlayerMarker cpu = state.currentPlayer;

    // 1) vencer um board interno agora (prioriza o que fecha linha no macro).
    (int, int)? bestWin;
    for (final (int, int) move in moves) {
      if (_winsMini(state, move, cpu)) {
        bestWin = move;
        if (_winsMacroAfter(state, move, cpu)) {
          return move;
        }
      }
    }
    if (bestWin != null) {
      return bestWin;
    }
    // 2) bloquear vitória interna do oponente no mesmo board.
    for (final (int, int) move in moves) {
      if (_winsMini(state, move, cpu.opponent)) {
        return move;
      }
    }
    if (difficulty == CpuDifficulty.medium) {
      return moves[_random.nextInt(moves.length)];
    }
    // hard: não entregar um board onde o oponente vence na hora; posicional.
    final List<(int, int)> safe = <(int, int)>[
      for (final (int, int) move in moves)
        if (!_givesOpponentMiniWin(state, move)) move,
    ];
    final List<(int, int)> pool = safe.isNotEmpty ? safe : moves;
    return _positional(pool);
  }

  List<(int, int)> _playableMoves(Ultimate2State state) => <(int, int)>[
        for (int b = 0; b < 9; b++)
          if (state.isBoardPlayable(b))
            for (int c = 0; c < 9; c++)
              if (state.boards[b][c] == null) (b, c),
      ];

  bool _winsMini(Ultimate2State state, (int, int) move, PlayerMarker who) {
    final List<PlayerMarker?> board = List<PlayerMarker?>.from(state.boards[move.$1]);
    board[move.$2] = who;
    final GameResult r = WinChecker.evaluateBoard(board);
    return r.resolution == GameResolution.victory && r.winner == who;
  }

  bool _winsMacroAfter(Ultimate2State state, (int, int) move, PlayerMarker who) {
    final List<PlayerMarker?> macro = List<PlayerMarker?>.from(state.macro);
    macro[move.$1] = who;
    final GameResult r = WinChecker.evaluateBoard(macro);
    return r.resolution == GameResolution.victory && r.winner == who;
  }

  bool _givesOpponentMiniWin(Ultimate2State state, (int, int) move) {
    final Ultimate2Engine engine = Ultimate2Engine();
    final Ultimate2State after = engine.handleMove(state, move.$1, move.$2);
    if (after.result.isFinal) {
      return false;
    }
    final PlayerMarker opponent = after.currentPlayer;
    for (int b = 0; b < 9; b++) {
      if (!after.isBoardPlayable(b)) {
        continue;
      }
      for (int c = 0; c < 9; c++) {
        if (after.boards[b][c] != null) {
          continue;
        }
        final List<PlayerMarker?> board = List<PlayerMarker?>.from(after.boards[b]);
        board[c] = opponent;
        final GameResult r = WinChecker.evaluateBoard(board);
        if (r.resolution == GameResolution.victory && r.winner == opponent) {
          return true;
        }
      }
    }
    return false;
  }

  (int, int) _positional(List<(int, int)> pool) {
    for (final int target in <int>[4, 0, 2, 6, 8]) {
      final List<(int, int)> hits =
          pool.where(((int, int) m) => m.$2 == target).toList();
      if (hits.isNotEmpty) {
        return hits[_random.nextInt(hits.length)];
      }
    }
    return pool[_random.nextInt(pool.length)];
  }
}

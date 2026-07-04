import 'dart:math';

import '../models/cpu_difficulty.dart';
import '../models/game_mode.dart';
import '../models/game_result.dart';
import '../models/game_state.dart';
import '../models/player_marker.dart';
import '../models/ultimate_condition.dart';
import 'modes/shift_rules_engine.dart';
import 'win_checker.dart';

/// Escolhe a jogada da CPU conforme a dificuldade.
///
/// - easy: célula aleatória.
/// - medium: vence se possível, bloqueia a vitória do oponente, senão aleatório.
/// - hard: minimax perfeito no modo clássico; nos demais modos usa a mesma
///   detecção de vitória/bloqueio ciente das regras do modo (remoção do Shift,
///   condição do Ultimate) + filtro de jogadas seguras + preferência posicional.
class CpuStrategy {
  CpuStrategy({Random? random}) : _random = random ?? Random();

  final Random _random;

  int? chooseMove({
    required GameState state,
    required GameModeType mode,
    required CpuDifficulty difficulty,
  }) {
    final List<int> moves = _availableMoves(state);
    if (moves.isEmpty) {
      return null;
    }
    final PlayerMarker cpu = state.currentPlayer;
    switch (difficulty) {
      case CpuDifficulty.easy:
        return moves[_random.nextInt(moves.length)];
      case CpuDifficulty.medium:
        return _winningMove(state, mode, moves, cpu) ??
            _winningMove(state, mode, moves, cpu.opponent) ??
            moves[_random.nextInt(moves.length)];
      case CpuDifficulty.hard:
        return _hardMove(state, mode, moves, cpu);
    }
  }

  List<int> _availableMoves(GameState state) {
    return <int>[
      for (int i = 0; i < state.board.length; i++)
        if (state.isCellAvailable(i)) i,
    ];
  }

  /// Tabuleiro resultante de [who] jogar em [index], replicando a parte
  /// determinística das regras do modo (no Shift, a peça mais antiga sai).
  List<PlayerMarker?> _boardAfterPlacement(
    GameState state,
    GameModeType mode,
    int index,
    PlayerMarker who,
  ) {
    final List<PlayerMarker?> board = List<PlayerMarker?>.from(state.board);
    if (mode == GameModeType.shift) {
      final List<int> placed = state.playerMoves[who] ?? const <int>[];
      if (placed.length >= ShiftRulesEngine.pieceLimitPerPlayer) {
        board[placed.first] = null;
      }
    }
    board[index] = who;
    return board;
  }

  bool _placementWins(
    GameState state,
    GameModeType mode,
    int index,
    PlayerMarker who,
  ) {
    final List<PlayerMarker?> board = _boardAfterPlacement(state, mode, index, who);
    final GameResult result = WinChecker.evaluateBoard(board);
    if (result.resolution != GameResolution.victory || result.winner != who) {
      return false;
    }
    final UltimateCondition? condition = state.activeUltimateCondition;
    if (mode == GameModeType.ultimateMini && condition != null && !condition.isBoardValid(board)) {
      return false;
    }
    return true;
  }

  int? _winningMove(
    GameState state,
    GameModeType mode,
    List<int> moves,
    PlayerMarker who,
  ) {
    for (final int move in moves) {
      if (_placementWins(state, mode, move, who)) {
        return move;
      }
    }
    return null;
  }

  int _hardMove(
    GameState state,
    GameModeType mode,
    List<int> moves,
    PlayerMarker cpu,
  ) {
    if (mode == GameModeType.classic) {
      return _minimaxMove(state.board, cpu) ?? moves[_random.nextInt(moves.length)];
    }

    final int? winNow = _winningMove(state, mode, moves, cpu);
    if (winNow != null) {
      return winNow;
    }
    final int? blockNow = _winningMove(state, mode, moves, cpu.opponent);
    if (blockNow != null) {
      return blockNow;
    }

    // No Ultimate com "evite o centro", ocupar o centro invalida qualquer
    // vitória futura (dos dois lados) — a CPU nunca se auto-sabota.
    final bool avoidCenter = mode == GameModeType.ultimateMini &&
        state.activeUltimateCondition?.type == UltimateConditionType.avoidCenter;
    List<int> candidates =
        avoidCenter ? moves.where((int m) => m != 4).toList() : List<int>.from(moves);
    if (candidates.isEmpty) {
      candidates = moves;
    }

    // Jogadas "seguras": depois delas o oponente não tem vitória imediata.
    final List<int> safe = <int>[
      for (final int move in candidates)
        if (!_opponentWinsAfter(state, mode, move, cpu)) move,
    ];
    final List<int> pool = safe.isNotEmpty ? safe : candidates;
    return _bestPositional(pool);
  }

  bool _opponentWinsAfter(
    GameState state,
    GameModeType mode,
    int cpuMove,
    PlayerMarker cpu,
  ) {
    final List<PlayerMarker?> boardAfter =
        _boardAfterPlacement(state, mode, cpuMove, cpu);
    final PlayerMarker opponent = cpu.opponent;
    for (int i = 0; i < boardAfter.length; i++) {
      if (boardAfter[i] != null) {
        continue;
      }
      final List<PlayerMarker?> reply = List<PlayerMarker?>.from(boardAfter);
      if (mode == GameModeType.shift) {
        final List<int> placed = state.playerMoves[opponent] ?? const <int>[];
        if (placed.length >= ShiftRulesEngine.pieceLimitPerPlayer &&
            reply[placed.first] == opponent) {
          reply[placed.first] = null;
        }
      }
      reply[i] = opponent;
      final GameResult result = WinChecker.evaluateBoard(reply);
      if (result.resolution == GameResolution.victory && result.winner == opponent) {
        final UltimateCondition? condition = state.activeUltimateCondition;
        if (mode == GameModeType.ultimateMini &&
            condition != null &&
            !condition.isBoardValid(reply)) {
          continue;
        }
        return true;
      }
    }
    return false;
  }

  int _bestPositional(List<int> pool) {
    const List<List<int>> preferenceGroups = <List<int>>[
      <int>[4],
      <int>[0, 2, 6, 8],
      <int>[1, 3, 5, 7],
    ];
    for (final List<int> group in preferenceGroups) {
      final List<int> inPool = pool.where(group.contains).toList();
      if (inPool.isNotEmpty) {
        return inPool[_random.nextInt(inPool.length)];
      }
    }
    return pool[_random.nextInt(pool.length)];
  }

  // ---------------------------------------------------------------- minimax

  int? _minimaxMove(List<PlayerMarker?> board, PlayerMarker cpu) {
    final List<PlayerMarker?> working = List<PlayerMarker?>.from(board);
    int? bestMove;
    int bestScore = -1000;
    for (int i = 0; i < working.length; i++) {
      if (working[i] != null) {
        continue;
      }
      working[i] = cpu;
      final int score = _minimax(working, cpu, isCpuTurn: false, depth: 1);
      working[i] = null;
      if (score > bestScore) {
        bestScore = score;
        bestMove = i;
      }
    }
    return bestMove;
  }

  int _minimax(
    List<PlayerMarker?> board,
    PlayerMarker cpu, {
    required bool isCpuTurn,
    required int depth,
  }) {
    final GameResult result = WinChecker.evaluateBoard(board);
    if (result.resolution == GameResolution.victory) {
      return result.winner == cpu ? 10 - depth : depth - 10;
    }
    if (result.resolution == GameResolution.draw) {
      return 0;
    }
    final PlayerMarker mover = isCpuTurn ? cpu : cpu.opponent;
    int best = isCpuTurn ? -1000 : 1000;
    for (int i = 0; i < board.length; i++) {
      if (board[i] != null) {
        continue;
      }
      board[i] = mover;
      final int score = _minimax(board, cpu, isCpuTurn: !isCpuTurn, depth: depth + 1);
      board[i] = null;
      if (isCpuTurn) {
        best = max(best, score);
      } else {
        best = min(best, score);
      }
    }
    return best;
  }
}

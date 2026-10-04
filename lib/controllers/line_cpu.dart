import 'dart:math';

import '../models/cpu_difficulty.dart';
import '../models/player_marker.dart';
import 'win_checker.dart';

/// CPU dos modos de tabuleiro maior (4x4 e Cinco em linha).
///
/// Minimax não cabe num 10x10, então a máquina joga por regras curtas e uma
/// pontuação de padrões, sempre em Dart puro e com o [Random] injetável para
/// os testes serem determinísticos.
///
/// - easy: casa aleatória vizinha (8 direções) de alguma peça; centro se o
///   tabuleiro estiver vazio. Não vence nem bloqueia de propósito.
/// - medium: vence agora, senão bloqueia a vitória imediata do rival, senão
///   sorteia entre as 3 melhores casas da pontuação.
/// - hard: vence agora, bloqueia agora, cria ameaça dupla (duas casas de
///   vitória ao mesmo tempo, impossível de bloquear), impede a ameaça dupla do
///   rival (é o que fecha o "três aberto" e o "quatro aberto" no Gomoku) e,
///   sem nada disso, joga a melhor casa da pontuação por janelas.
class LineCpu {
  LineCpu({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Peso de uma janela de [winLength] casas com `k` peças de um lado só.
  /// Cresce ~8x por peça: uma janela com 3 vale mais que muitas com 2.
  static const List<double> _windowWeights = <double>[
    1,
    8,
    60,
    480,
    4000,
    32000,
  ];

  /// Ataque vale um pouco mais que defesa no empate de padrões: entre fazer o
  /// meu três e travar o três do rival (sem ameaça dupla em jogo), avançar.
  static const double _attackBias = 1.1;

  int? chooseMove({
    required List<PlayerMarker?> board,
    required int size,
    required int winLength,
    required PlayerMarker me,
    required CpuDifficulty difficulty,
  }) {
    if (!board.contains(null)) {
      return null;
    }
    // Cópia de trabalho: as heurísticas colocam e tiram peças temporariamente.
    final List<PlayerMarker?> work = List<PlayerMarker?>.from(board);
    final _Shape shape = _Shape(size, winLength);
    switch (difficulty) {
      case CpuDifficulty.easy:
        return _pick(_nearbyEmpty(work, shape, radius: 1));
      case CpuDifficulty.medium:
        return _immediateWin(work, shape, me) ??
            _immediateWin(work, shape, me.opponent) ??
            _mediumHeuristic(work, shape, me);
      case CpuDifficulty.hard:
        return _hardMove(work, shape, me);
    }
  }

  int _pick(List<int> options) => options[_random.nextInt(options.length)];

  // ------------------------------------------------------------ candidatas

  /// Casas vazias a até [radius] casas (vizinhança de 8) de alguma peça.
  /// Tabuleiro vazio: as casas do centro. Se nada estiver perto de peça
  /// nenhuma (não acontece com radius >= 1 e casa livre), toda casa vazia.
  List<int> _nearbyEmpty(List<PlayerMarker?> board, _Shape shape,
      {required int radius}) {
    final int size = shape.size;
    final List<bool> near = List<bool>.filled(board.length, false);
    bool anyPiece = false;
    for (int index = 0; index < board.length; index++) {
      if (board[index] == null) {
        continue;
      }
      anyPiece = true;
      final int row = index ~/ size;
      final int col = index % size;
      for (int r = max(0, row - radius); r <= min(size - 1, row + radius); r++) {
        for (int c = max(0, col - radius);
            c <= min(size - 1, col + radius);
            c++) {
          near[r * size + c] = true;
        }
      }
    }
    if (!anyPiece) {
      return _centerCells(size);
    }
    final List<int> result = <int>[
      for (int i = 0; i < board.length; i++)
        if (board[i] == null && near[i]) i,
    ];
    if (result.isNotEmpty) {
      return result;
    }
    return <int>[
      for (int i = 0; i < board.length; i++)
        if (board[i] == null) i,
    ];
  }

  /// Centro do tabuleiro: 1 casa no lado ímpar, as 4 do meio no lado par.
  static List<int> _centerCells(int size) {
    final int high = size ~/ 2;
    final int low = size.isOdd ? high : high - 1;
    return <int>[
      for (int r = low; r <= high; r++)
        for (int c = low; c <= high; c++) r * size + c,
    ];
  }

  // ------------------------------------------------------- vitória/bloqueio

  int? _immediateWin(
      List<PlayerMarker?> board, _Shape shape, PlayerMarker who) {
    final List<int> wins = _winningCells(board, shape, who);
    return wins.isEmpty ? null : _pick(wins);
  }

  List<int> _winningCells(
      List<PlayerMarker?> board, _Shape shape, PlayerMarker who) {
    return <int>[
      for (int i = 0; i < board.length; i++)
        if (board[i] == null &&
            WinChecker.completesLine(board, i, who,
                size: shape.size, winLength: shape.winLength))
          i,
    ];
  }

  /// Quantas casas de vitória imediata [who] passa a ter depois de jogar em
  /// [move]. Só olha as retas que passam por [move]: antes da jogada [who]
  /// não tinha nenhuma (quem chama já tratou vitória e bloqueio imediatos).
  int _threatsAfter(
      List<PlayerMarker?> board, _Shape shape, int move, PlayerMarker who) {
    final int size = shape.size;
    board[move] = who;
    final Set<int> wins = <int>{};
    final int row = move ~/ size;
    final int col = move % size;
    for (final (int dr, int dc) in WinChecker.lineDirections) {
      for (final int sign in const <int>[1, -1]) {
        for (int step = 1; step < shape.winLength; step++) {
          final int r = row + dr * sign * step;
          final int c = col + dc * sign * step;
          if (r < 0 || r >= size || c < 0 || c >= size) {
            break;
          }
          final int cell = r * size + c;
          final PlayerMarker? occupant = board[cell];
          if (occupant == who.opponent) {
            break;
          }
          if (occupant == null &&
              WinChecker.completesLine(board, cell, who,
                  size: size, winLength: shape.winLength)) {
            wins.add(cell);
          }
        }
      }
    }
    board[move] = null;
    return wins.length;
  }

  // -------------------------------------------------------------- pontuação

  /// Pontuação de jogar em [cell]: soma, em todas as janelas de [winLength]
  /// casas que passam por [cell], o valor de ataque (janela só minha) e de
  /// defesa (janela só do rival). Janela com peças dos dois lados não vale
  /// nada: ali ninguém fecha linha.
  double _score(
      List<PlayerMarker?> board, _Shape shape, int cell, PlayerMarker me) {
    final int size = shape.size;
    final int winLength = shape.winLength;
    final int row = cell ~/ size;
    final int col = cell % size;
    double attack = 0;
    double defense = 0;
    for (final (int dr, int dc) in WinChecker.lineDirections) {
      // A janela começa em [cell] menos `back` passos e tem winLength casas.
      for (int back = 0; back < winLength; back++) {
        final int startRow = row - dr * back;
        final int startCol = col - dc * back;
        final int endRow = startRow + dr * (winLength - 1);
        final int endCol = startCol + dc * (winLength - 1);
        if (startRow < 0 ||
            startRow >= size ||
            startCol < 0 ||
            startCol >= size ||
            endRow < 0 ||
            endRow >= size ||
            endCol < 0 ||
            endCol >= size) {
          continue;
        }
        int mine = 0;
        int theirs = 0;
        for (int k = 0; k < winLength; k++) {
          final PlayerMarker? occupant =
              board[(startRow + dr * k) * size + startCol + dc * k];
          if (occupant == me) {
            mine += 1;
          } else if (occupant != null) {
            theirs += 1;
          }
        }
        if (theirs == 0) {
          attack += _windowWeights[min(mine, _windowWeights.length - 1)];
        }
        if (mine == 0) {
          defense += _windowWeights[min(theirs, _windowWeights.length - 1)];
        }
      }
    }
    // Desempate leve pelo centro: casas centrais entram em mais janelas
    // futuras, e a abertura não fica grudada na borda.
    final double center = (size - 1) / 2;
    final double distance = (row - center).abs() + (col - center).abs();
    return attack * _attackBias + defense - distance * 0.01;
  }

  /// Casas de [pool] com a maior pontuação (empates todos juntos).
  List<int> _bestScored(List<PlayerMarker?> board, _Shape shape,
      List<int> pool, PlayerMarker me) {
    double best = double.negativeInfinity;
    List<int> top = <int>[];
    for (final int cell in pool) {
      final double value = _score(board, shape, cell, me);
      if (value > best + 1e-9) {
        best = value;
        top = <int>[cell];
      } else if ((value - best).abs() <= 1e-9) {
        top.add(cell);
      }
    }
    return top;
  }

  int _mediumHeuristic(
      List<PlayerMarker?> board, _Shape shape, PlayerMarker me) {
    final List<int> pool = _nearbyEmpty(board, shape, radius: 2);
    final List<(int, double)> scored = <(int, double)>[
      for (final int cell in pool) (cell, _score(board, shape, cell, me)),
    ]..sort(((int, double) a, (int, double) b) => b.$2.compareTo(a.$2));
    final int topCount = min(3, scored.length);
    return scored[_random.nextInt(topCount)].$1;
  }

  // ------------------------------------------------------------------- hard

  int _hardMove(List<PlayerMarker?> board, _Shape shape, PlayerMarker me) {
    final PlayerMarker rival = me.opponent;

    final List<int> myWins = _winningCells(board, shape, me);
    if (myWins.isNotEmpty) {
      return _pick(myWins);
    }
    final List<int> rivalWins = _winningCells(board, shape, rival);
    if (rivalWins.isNotEmpty) {
      // Mais de uma casa de vitória do rival já é derrota; bloqueia a melhor.
      return _pick(_bestScored(board, shape, rivalWins, me));
    }

    final List<int> pool = _nearbyEmpty(board, shape, radius: 2);

    // Ameaça dupla minha: o rival só consegue tapar uma das duas casas.
    final List<int> myForks = <int>[
      for (final int cell in pool)
        if (_threatsAfter(board, shape, cell, me) >= 2) cell,
    ];
    if (myForks.isNotEmpty) {
      return _pick(_bestScored(board, shape, myForks, me));
    }

    // Ameaça dupla do rival (no Gomoku: o três aberto que vira quatro
    // aberto). Ocupo a casa que mais desmonta essas ameaças.
    final List<int> rivalForks = <int>[
      for (final int cell in pool)
        if (_threatsAfter(board, shape, cell, rival) >= 2) cell,
    ];
    if (rivalForks.isNotEmpty) {
      int fewestLeft = rivalForks.length + 1;
      List<int> blockers = <int>[];
      for (final int cell in rivalForks) {
        board[cell] = me;
        int left = 0;
        for (final int other in rivalForks) {
          if (other != cell && _threatsAfter(board, shape, other, rival) >= 2) {
            left += 1;
          }
        }
        board[cell] = null;
        if (left < fewestLeft) {
          fewestLeft = left;
          blockers = <int>[cell];
        } else if (left == fewestLeft) {
          blockers.add(cell);
        }
      }
      return _pick(_bestScored(board, shape, blockers, me));
    }

    return _pick(_bestScored(board, shape, pool, me));
  }
}

class _Shape {
  const _Shape(this.size, this.winLength);

  final int size;
  final int winLength;
}

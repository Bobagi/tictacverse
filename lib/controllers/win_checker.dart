import '../models/game_result.dart';
import '../models/player_marker.dart';

class WinChecker {
  static const List<List<int>> winningLines = <List<int>>[
    <int>[0, 1, 2],
    <int>[3, 4, 5],
    <int>[6, 7, 8],
    <int>[0, 3, 6],
    <int>[1, 4, 7],
    <int>[2, 5, 8],
    <int>[0, 4, 8],
    <int>[2, 4, 6],
  ];

  static GameResult evaluateBoard(List<PlayerMarker?> board) {
    for (final List<int> line in winningLines) {
      final PlayerMarker? first = board[line.first];
      if (first != null && board[line[1]] == first && board[line[2]] == first) {
        return GameResult(
          resolution: GameResolution.victory,
          winner: first,
          winningLine: line,
        );
      }
    }
    if (!board.contains(null)) {
      return GameResult(resolution: GameResolution.draw);
    }
    return GameResult(resolution: GameResolution.ongoing);
  }

  /// Direções de linha: direita, baixo, diagonal descendo para a direita e
  /// diagonal descendo para a esquerda, como (passo de linha, passo de coluna).
  static const List<(int, int)> lineDirections = <(int, int)>[
    (0, 1),
    (1, 0),
    (1, 1),
    (1, -1),
  ];

  /// Avalia um tabuleiro quadrado [size]x[size] em que [winLength] peças
  /// seguidas vencem (em linha, coluna ou qualquer diagonal).
  ///
  /// A linha vencedora devolvida é a sequência contígua inteira, em ordem ao
  /// longo da direção (no Cinco em linha, seis seguidas devolvem as seis), então
  /// a primeira e a última casa são as pontas para desenhar o risco.
  ///
  /// A contagem anda por linha e coluna, nunca por índice: as casas 8, 9, 10,
  /// 11 e 12 de um 10x10 NÃO formam linha (atravessam a borda).
  static GameResult evaluateLines(
    List<PlayerMarker?> board, {
    required int size,
    required int winLength,
  }) {
    assert(board.length == size * size, 'tabuleiro não é ${size}x$size');
    for (int index = 0; index < board.length; index++) {
      final PlayerMarker? owner = board[index];
      if (owner == null) {
        continue;
      }
      final int row = index ~/ size;
      final int col = index % size;
      for (final (int dr, int dc) in lineDirections) {
        // Só conta a partir do começo da sequência, para não repetir trabalho.
        final int prevRow = row - dr;
        final int prevCol = col - dc;
        if (_inside(prevRow, prevCol, size) &&
            board[prevRow * size + prevCol] == owner) {
          continue;
        }
        final List<int> run = <int>[index];
        int r = row + dr;
        int c = col + dc;
        while (_inside(r, c, size) && board[r * size + c] == owner) {
          run.add(r * size + c);
          r += dr;
          c += dc;
        }
        if (run.length >= winLength) {
          return GameResult(
            resolution: GameResolution.victory,
            winner: owner,
            winningLine: run,
          );
        }
      }
    }
    if (!board.contains(null)) {
      return GameResult(resolution: GameResolution.draw);
    }
    return GameResult(resolution: GameResolution.ongoing);
  }

  /// [who] colocar uma peça em [index] fecha uma linha de [winLength]?
  ///
  /// Olha só as quatro retas que passam por [index], sem copiar o tabuleiro:
  /// é o teste barato que a CPU roda centenas de vezes por jogada. A casa
  /// [index] é tratada como se já fosse de [who], esteja vazia ou não.
  static bool completesLine(
    List<PlayerMarker?> board,
    int index,
    PlayerMarker who, {
    required int size,
    required int winLength,
  }) {
    for (final (int dr, int dc) in lineDirections) {
      if (runLengthThrough(board, index, who, dr, dc, size: size) >=
          winLength) {
        return true;
      }
    }
    return false;
  }

  /// Tamanho da sequência de [who] que passaria por [index] na direção
  /// ([dr], [dc]) contando a própria casa [index].
  static int runLengthThrough(
    List<PlayerMarker?> board,
    int index,
    PlayerMarker who,
    int dr,
    int dc, {
    required int size,
  }) {
    final int row = index ~/ size;
    final int col = index % size;
    int count = 1;
    for (final int sign in const <int>[1, -1]) {
      int r = row + dr * sign;
      int c = col + dc * sign;
      while (_inside(r, c, size) && board[r * size + c] == who) {
        count += 1;
        r += dr * sign;
        c += dc * sign;
      }
    }
    return count;
  }

  static bool _inside(int row, int col, int size) =>
      row >= 0 && row < size && col >= 0 && col < size;
}

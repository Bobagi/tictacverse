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
        return GameResult(resolution: GameResolution.victory, winner: first);
      }
    }
    if (!board.contains(null)) {
      return GameResult(resolution: GameResolution.draw);
    }
    return GameResult(resolution: GameResolution.ongoing);
  }
}

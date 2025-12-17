import 'player_marker.dart';

enum GameResolution {
  ongoing,
  draw,
  victory,
}

class GameResult {
  GameResult({required this.resolution, this.winner, this.winningLine});

  final GameResolution resolution;
  final PlayerMarker? winner;
  final List<int>? winningLine;

  bool get isFinal => resolution != GameResolution.ongoing;
}

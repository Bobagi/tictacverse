import 'player_marker.dart';

enum GameResolution {
  ongoing,
  draw,
  victory,
}

class GameResult {
  GameResult({required this.resolution, this.winner});

  final GameResolution resolution;
  final PlayerMarker? winner;

  bool get isFinal => resolution != GameResolution.ongoing;
}

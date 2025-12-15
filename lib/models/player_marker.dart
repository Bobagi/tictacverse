enum PlayerMarker {
  cross,
  nought,
}

extension PlayerMarkerToggle on PlayerMarker {
  PlayerMarker get opponent => this == PlayerMarker.cross ? PlayerMarker.nought : PlayerMarker.cross;

  String get symbol => this == PlayerMarker.cross ? 'X' : 'O';
}

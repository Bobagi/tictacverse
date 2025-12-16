enum ChaosEffectType {
  removePiece,
  blockCell,
  swapSymbols,
}

class ChaosEvent {
  ChaosEvent({required this.type, this.targetIndex});

  final ChaosEffectType type;
  final int? targetIndex;
}

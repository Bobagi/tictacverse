import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/player_marker.dart';
import '../../services/visual_assets.dart';
import 'modern_background.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({
    super.key,
    required this.board,
    required this.blockedCells,
    required this.onCellSelected,
    this.visualAssetConfig,
  });

  final List<PlayerMarker?> board;
  final List<int> blockedCells;
  final void Function(int index) onCellSelected;
  final VisualAssetConfig? visualAssetConfig;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late final Random _randomGenerator = Random();
  late VisualAssetConfig _assetConfig = widget.visualAssetConfig ?? VisualAssetConfig();
  late Map<int, double> _cellRotations = <int, double>{};
  late Map<PlayerMarker, Color> _playerGlowColors = <PlayerMarker, Color>{};
  late List<PlayerMarker?> _previousBoardState = List<PlayerMarker?>.from(widget.board);

  @override
  void initState() {
    super.initState();
    _assignGlowColors();
  }

  @override
  void didUpdateWidget(GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visualAssetConfig != null && widget.visualAssetConfig != oldWidget.visualAssetConfig) {
      _assetConfig = widget.visualAssetConfig!;
    }
    if (_boardWasReset()) {
      _cellRotations = <int, double>{};
      _assignGlowColors();
    }
    _storeRotationsForNewPlacements();
    _previousBoardState = List<PlayerMarker?>.from(widget.board);
  }

  @override
  Widget build(BuildContext context) {
    final VisualAssetConfig resolvedAssetConfig = _assetConfig;
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double cellExtent = constraints.biggest.shortestSide / 3;
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Center(
                    child: Image.asset(
                      resolvedAssetConfig.boardAssetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemCount: widget.board.length,
                  itemBuilder: (BuildContext context, int index) => _buildCell(
                    context,
                    index,
                    cellExtent,
                    resolvedAssetConfig,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int index, double cellExtent, VisualAssetConfig assetConfig) {
    final PlayerMarker? marker = widget.board[index];
    final bool isBlocked = widget.blockedCells.contains(index);
    return GestureDetector(
      onTap: () => widget.onCellSelected(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          color: Colors.transparent,
        ),
        child: Stack(
          children: <Widget>[
            if (marker != null) _buildMarkerWithEffects(marker, index, cellExtent, assetConfig),
            if (isBlocked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.block, color: Colors.redAccent.shade200),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerWithEffects(
    PlayerMarker marker,
    int index,
    double cellExtent,
    VisualAssetConfig assetConfig,
  ) {
    final double rotationAngle = _cellRotations[index] ?? 0;
    final Color glowColor = _playerGlowColors[marker] ?? Colors.cyanAccent;
    final String assetPath = marker == PlayerMarker.cross ? assetConfig.crossAssetPath : assetConfig.noughtAssetPath;
    return Center(
      child: Transform.rotate(
        angle: rotationAngle,
        child: Container(
          width: cellExtent * 0.72,
          height: cellExtent * 0.72,
          decoration: BoxDecoration(
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: glowColor.withOpacity(0.48),
                blurRadius: 36,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: glowColor.withOpacity(0.22),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _assignGlowColors() {
    final bool crossReceivesBlue = _randomGenerator.nextBool();
    const Color electricBlue = Color(0xFF6BE0FF);
    const Color neonPink = Color(0xFFFF6BD9);
    _playerGlowColors = crossReceivesBlue
        ? <PlayerMarker, Color>{
            PlayerMarker.cross: electricBlue,
            PlayerMarker.nought: neonPink,
          }
        : <PlayerMarker, Color>{
            PlayerMarker.cross: neonPink,
            PlayerMarker.nought: electricBlue,
          };
  }

  void _storeRotationsForNewPlacements() {
    for (int index = 0; index < widget.board.length; index++) {
      final PlayerMarker? previousMarker = _previousBoardState[index];
      final PlayerMarker? currentMarker = widget.board[index];
      final bool placementIsNew = previousMarker == null && currentMarker != null;
      if (placementIsNew) {
        _cellRotations[index] = _generateQuarterTurnRotation();
      }
    }
  }

  bool _boardWasReset() {
    final bool hadMarkers = _previousBoardState.any((PlayerMarker? marker) => marker != null);
    final bool isNowEmpty = widget.board.every((PlayerMarker? marker) => marker == null);
    return hadMarkers && isNowEmpty;
  }

  double _generateQuarterTurnRotation() {
    const List<double> quarterTurns = <double>[0, pi / 2, pi, 3 * pi / 2];
    final int randomIndex = _randomGenerator.nextInt(quarterTurns.length);
    return quarterTurns[randomIndex];
  }
}

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

class _GameBoardState extends State<GameBoard> with SingleTickerProviderStateMixin {
  late final Random _randomGenerator = Random();
  late VisualAssetConfig _assetConfig = widget.visualAssetConfig ?? VisualAssetConfig();
  late Map<int, double> _cellRotations = <int, double>{};
  late Map<PlayerMarker, Color> _playerGlowColors = <PlayerMarker, Color>{};
  late List<PlayerMarker?> _previousBoardState = List<PlayerMarker?>.from(widget.board);
  late final AnimationController _neonPulseController =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

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
  void dispose() {
    _neonPulseController.dispose();
    super.dispose();
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
                  child: AnimatedBuilder(
                    animation: _neonPulseController,
                    builder: (BuildContext context, Widget? _) {
                      return CustomPaint(
                        painter: NeonGridPainter(progress: _neonPulseController.value),
                      );
                    },
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
          width: cellExtent * 0.64,
          height: cellExtent * 0.64,
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

class NeonGridPainter extends CustomPainter {
  NeonGridPainter({required this.progress});

  final double progress;

  static const Color electricBlue = Color(0xFF6BE0FF);
  static const Color neonPink = Color(0xFFFF6BD9);

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.shortestSide * 0.04;
    final double glowStrokeWidth = strokeWidth * 1.55;
    final Paint glowPaint = _buildGlowPaint(glowStrokeWidth);
    final Paint linePaint = _buildLinePaint(strokeWidth);

    final double firstDivision = size.width / 3;
    final double secondDivision = 2 * firstDivision;
    final Path gridPath = Path()
      ..moveTo(firstDivision, 0)
      ..lineTo(firstDivision, size.height)
      ..moveTo(secondDivision, 0)
      ..lineTo(secondDivision, size.height)
      ..moveTo(0, firstDivision)
      ..lineTo(size.width, firstDivision)
      ..moveTo(0, secondDivision)
      ..lineTo(size.width, secondDivision);

    canvas.drawPath(gridPath, glowPaint);
    canvas.drawPath(gridPath, linePaint);
  }

  Paint _buildLinePaint(double strokeWidth) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = _buildGradientShader(strokeWidth);
  }

  Paint _buildGlowPaint(double strokeWidth) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..shader = _buildGradientShader(strokeWidth);
  }

  Shader _buildGradientShader(double strokeWidth) {
    final Color primary = Color.lerp(electricBlue, neonPink, 0.5 * (1 + sin(progress * 2 * pi)))!;
    final Color secondary = Color.lerp(neonPink, electricBlue, 0.5 * (1 + cos(progress * 2 * pi)))!;
    return LinearGradient(
      colors: <Color>[primary.withOpacity(0.85), secondary.withOpacity(0.85), primary.withOpacity(0.85)],
      stops: const <double>[0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, strokeWidth * 20, strokeWidth * 20));
  }

  @override
  bool shouldRepaint(covariant NeonGridPainter oldDelegate) => oldDelegate.progress != progress;
}

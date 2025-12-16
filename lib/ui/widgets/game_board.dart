import 'package:flutter/material.dart';

import '../../models/player_marker.dart';
import '../../services/visual_assets.dart';
import 'modern_background.dart';

class GameBoard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final VisualAssetConfig assetConfig = visualAssetConfig ?? VisualAssetConfig();
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
                      assetConfig.boardAssetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemCount: board.length,
                  itemBuilder: (BuildContext context, int index) => _buildCell(
                    context,
                    index,
                    cellExtent,
                    assetConfig,
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
    final PlayerMarker? marker = board[index];
    final bool isBlocked = blockedCells.contains(index);
    return GestureDetector(
      onTap: () => onCellSelected(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          color: Colors.transparent,
        ),
        child: Stack(
          children: <Widget>[
            if (marker != null)
              Center(
                child: Image.asset(
                  marker == PlayerMarker.cross ? assetConfig.crossAssetPath : assetConfig.noughtAssetPath,
                  width: cellExtent * 0.7,
                  height: cellExtent * 0.7,
                  fit: BoxFit.contain,
                ),
              ),
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
}

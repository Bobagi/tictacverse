import 'package:flutter/material.dart';

import '../../models/player_marker.dart';
import '../../services/visual_assets.dart';

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
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        shrinkWrap: true,
        children: List<Widget>.generate(board.length, (int index) => _buildCell(context, index)),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int index) {
    final PlayerMarker? marker = board[index];
    final bool isBlocked = blockedCells.contains(index);
    return GestureDetector(
      onTap: () => onCellSelected(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: isBlocked
              ? Icon(Icons.block, color: Colors.red.shade400)
              : Text(
                  marker?.symbol ?? '',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
        ),
      ),
    );
  }
}

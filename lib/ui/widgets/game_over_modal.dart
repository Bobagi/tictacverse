import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../models/player_marker.dart';
import '../../services/visual_assets.dart';
import 'modern_background.dart';

class GameOverModal extends StatelessWidget {
  const GameOverModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPlayAgain,
    required this.onBackToMenu,
    this.winner,
    this.visualAssets,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToMenu;
  final PlayerMarker? winner;
  final VisualAssetConfig? visualAssets;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            _buildWinnerDetails(context),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade400,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                  onPressed: onPlayAgain,
                  child: Text(localization.playAgain),
                ),
                TextButton(onPressed: onBackToMenu, child: Text(localization.backToMenu)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerDetails(BuildContext context) {
    if (winner == null || visualAssets == null) {
      return Text(subtitle, style: Theme.of(context).textTheme.bodyMedium);
    }

    final String assetPath = winner == PlayerMarker.cross
        ? visualAssets!.crossAssetPath
        : visualAssets!.noughtAssetPath;
    final Color accentColor = winner == PlayerMarker.cross ? const Color(0xFF6BE0FF) : const Color(0xFFFF6BD9);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withOpacity(0.8), width: 2),
            boxShadow: <BoxShadow>[
              BoxShadow(color: accentColor.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Image.asset(assetPath, width: 28, height: 28, fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

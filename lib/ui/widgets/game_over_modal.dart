import 'package:flutter/material.dart';

import 'package:tictacverse/l10n/app_localizations.dart';
import '../../models/achievement.dart';
import '../../models/player_marker.dart';
import '../../services/audio_service.dart';
import '../../services/progression_engine.dart';
import '../../services/visual_assets.dart';
import 'achievements_sheet.dart';
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
    this.progression,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToMenu;
  final PlayerMarker? winner;
  final VisualAssetConfig? visualAssets;

  /// Recompensa da partida. Fica dentro do modal de propósito: um SnackBar
  /// aqui apareceria atrás dele (é o bug já conhecido do sheet de ajustes).
  final ProgressionResult? progression;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              _buildWinnerDetails(context),
              _buildProgressionRewards(context, localization),
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
                    onPressed: () {
                      AudioService.instance.playUiClick();
                      onPlayAgain();
                    },
                    child: Text(localization.playAgain),
                  ),
                  TextButton(
                    onPressed: () {
                      AudioService.instance.playUiClick();
                      onBackToMenu();
                    },
                    child: Text(localization.backToMenu),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Faixa de recompensa: XP sempre, e chips de nível/conquista quando houver.
  Widget _buildProgressionRewards(
    BuildContext context,
    AppLocalizations localization,
  ) {
    final ProgressionResult? result = progression;
    if (result == null || result.xpGained <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _RewardChip(
            icon: Icons.bolt_rounded,
            label: localization.xpGained(result.xpGained),
            tint: VerseColors.cross,
          ),
          if (result.leveledUp)
            _RewardChip(
              icon: Icons.trending_up_rounded,
              label: localization.levelUpToast(result.levelAfter),
              tint: VerseColors.energy,
            ),
          for (final AchievementDefinition achievement in result.newlyUnlocked)
            _RewardChip(
              icon: Icons.emoji_events_rounded,
              label: achievement.title(localization),
              tint: achievementTierColor(achievement.tier),
            ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accentColor.withOpacity(0.9), width: 2.5),
        boxShadow: <BoxShadow>[
          BoxShadow(color: accentColor.withOpacity(0.55), blurRadius: 18, offset: const Offset(0, 8)),
        ],
        gradient: RadialGradient(
          colors: <Color>[
            accentColor.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Image.asset(
        assetPath,
        width: 38,
        height: 38,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tint.withOpacity(0.16),
        border: Border.all(color: tint.withOpacity(0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

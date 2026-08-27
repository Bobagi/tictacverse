import 'package:flutter/material.dart';

import 'package:tictacverse/l10n/app_localizations.dart';
import '../../models/achievement.dart';
import '../../models/player_marker.dart';
import '../../services/audio_service.dart';
import '../../services/progression_engine.dart';
import '../../services/visual_assets.dart';
import 'achievements_sheet.dart';
import 'modern_background.dart';

class GameOverModal extends StatefulWidget {
  const GameOverModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPlayAgain,
    required this.onBackToMenu,
    this.winner,
    this.visualAssets,
    this.progression,
    this.onWatchAdForDoubleXp,
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

  /// Exibe o anúncio premiado e devolve a recompensa JÁ CREDITADA, ou `null` se
  /// o jogador não assistiu até o fim. Quando é `null`, a oferta não aparece -
  /// é assim que a tela desliga o convite (anúncios off, nada carregado, ou
  /// logo depois de um intersticial).
  final Future<ProgressionResult?> Function()? onWatchAdForDoubleXp;

  @override
  State<GameOverModal> createState() => _GameOverModalState();
}

class _GameOverModalState extends State<GameOverModal> {
  /// Progressão exibida: começa na da partida e passa a incluir o bônus depois
  /// que o anúncio é assistido.
  ProgressionResult? _progression;
  bool _isWatchingAd = false;
  bool _claimed = false;
  bool _adFailed = false;

  @override
  void initState() {
    super.initState();
    _progression = widget.progression;
  }

  /// Uma oferta por partida: depois de creditada, o botão sai de cena. O
  /// `_claimed` é travado ANTES do `await` para que um toque duplo rápido não
  /// dispare dois anúncios.
  Future<void> _handleWatchAd() async {
    final Future<ProgressionResult?> Function()? request =
        widget.onWatchAdForDoubleXp;
    if (request == null || _isWatchingAd || _claimed) {
      return;
    }
    AudioService.instance.playUiClick();
    setState(() {
      _isWatchingAd = true;
      _adFailed = false;
    });
    final ProgressionResult? bonus = await request();
    if (!mounted) {
      return;
    }
    setState(() {
      _isWatchingAd = false;
      if (bonus == null) {
        _adFailed = true;
        return;
      }
      _claimed = true;
      final ProgressionResult? current = _progression;
      _progression = current == null ? bonus : current.mergedWith(bonus);
    });
  }

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
              Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              _buildWinnerDetails(context),
              _buildProgressionRewards(context, localization),
              _buildDoubleXpOffer(context, localization),
              const SizedBox(height: 12),
              // Wrap, não Row: em 360x640 os dois botões não cabem lado a lado
              // em inglês (estourava 85px), e menos ainda em hindi/bengali.
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade400,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                    onPressed: () {
                      AudioService.instance.playUiClick();
                      widget.onPlayAgain();
                    },
                    child: Text(localization.playAgain),
                  ),
                  TextButton(
                    onPressed: () {
                      AudioService.instance.playUiClick();
                      widget.onBackToMenu();
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
    final ProgressionResult? result = _progression;
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

  /// Convite para dobrar o XP assistindo a um anúncio premiado.
  ///
  /// Fica **abaixo** dos chips e separado da linha de ações por um respiro
  /// maior, com estilo de contorno em vez do verde sólido do "jogar de novo":
  /// clique acidental em anúncio é justamente o que derrubou a conta do AdMob
  /// em 2026-07, então a oferta nunca imita o botão primário nem encosta nele.
  Widget _buildDoubleXpOffer(
    BuildContext context,
    AppLocalizations localization,
  ) {
    if (widget.onWatchAdForDoubleXp == null) {
      return const SizedBox.shrink();
    }
    final ProgressionResult? result = _progression;
    if (result == null || result.xpGained <= 0) {
      return const SizedBox.shrink();
    }
    if (_claimed) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: _RewardChip(
          icon: Icons.check_circle_rounded,
          label: localization.doubleXpDone,
          tint: VerseColors.energy,
        ),
      );
    }
    if (_adFailed) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text(
          localization.doubleXpUnavailable,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: OutlinedButton.icon(
        onPressed: _isWatchingAd ? null : _handleWatchAd,
        style: OutlinedButton.styleFrom(
          foregroundColor: VerseColors.energy,
          side: BorderSide(color: VerseColors.energy.withOpacity(0.7)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        icon: _isWatchingAd
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_circle_outline_rounded, size: 20),
        label: Text(
          localization.doubleXpCta,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildWinnerDetails(BuildContext context) {
    if (widget.winner == null || widget.visualAssets == null) {
      return Text(widget.subtitle,
          style: Theme.of(context).textTheme.bodyMedium);
    }

    final String assetPath = widget.winner == PlayerMarker.cross
        ? widget.visualAssets!.crossAssetPath
        : widget.visualAssets!.noughtAssetPath;
    final Color accentColor = widget.winner == PlayerMarker.cross
        ? const Color(0xFF6BE0FF)
        : const Color(0xFFFF6BD9);

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
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

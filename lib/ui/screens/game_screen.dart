import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../controllers/banner_ad_controller.dart';
import '../../controllers/game_controller.dart';
import '../../controllers/interstitial_ad_controller.dart';
import '../../controllers/rewarded_ad_controller.dart';
import '../../models/chaos_event.dart';
import '../../models/game_mode.dart';
import '../../models/game_result.dart';
import '../../models/player_marker.dart';
import '../../services/ad_service.dart';
import '../../services/metrics_service.dart';
import '../../services/visual_assets.dart';
import '../widgets/game_board.dart';
import '../widgets/game_over_modal.dart';
import '../widgets/modern_background.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    required this.metricsService,
  });

  final GameController controller;
  final MetricsService metricsService;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final VisualAssetConfig _visualAssets = VisualAssetConfig();
  final BannerAdController bannerAdController = BannerAdController();
  final InterstitialAdController interstitialAdController = InterstitialAdController();
  final RewardedAdController rewardedAdController = RewardedAdController();
  final AdService adService = AdService();

  @override
  void initState() {
    super.initState();
    bannerAdController.loadBannerAd(
      onAdLoaded: _refreshBannerArea,
      onAdFailed: _refreshBannerArea,
    );
    interstitialAdController.loadInterstitialAd();
    rewardedAdController.loadRewardedAd();
  }

  @override
  void dispose() {
    bannerAdController.dispose();
    interstitialAdController.dispose();
    rewardedAdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(widget.controller.modeDefinition.title(localization))),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildStatusHud(localization),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GameBoard(
                          board: widget.controller.state.board,
                          blockedCells: widget.controller.state.blockedCells,
                          onCellSelected: _handleCellTap,
                          winningLine: widget.controller.state.result.winningLine,
                          winningPlayer: widget.controller.state.result.winner,
                          visualAssetConfig: _visualAssets,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPlayerMessageBanner(localization),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildBannerArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHud(AppLocalizations localization) {
    final PlayerMarker current = widget.controller.state.currentPlayer;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _buildPlayerAvatar(current),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${localization.currentPlayer}: ${current.symbol}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    localization.winInstruction,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _buildHudChip(Icons.sports_esports, localization.tapToClaim),
              if (widget.controller.state.movesRemaining != null)
                _buildHudChip(
                  Icons.timelapse_rounded,
                  '${localization.movesRemaining}: ${widget.controller.state.movesRemaining}',
                ),
              if (widget.controller.state.activeUltimateCondition != null)
                _buildHudChip(Icons.auto_awesome_rounded, widget.controller.state.activeUltimateCondition!.describe(localization)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHudChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: Colors.lightBlueAccent),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPlayerMessageBanner(AppLocalizations localization) {
    final PlayerMarker current = widget.controller.state.currentPlayer;
    final ChaosEvent? chaosEvent = widget.controller.state.activeChaosEvent;
    final String messageDetail = chaosEvent != null
        ? _describeChaosEvent(chaosEvent, localization)
        : widget.controller.state.activeUltimateCondition?.describe(localization) ?? localization.takeTurnCta;
    final Color accentColor = chaosEvent != null ? Colors.pinkAccent : Colors.lightBlueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            accentColor.withOpacity(0.18),
            const Color(0xFF0D1C3D).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: accentColor.withOpacity(0.28), blurRadius: 22, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        children: <Widget>[
          _buildPlayerAvatar(current),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${localization.currentPlayer}: ${current.symbol}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  messageDetail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withOpacity(0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.touch_app_rounded, color: accentColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  localization.playLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerArea() {
    return GlassPanel(
      child: SafeArea(
        top: false,
        child: Center(
          child: SizedBox(
            height: 50,
            child: bannerAdController.buildBannerAdWidget(),
          ),
        ),
      ),
    );
  }

  void _handleCellTap(int index) {
    setState(() {
      widget.controller.selectCell(index);
    });
    if (widget.controller.state.result.isFinal) {
      widget.metricsService.recordMatch(widget.controller.modeDefinition.type);
      if (adService.shouldShowInterstitialOnMatchEnd()) {
        interstitialAdController.showInterstitialAdIfAvailable();
      } else {
        interstitialAdController.loadInterstitialAd();
      }
      rewardedAdController.loadRewardedAd();
      _showGameOverSheet();
    }
  }

  Widget _buildPlayerAvatar(PlayerMarker marker) {
    final Color accentColor = marker == PlayerMarker.cross ? const Color(0xFF6BE0FF) : const Color(0xFFFF6BD9);
    final String assetPath = marker == PlayerMarker.cross ? _visualAssets.crossAssetPath : _visualAssets.noughtAssetPath;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: <Color>[accentColor.withOpacity(0.85), Colors.white.withOpacity(0.1)]),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(color: accentColor.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.16),
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withOpacity(0.4)),
        ),
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          assetPath,
          width: 16,
          height: 16,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  void _showGameOverSheet() {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    final GameResult result = widget.controller.state.result;
    final String title;
    final String subtitle;
    if (result.resolution == GameResolution.draw) {
      title = localization.drawResult;
      subtitle = localization.playAgain;
    } else {
      title = localization.winnerResult;
      subtitle = result.winner?.symbol ?? '';
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => GameOverModal(
        title: title,
        subtitle: subtitle,
        onPlayAgain: () {
          Navigator.of(context).pop();
          setState(widget.controller.resetMatch);
        },
        onBackToMenu: () {
          Navigator.of(context)
            ..pop()
            ..pop();
        },
        winner: result.winner,
        visualAssets: _visualAssets,
      ),
    );
  }

  void _refreshBannerArea() {
    if (mounted) {
      setState(() {});
    }
  }

  String _describeChaosEvent(ChaosEvent event, AppLocalizations localization) {
    switch (event.type) {
      case ChaosEffectType.removePiece:
        return localization.chaosRemovePiece;
      case ChaosEffectType.blockCell:
        return localization.chaosBlockCell;
      case ChaosEffectType.swapSymbols:
        return localization.chaosSwapSymbols;
    }
  }
}

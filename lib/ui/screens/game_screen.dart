import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../controllers/banner_ad_controller.dart';
import '../../controllers/game_controller.dart';
import '../../controllers/interstitial_ad_controller.dart';
import '../../controllers/rewarded_ad_controller.dart';
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
  final InterstitialAdController interstitialAdController =
      InterstitialAdController();
  final RewardedAdController rewardedAdController = RewardedAdController();
  final AdService adService = AdService();
  Timer? _cpuHighlightTimer;
  int? _cpuMoveHighlightIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bannerAdController.loadBannerAd(
        context: context,
        onAdLoaded: _refreshBannerArea,
        onAdFailed: _refreshBannerArea,
      );
    });
    interstitialAdController.loadInterstitialAd();
    rewardedAdController.loadRewardedAd();
  }

  @override
  void dispose() {
    _cpuHighlightTimer?.cancel();
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
        appBar: AppBar(
            title: Text(widget.controller.modeDefinition.title(localization))),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildStatusHud(localization),
                      const SizedBox(height: 12),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (BuildContext context,
                              BoxConstraints constraints) {
                            final double boardSize =
                                constraints.biggest.shortestSide;
                            return Center(
                              child: SizedBox(
                                width: boardSize,
                                height: boardSize,
                                child: GameBoard(
                                  board: widget.controller.state.board,
                                  blockedCells:
                                      widget.controller.state.blockedCells,
                                  onCellSelected: _handleCellTap,
                                  winningLine: widget
                                      .controller.state.result.winningLine,
                                  winningPlayer:
                                      widget.controller.state.result.winner,
                                  visualAssetConfig: _visualAssets,
                                  highlightIndex: _cpuMoveHighlightIndex,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _buildPlayerAvatar(current),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${localization.currentPlayer}: ${current.symbol}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localization.winInstruction,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showHelpModal(localization),
                icon: const Icon(Icons.help_outline_rounded,
                    color: Colors.white70),
                tooltip: localization.helpTitle,
              ),
            ],
          ),
          if (widget.controller.state.movesRemaining != null ||
              widget.controller.state.activeUltimateCondition !=
                  null) ...<Widget>[
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              if (widget.controller.state.movesRemaining != null)
                _buildHudChip(
                  Icons.timelapse_rounded,
                  '${localization.movesRemaining}: ${widget.controller.state.movesRemaining}',
                ),
              if (widget.controller.state.activeUltimateCondition != null)
                _buildHudChip(
                  Icons.auto_awesome_rounded,
                  widget.controller.state.activeUltimateCondition!
                      .describe(localization),
                ),
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
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerArea() {
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: bannerAdController.expectedAdHeight,
          child: bannerAdController.buildBannerAdWidget(),
        ),
      ),
    );
  }

  void _handleCellTap(int index) {
    final List<PlayerMarker?> previousBoard =
        List<PlayerMarker?>.from(widget.controller.state.board);
    setState(() {
      widget.controller.selectCell(index);
    });
    final int? cpuMoveIndex =
        _findCpuMoveIndex(previousBoard, widget.controller.state.board);
    if (cpuMoveIndex != null) {
      _triggerCpuMoveHighlight(cpuMoveIndex);
    }
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
    final Color accentColor = marker == PlayerMarker.cross
        ? const Color(0xFF6BE0FF)
        : const Color(0xFFFF6BD9);
    final String assetPath = marker == PlayerMarker.cross
        ? _visualAssets.crossAssetPath
        : _visualAssets.noughtAssetPath;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: <Color>[
          accentColor.withOpacity(0.85),
          Colors.white.withOpacity(0.1)
        ]),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: accentColor.withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 8)),
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

  int? _findCpuMoveIndex(
      List<PlayerMarker?> previousBoard, List<PlayerMarker?> currentBoard) {
    for (int index = 0; index < currentBoard.length; index++) {
      if (previousBoard[index] == null &&
          currentBoard[index] == PlayerMarker.nought) {
        return index;
      }
    }
    return null;
  }

  void _triggerCpuMoveHighlight(int index) {
    _cpuHighlightTimer?.cancel();
    setState(() {
      _cpuMoveHighlightIndex = index;
    });
    _cpuHighlightTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _cpuMoveHighlightIndex = null;
        });
      }
    });
  }

  void _showHelpModal(AppLocalizations localization) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.help_outline_rounded,
                      color: Colors.lightBlueAccent),
                  const SizedBox(width: 8),
                  Text(
                    localization.helpTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                localization.tapToClaim,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(localization.closeLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

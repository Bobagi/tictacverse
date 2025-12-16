import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';
import '../../localization/app_localizations.dart';
import '../../models/chaos_event.dart';
import '../../models/game_mode.dart';
import '../../models/game_result.dart';
import '../../models/player_marker.dart';
import '../../services/ad_service.dart';
import '../../services/metrics_service.dart';
import '../widgets/game_board.dart';
import '../widgets/game_over_modal.dart';
import '../widgets/modern_background.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    required this.adService,
    required this.metricsService,
  });

  final GameController controller;
  final AdService adService;
  final MetricsService metricsService;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context);
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
                GlassPanel(child: _buildStatusRow(localization)),
                const SizedBox(height: 16),
                GameBoard(
                  board: widget.controller.state.board,
                  blockedCells: widget.controller.state.blockedCells,
                  onCellSelected: _handleCellTap,
                ),
                const SizedBox(height: 16),
                if (_hasModeInfo)
                  GlassPanel(
                    child: _buildModeInfo(localization),
                  ),
                const Spacer(),
                if (widget.adService.shouldShowBannerOnGameScreen()) _buildBannerPlaceholder(localization),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(AppLocalizations localization) {
    final PlayerMarker current = widget.controller.state.currentPlayer;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text('${localization.currentPlayer}: ${current.symbol}', style: Theme.of(context).textTheme.titleMedium),
        if (widget.controller.state.movesRemaining != null)
          Text('${localization.movesRemaining}: ${widget.controller.state.movesRemaining}',
              style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildModeInfo(AppLocalizations localization) {
    final List<Widget> info = <Widget>[];
    final ChaosEvent? chaosEvent = widget.controller.state.activeChaosEvent;
    if (chaosEvent != null) {
      info.add(Text(_describeChaosEvent(chaosEvent, localization)));
    }
    if (widget.controller.state.activeUltimateCondition != null) {
      info.add(Text(widget.controller.state.activeUltimateCondition!.describe(localization)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: info);
  }

  Widget _buildBannerPlaceholder(AppLocalizations localization) {
    return GlassPanel(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(localization.adsBannerPlacement),
          const Icon(Icons.ad_units),
        ],
      ),
    );
  }

  void _handleCellTap(int index) {
    setState(() {
      widget.controller.selectCell(index);
    });
    if (widget.controller.state.result.isFinal) {
      widget.metricsService.recordMatch(widget.controller.modeDefinition.type);
      _maybeShowInterstitial();
      _showGameOverSheet();
    }
  }

  void _maybeShowInterstitial() {
    if (widget.adService.shouldShowInterstitialOnMatchEnd()) {
      widget.metricsService.recordAdImpression();
    }
  }

  void _showGameOverSheet() {
    final AppLocalizations localization = AppLocalizations.of(context);
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
      ),
    );
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

  bool get _hasModeInfo {
    return widget.controller.state.activeChaosEvent != null || widget.controller.state.activeUltimateCondition != null;
  }
}

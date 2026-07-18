import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../controllers/banner_ad_controller.dart';
import '../../controllers/interstitial_ad_controller.dart';
import '../../controllers/modes/ultimate2_engine.dart';
import '../../models/cpu_difficulty.dart';
import '../../models/game_mode.dart';
import '../../models/game_result.dart';
import '../../models/player_marker.dart';
import '../../services/ad_service.dart';
import '../../services/ads_configuration.dart';
import '../../services/audio_service.dart';
import '../../services/metrics_service.dart';
import '../../services/review_service.dart';
import '../../services/storage_service.dart';
import '../../services/visual_assets.dart';
import '../widgets/board_shake.dart';
import '../widgets/game_over_modal.dart';
import '../widgets/modern_background.dart';
import '../widgets/neon_win_line.dart';
import '../widgets/pop_in.dart';

class Ultimate2Screen extends StatefulWidget {
  const Ultimate2Screen({
    super.key,
    required this.playAgainstCpu,
    required this.cpuDifficulty,
    required this.metricsService,
  });

  final bool playAgainstCpu;
  final CpuDifficulty cpuDifficulty;
  final MetricsService metricsService;

  @override
  State<Ultimate2Screen> createState() => _Ultimate2ScreenState();
}

class _Ultimate2ScreenState extends State<Ultimate2Screen> {
  final Ultimate2Engine engine = Ultimate2Engine();
  final Ultimate2Cpu cpu = Ultimate2Cpu();
  final VisualAssetConfig visualAssets = VisualAssetConfig();
  final BannerAdController bannerAdController = BannerAdController();
  final InterstitialAdController interstitialAdController = InterstitialAdController();
  final AdService adService = AdService();
  final AudioService audioService = AudioService.instance;
  late Ultimate2State state;
  Timer? _cpuMoveTimer;
  Timer? _gameOverTimer;
  bool _cpuThinking = false;
  int _shakeTick = 0;

  static const Duration _cpuThinkDelay = Duration(milliseconds: 550);
  static const Duration _winCelebration = Duration(milliseconds: 1650);
  static const Duration _drawPause = Duration(milliseconds: 650);

  @override
  void initState() {
    super.initState();
    state = engine.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bannerAdController.loadBannerAd(
        context: context,
        onAdLoaded: _refresh,
        onAdFailed: _refresh,
      );
      audioService.ensureBackgroundMusic();
    });
    interstitialAdController.loadInterstitialAd();
  }

  @override
  void dispose() {
    _cpuMoveTimer?.cancel();
    _gameOverTimer?.cancel();
    bannerAdController.dispose();
    interstitialAdController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTap(int board, int cell) {
    // Durante a pausa da CPU um toque jogaria PELA CPU — bloquear.
    if (_cpuThinking || !state.isCellPlayable(board, cell)) {
      return;
    }
    setState(() {
      state = engine.handleMove(state, board, cell);
    });
    audioService.playMoveSfx();
    if (state.result.isFinal) {
      _onMatchEnded();
      return;
    }
    if (widget.playAgainstCpu &&
        state.currentPlayer == PlayerMarker.nought) {
      _cpuThinking = true;
      _cpuMoveTimer?.cancel();
      _cpuMoveTimer = Timer(_cpuThinkDelay, _performDelayedCpuMove);
    }
  }

  void _performDelayedCpuMove() {
    if (!mounted) {
      return;
    }
    setState(() {
      final (int, int)? move = cpu.chooseMove(state, widget.cpuDifficulty);
      if (move != null) {
        state = engine.handleMove(state, move.$1, move.$2);
      }
      _cpuThinking = false;
    });
    audioService.playMoveSfx();
    if (state.result.isFinal) {
      _onMatchEnded();
    }
  }

  void _onMatchEnded() {
    widget.metricsService.recordMatch(GameModeType.ultimate2);
    StorageService.instance.recordMatch(
      mode: GameModeType.ultimate2,
      result: state.result,
      vsCpu: widget.playAgainstCpu,
    );
    // Celebração antes do modal: shake + linha neon do macro-tabuleiro
    // desenhando por inteiro; review/interstitial só depois.
    final GameResult finalResult = state.result;
    final bool hasWinLine =
        finalResult.winningLine != null && finalResult.winner != null;
    if (hasWinLine) {
      setState(() {
        _shakeTick++;
      });
    }
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final Duration delay = reduceMotion
        ? const Duration(milliseconds: 200)
        : (hasWinLine ? _winCelebration : _drawPause);
    _gameOverTimer?.cancel();
    _gameOverTimer = Timer(delay, () {
      if (!mounted) {
        return;
      }
      if (widget.playAgainstCpu && finalResult.winner == PlayerMarker.cross) {
        ReviewService.instance.maybeRequestReview();
      }
      if (adService.shouldShowInterstitialOnMatchEnd()) {
        interstitialAdController.showInterstitialAdIfAvailable();
      } else {
        interstitialAdController.loadInterstitialAd();
      }
      _showGameOverSheet();
    });
  }

  void _showGameOverSheet() {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    final GameResult result = state.result;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => GameOverModal(
        title: result.resolution == GameResolution.draw
            ? localization.drawResult
            : localization.winnerResult,
        subtitle: result.resolution == GameResolution.draw
            ? localization.playAgain
            : result.winner?.symbol ?? '',
        onPlayAgain: () {
          Navigator.of(context).pop();
          _cpuMoveTimer?.cancel();
          setState(() {
            state = engine.start();
            _cpuThinking = false;
          });
        },
        onBackToMenu: () {
          Navigator.of(context)
            ..pop()
            ..pop();
        },
        winner: result.winner,
        visualAssets: visualAssets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(localization.modeUltimate2Title),
          actions: <Widget>[
            ValueListenableBuilder<bool>(
              valueListenable: audioService.isMutedListenable,
              builder: (BuildContext context, bool isMuted, Widget? _) {
                return IconButton(
                  icon: Icon(
                      isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                  tooltip: localization.muteLabel,
                  onPressed: () => audioService.setMuted(!isMuted),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: localization.helpTitle,
              onPressed: () => _showHelp(localization),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHud(localization),
                const SizedBox(height: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final double size = constraints.biggest.shortestSide;
                      return Center(
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: BoardShake(
                            trigger: _shakeTick,
                            child: _MacroBoard(
                              state: state,
                              visualAssets: visualAssets,
                              onCellTap: _handleTap,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (AdsConfiguration.adsEnabled) ...<Widget>[
                  const SizedBox(height: 10),
                  GlassPanel(
                    padding: EdgeInsets.zero,
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: bannerAdController.expectedAdHeight,
                        child: bannerAdController.buildBannerAdWidget(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHud(AppLocalizations localization) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: <Widget>[
          Text(
            '${localization.currentPlayer}: ${state.currentPlayer.symbol}',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.activeBoard == null
                  ? localization.ultimate2FreeMove
                  : localization.ultimate2PlayIn,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp(AppLocalizations localization) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: GlassPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(localization.helpTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(localization.ultimate2Help,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70)),
                const SizedBox(height: 10),
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
      ),
    );
  }
}

class _MacroBoard extends StatelessWidget {
  const _MacroBoard({
    required this.state,
    required this.visualAssets,
    required this.onCellTap,
  });

  final Ultimate2State state;
  final VisualAssetConfig visualAssets;
  final void Function(int board, int cell) onCellTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
        color: Colors.white.withOpacity(0.03),
      ),
      padding: const EdgeInsets.all(6),
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              for (int row = 0; row < 3; row++)
                Expanded(
                  child: Row(
                    children: <Widget>[
                      for (int col = 0; col < 3; col++)
                        Expanded(child: _buildMini(context, row * 3 + col)),
                    ],
                  ),
                ),
            ],
          ),
          if (state.result.resolution == GameResolution.victory &&
              state.result.winningLine != null)
            Positioned.fill(
              child: IgnorePointer(
                child: NeonWinLine(
                  key: ValueKey<String>(
                      'macro-${state.result.winningLine!.join('-')}'),
                  winningLine: state.result.winningLine!,
                  color: state.result.winner == PlayerMarker.cross
                      ? const Color(0xFF6BE0FF)
                      : const Color(0xFFFF6BD9),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMini(BuildContext context, int board) {
    final bool playable = state.isBoardPlayable(board);
    final PlayerMarker? owner = state.macro[board];
    final bool closed = state.isBoardClosed(board);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: playable
              ? Colors.cyanAccent.withOpacity(0.10)
              : Colors.white.withOpacity(0.03),
          border: Border.all(
            color: playable
                ? Colors.cyanAccent
                : Colors.white.withOpacity(closed ? 0.10 : 0.22),
            width: playable ? 1.8 : 1,
          ),
          boxShadow: playable
              ? <BoxShadow>[
                  BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.35), blurRadius: 12),
                ]
              : const <BoxShadow>[],
        ),
        child: Stack(
          children: <Widget>[
            Opacity(
              opacity: owner != null ? 0.25 : (closed ? 0.45 : 1),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Column(
                  children: <Widget>[
                    for (int r = 0; r < 3; r++)
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            for (int c = 0; c < 3; c++)
                              Expanded(child: _buildCell(board, r * 3 + c)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (owner != null)
              Positioned.fill(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.72,
                    heightFactor: 0.72,
                    child: PopIn(
                      beginScale: 1.7,
                      duration: const Duration(milliseconds: 380),
                      child: Image.asset(
                        owner == PlayerMarker.cross
                            ? visualAssets.crossAssetPath
                            : visualAssets.noughtAssetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(int board, int cell) {
    final PlayerMarker? marker = state.boards[board][cell];
    final bool isLast = state.lastBoard == board && state.lastCell == cell;
    return GestureDetector(
      onTap: () => onCellTap(board, cell),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isLast
              ? Colors.amberAccent.withOpacity(0.18)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
        ),
        child: marker == null
            ? null
            : Padding(
                padding: const EdgeInsets.all(2),
                child: PopIn(
                  duration: const Duration(milliseconds: 200),
                  child: Image.asset(
                    marker == PlayerMarker.cross
                        ? visualAssets.crossAssetPath
                        : visualAssets.noughtAssetPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
      ),
    );
  }
}

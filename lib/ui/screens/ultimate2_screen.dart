import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../controllers/banner_ad_controller.dart';
import '../../controllers/interstitial_ad_controller.dart';
import '../../controllers/modes/ultimate2_engine.dart';
import '../../controllers/rewarded_ad_controller.dart';
import '../../models/cpu_difficulty.dart';
import '../../models/game_mode.dart';
import '../../models/game_result.dart';
import '../../models/player_marker.dart';
import '../../models/progress_state.dart';
import '../../services/ad_service.dart';
import '../../services/ads_configuration.dart';
import '../../services/audio_service.dart';
import '../../services/double_xp_offer.dart';
import '../../services/haptics_service.dart';
import '../../services/match_feedback.dart';
import '../../services/metrics_service.dart';
import '../../services/progression_engine.dart';
import '../../services/progression_service.dart';
import '../../services/review_service.dart';
import '../../services/storage_service.dart';
import '../../services/visual_assets.dart';
import '../widgets/board_shake.dart';
import '../widgets/game_over_modal.dart';
import '../widgets/juice/particles.dart';
import '../widgets/juice/press_scale.dart';
import '../widgets/juice/pulse.dart';
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
  final InterstitialAdController interstitialAdController =
      InterstitialAdController();
  final RewardedAdController rewardedAdController = RewardedAdController();
  final AdService adService = AdService.instance;
  final AudioService audioService = AudioService.instance;
  final HapticsService haptics = HapticsService.instance;
  final ParticleController _screenParticles = ParticleController();
  final ParticleController _boardParticles = ParticleController();
  late final DoubleXpOffer _doubleXpOffer = DoubleXpOffer(
    rewardedAdController: rewardedAdController,
    adService: adService,
  );
  late Ultimate2State state;
  Timer? _cpuMoveTimer;
  Timer? _gameOverTimer;
  bool _cpuThinking = false;
  int _shakeTick = 0;

  /// Recompensa da última partida, exibida dentro do modal de fim.
  ProgressionResult? _progressionResult;

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
    // O carro-chefe rende 50% mais XP: é onde a oferta de dobrar mais vale.
    rewardedAdController.loadRewardedAd();
  }

  @override
  void dispose() {
    _cpuMoveTimer?.cancel();
    _gameOverTimer?.cancel();
    bannerAdController.dispose();
    interstitialAdController.dispose();
    rewardedAdController.dispose();
    _screenParticles.dispose();
    _boardParticles.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTap(int board, int cell) {
    // Durante a pausa da CPU um toque jogaria PELA CPU - bloquear.
    if (_cpuThinking || !state.isCellPlayable(board, cell)) {
      return;
    }
    final Ultimate2State previous = state;
    setState(() {
      state = engine.handleMove(state, board, cell);
    });
    audioService.playMoveSfx(
        isNought: previous.currentPlayer == PlayerMarker.nought);
    haptics.play(HapticCue.place);
    _announceCapture(previous, board);
    if (state.result.isFinal) {
      _onMatchEnded();
      return;
    }
    if (widget.playAgainstCpu && state.currentPlayer == PlayerMarker.nought) {
      _cpuThinking = true;
      _cpuMoveTimer?.cancel();
      _cpuMoveTimer = Timer(_cpuThinkDelay, _performDelayedCpuMove);
    }
  }

  void _performDelayedCpuMove() {
    if (!mounted) {
      return;
    }
    final Ultimate2State previous = state;
    (int, int)? move;
    setState(() {
      move = cpu.chooseMove(state, widget.cpuDifficulty);
      if (move != null) {
        state = engine.handleMove(state, move!.$1, move!.$2);
      }
      _cpuThinking = false;
    });
    audioService.playMoveSfx(isNought: true);
    if (move != null) {
      _announceCapture(previous, move!.$1);
    }
    if (state.result.isFinal) {
      _onMatchEnded();
    }
  }

  /// Mini-tabuleiro acabou de ganhar dono: som de confirmação, pulso mais
  /// forte e tremida curta. É a pequena vitória dentro da partida grande.
  void _announceCapture(Ultimate2State previous, int board) {
    if (previous.macro[board] == null && state.macro[board] != null) {
      audioService.play(Sfx.capture);
      haptics.play(HapticCue.capture);
      if (!state.result.isFinal) {
        setState(() {
          _shakeTick++;
        });
      }
    }
  }

  void _onMatchEnded() {
    final bool vsCpu = widget.playAgainstCpu;
    widget.metricsService.recordMatch(GameModeType.ultimate2);
    StorageService.instance.recordMatch(
      mode: GameModeType.ultimate2,
      result: state.result,
      vsCpu: vsCpu,
    );
    final ProgressionResult progression =
        ProgressionService.instance.registerMatch(
      MatchOutcome(
        mode: GameModeType.ultimate2,
        vsCpu: vsCpu,
        difficulty: widget.cpuDifficulty,
        humanWon: vsCpu &&
            state.result.resolution == GameResolution.victory &&
            state.result.winner == PlayerMarker.cross,
        isDraw: state.result.resolution == GameResolution.draw,
      ),
    );
    _progressionResult = progression;
    _doubleXpOffer.onMatchEnded(progression);
    // Celebração antes do modal: shake + linha neon do macro-tabuleiro
    // desenhando por inteiro; review/interstitial só depois.
    final GameResult finalResult = state.result;
    final bool hasWinLine =
        finalResult.winningLine != null && finalResult.winner != null;
    final MatchEndKind kind = classifyMatchEnd(finalResult, vsCpu: vsCpu);
    if (hasWinLine) {
      setState(() {
        _shakeTick++;
      });
      audioService.play(Sfx.winLine);
    }
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final Duration delay = reduceMotion
        ? const Duration(milliseconds: 200)
        : (hasWinLine ? _winCelebration : _drawPause);
    Timer(
      reduceMotion || !hasWinLine
          ? Duration.zero
          : const Duration(milliseconds: 650),
      () {
        if (mounted) {
          playMatchEndFeedback(kind, screenParticles: _screenParticles);
        }
      },
    );
    _gameOverTimer?.cancel();
    _gameOverTimer = Timer(delay, () {
      if (!mounted) {
        return;
      }
      if (vsCpu && finalResult.winner == PlayerMarker.cross) {
        ReviewService.instance.maybeRequestReview();
      }
      bool interstitialShown = false;
      if (adService.shouldShowInterstitialOnMatchEnd()) {
        interstitialShown =
            interstitialAdController.showInterstitialAdIfAvailable();
      } else {
        interstitialAdController.loadInterstitialAd();
      }
      _doubleXpOffer.onCelebrationDone(interstitialShown: interstitialShown);
      _showGameOverSheet(kind);
    });
  }

  void _showGameOverSheet(MatchEndKind kind) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    final GameResult result = state.result;
    final bool vsCpu = widget.playAgainstCpu;
    final ProgressState progress = ProgressionService.instance.state;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      // Sem isto o sheet trava em 9/16 da tela e o modal cheio (sequências,
      // nível, conquista, barra, oferta) sairia cortado; o modal limita a
      // própria altura e rola por dentro.
      isScrollControlled: true,
      builder: (BuildContext context) => GameOverModal(
        progression: _progressionResult,
        title: matchEndTitle(localization, result, vsCpu: vsCpu),
        subtitle: localization.playAgain,
        onWatchAdForDoubleXp: _doubleXpOffer.build(),
        xpAfter: ProgressionService.instance.xp,
        winStreak: vsCpu ? progress.currentWinStreak : 0,
        isNewBestStreak: vsCpu &&
            kind == MatchEndKind.humanWin &&
            progress.currentWinStreak >= 2 &&
            progress.currentWinStreak == progress.bestWinStreak,
        dailyStreak:
            ProgressionEngine.effectiveDailyStreak(progress, DateTime.now()),
        celebrate:
            kind == MatchEndKind.humanWin || kind == MatchEndKind.twoPlayerWin,
        onPlayAgain: () {
          Navigator.of(context).pop();
          _cpuMoveTimer?.cancel();
          _screenParticles.clear();
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
                  icon: Icon(isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded),
                  tooltip: localization.muteLabel,
                  onPressed: () => audioService.setMuted(!isMuted),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: localization.helpTitle,
              onPressed: () {
                audioService.playUiClick();
                haptics.play(HapticCue.tap);
                _showHelp(localization);
              },
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildHud(localization),
                    const SizedBox(height: 10),
                    Expanded(
                      child: LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
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
                                  particles: _boardParticles,
                                  interactive:
                                      !_cpuThinking && !state.result.isFinal,
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
            Positioned.fill(child: ParticleField(controller: _screenParticles)),
          ],
        ),
      ),
    );
  }

  Widget _buildHud(AppLocalizations localization) {
    final bool humanTurn = !state.result.isFinal &&
        (!widget.playAgainstCpu ||
            (state.currentPlayer == PlayerMarker.cross && !_cpuThinking));
    final String hint;
    if (_cpuThinking) {
      hint = localization.cpuThinking;
    } else if (state.activeBoard == null) {
      hint = localization.ultimate2FreeMove;
    } else {
      hint = localization.ultimate2PlayIn;
    }
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: <Widget>[
          Pulse(
            active: humanTurn,
            maxScale: 1.08,
            child: Text(
              '${localization.currentPlayer}: ${state.currentPlayer.symbol}',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                hint,
                key: ValueKey<String>(hint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.cyanAccent),
              ),
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

class _MacroBoard extends StatefulWidget {
  const _MacroBoard({
    required this.state,
    required this.visualAssets,
    required this.onCellTap,
    required this.particles,
    required this.interactive,
  });

  final Ultimate2State state;
  final VisualAssetConfig visualAssets;
  final void Function(int board, int cell) onCellTap;
  final ParticleController particles;
  final bool interactive;

  @override
  State<_MacroBoard> createState() => _MacroBoardState();
}

class _MacroBoardState extends State<_MacroBoard> {
  static const double _outerPadding = 6;
  static const double _miniPadding = 4;
  static const double _miniInnerPadding = 3;

  double _lastSize = 0;

  @override
  void didUpdateWidget(_MacroBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _emitParticles(oldWidget.state, widget.state);
  }

  /// Centro de uma célula (board, cell) nas coordenadas do Stack interno.
  Offset _cellCenter(int board, int cell) {
    final double inner = _lastSize - 2 * _outerPadding;
    final double mini = inner / 3;
    final double miniOrigin = mini * (board % 3);
    final double miniOriginY = mini * (board ~/ 3);
    final double cellArea = mini - 2 * (_miniPadding + _miniInnerPadding);
    final double cellSize = cellArea / 3;
    final double offset = _miniPadding + _miniInnerPadding;
    return Offset(
      miniOrigin + offset + (cell % 3 + 0.5) * cellSize,
      miniOriginY + offset + (cell ~/ 3 + 0.5) * cellSize,
    );
  }

  Offset _miniCenter(int board) {
    final double inner = _lastSize - 2 * _outerPadding;
    final double mini = inner / 3;
    return Offset((board % 3 + 0.5) * mini, (board ~/ 3 + 0.5) * mini);
  }

  void _emitParticles(Ultimate2State before, Ultimate2State after) {
    if (_lastSize <= 0 || identical(before, after)) {
      return;
    }
    final double mini = (_lastSize - 2 * _outerPadding) / 3;
    // Peça nova: explosão pequena na célula.
    if (after.lastBoard != null &&
        after.lastCell != null &&
        before.boards[after.lastBoard!][after.lastCell!] == null &&
        after.boards[after.lastBoard!][after.lastCell!] != null) {
      final PlayerMarker marker =
          after.boards[after.lastBoard!][after.lastCell!]!;
      widget.particles.burst(
        center: _cellCenter(after.lastBoard!, after.lastCell!),
        color: marker == PlayerMarker.cross
            ? const Color(0xFF6BE0FF)
            : const Color(0xFFFF6BD9),
        accent: Colors.white,
        count: 10,
        size: mini * 0.05,
        speed: mini / 110,
      );
    }
    // Mini-tabuleiro conquistado: explosão grande, colorida pelo dono.
    for (int board = 0; board < 9; board++) {
      if (before.macro[board] == null && after.macro[board] != null) {
        final PlayerMarker owner = after.macro[board]!;
        widget.particles.burst(
          center: _miniCenter(board),
          color: owner == PlayerMarker.cross
              ? const Color(0xFF6BE0FF)
              : const Color(0xFFFF6BD9),
          accent: VerseColors.energy,
          count: 30,
          size: mini * 0.09,
          speed: mini / 55,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Ultimate2State state = widget.state;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
        color: Colors.white.withOpacity(0.03),
      ),
      padding: const EdgeInsets.all(_outerPadding),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _lastSize = constraints.biggest.shortestSide + 2 * _outerPadding;
          return Stack(
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
              Positioned.fill(
                  child: ParticleField(controller: widget.particles)),
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
          );
        },
      ),
    );
  }

  Widget _buildMini(BuildContext context, int board) {
    final Ultimate2State state = widget.state;
    final bool playable = state.isBoardPlayable(board);
    final PlayerMarker? owner = state.macro[board];
    final bool closed = state.isBoardClosed(board);
    final bool isWinningBoard =
        state.result.winningLine?.contains(board) ?? false;
    final Color ownerColor = owner == PlayerMarker.cross
        ? const Color(0xFF6BE0FF)
        : const Color(0xFFFF6BD9);

    return Padding(
      padding: const EdgeInsets.all(_miniPadding),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: playable
              ? Colors.cyanAccent.withOpacity(0.10)
              : (owner != null
                  ? ownerColor.withOpacity(0.08)
                  : Colors.white.withOpacity(0.03)),
          border: Border.all(
            color: playable
                ? Colors.cyanAccent
                : (owner != null
                    ? ownerColor.withOpacity(0.45)
                    : Colors.white.withOpacity(closed ? 0.10 : 0.22)),
            width: playable ? 1.8 : 1,
          ),
          boxShadow: playable
              ? <BoxShadow>[
                  BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.35),
                      blurRadius: 12),
                ]
              : const <BoxShadow>[],
        ),
        child: Stack(
          children: <Widget>[
            Opacity(
              opacity: owner != null ? 0.25 : (closed ? 0.45 : 1),
              child: Padding(
                padding: const EdgeInsets.all(_miniInnerPadding),
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
                      child: Pulse(
                        active: isWinningBoard,
                        maxScale: 1.12,
                        period: const Duration(milliseconds: 520),
                        child: Image.asset(
                          owner == PlayerMarker.cross
                              ? widget.visualAssets.crossAssetPath
                              : widget.visualAssets.noughtAssetPath,
                          fit: BoxFit.contain,
                        ),
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
    final Ultimate2State state = widget.state;
    final PlayerMarker? marker = state.boards[board][cell];
    final bool isLast = state.lastBoard == board && state.lastCell == cell;
    return PressScale(
      enabled: widget.interactive && state.isCellPlayable(board, cell),
      pressedScale: 0.85,
      child: GestureDetector(
        onTap: () => widget.onCellTap(board, cell),
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
                          ? widget.visualAssets.crossAssetPath
                          : widget.visualAssets.noughtAssetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

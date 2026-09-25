import 'dart:async';

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
import '../widgets/game_board.dart';
import '../widgets/game_over_modal.dart';
import '../widgets/juice/particles.dart';
import '../widgets/juice/pulse.dart';
import '../widgets/modern_background.dart';
import '../widgets/pop_in.dart';

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
  final AdService adService = AdService.instance;
  final AudioService audioService = AudioService.instance;
  final HapticsService haptics = HapticsService.instance;
  final ParticleController _screenParticles = ParticleController();
  final ParticleController _boardParticles = ParticleController();
  late final DoubleXpOffer _doubleXpOffer = DoubleXpOffer(
    rewardedAdController: rewardedAdController,
    adService: adService,
  );
  Timer? _cpuHighlightTimer;
  Timer? _cpuMoveTimer;
  Timer? _gameOverTimer;
  int? _cpuMoveHighlightIndex;
  bool _cpuThinking = false;
  int _shakeTick = 0;

  /// Recompensa da última partida, exibida dentro do modal de fim.
  ProgressionResult? _progressionResult;

  /// Pausa de "pensamento" antes da CPU responder - a jogada dela não pode
  /// aparecer no mesmo frame do toque do jogador.
  static const Duration _cpuThinkDelay = Duration(milliseconds: 550);

  /// Tempo pra linha neon desenhar + pulsar antes do modal de fim subir.
  static const Duration _winCelebration = Duration(milliseconds: 1650);
  static const Duration _drawPause = Duration(milliseconds: 650);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bannerAdController.loadBannerAd(
        context: context,
        onAdLoaded: _refreshBannerArea,
        onAdFailed: _refreshBannerArea,
      );
      audioService.ensureBackgroundMusic();
    });
    interstitialAdController.loadInterstitialAd();
    rewardedAdController.loadRewardedAd();
  }

  @override
  void dispose() {
    _cpuHighlightTimer?.cancel();
    _cpuMoveTimer?.cancel();
    _gameOverTimer?.cancel();
    bannerAdController.dispose();
    interstitialAdController.dispose();
    rewardedAdController.dispose();
    _screenParticles.dispose();
    _boardParticles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(widget.controller.modeDefinition.title(localization)),
          ),
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
                                    child: BoardShake(
                                      trigger: _shakeTick,
                                      child: GameBoard(
                                        board: widget.controller.state.board,
                                        blockedCells: widget
                                            .controller.state.blockedCells,
                                        onCellSelected: _handleCellTap,
                                        winningLine: widget.controller.state
                                            .result.winningLine,
                                        winningPlayer: widget
                                            .controller.state.result.winner,
                                        visualAssetConfig: _visualAssets,
                                        highlightIndex: _cpuMoveHighlightIndex,
                                        particles: _boardParticles,
                                        interactive: !_cpuThinking &&
                                            !widget.controller.state.result
                                                .isFinal,
                                      ),
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
                    if (AdsConfiguration.adsEnabled) ...<Widget>[
                      const SizedBox(height: 12),
                      _buildBannerArea(),
                    ],
                  ],
                ),
              ),
            ),
            // Confete por cima de tudo (inclusive do banner), sem roubar toque.
            Positioned.fill(child: ParticleField(controller: _screenParticles)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHud(AppLocalizations localization) {
    final PlayerMarker current = widget.controller.state.currentPlayer;
    final bool vsCpu = widget.controller.playAgainstCpu;
    final bool humanTurn = !widget.controller.state.result.isFinal &&
        (!vsCpu || (current == PlayerMarker.cross && !_cpuThinking));
    final String hint;
    if (_cpuThinking) {
      hint = localization.cpuThinking;
    } else if (vsCpu && humanTurn) {
      hint = localization.yourTurn;
    } else {
      hint = localization.winInstruction;
    }
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              // O avatar de quem joga "respira": a vez de jogar fica óbvia sem
              // ler o texto - importa nos idiomas em que a HUD fica longa.
              Pulse(
                active: humanTurn,
                maxScale: 1.1,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (Widget child, Animation<double> anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: KeyedSubtree(
                    key: ValueKey<PlayerMarker>(current),
                    child: _buildPlayerAvatar(current),
                  ),
                ),
              ),
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        hint,
                        key: ValueKey<String>(hint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _cpuThinking
                                  ? Colors.cyanAccent
                                  : Colors.white70,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_cpuThinking)
                const _ThinkingDots()
              else
                IconButton(
                  onPressed: () {
                    audioService.playUiClick();
                    haptics.play(HapticCue.tap);
                    _showHelpModal(localization);
                  },
                  icon: const Icon(Icons.help_outline_rounded,
                      color: Colors.white70),
                  tooltip: localization.helpTitle,
                ),
            ],
          ),
          if (widget.controller.state.movesRemaining != null ||
              widget.controller.state.activeUltimateCondition != null ||
              widget.controller.state.activeChaosEvent != null) ...<Widget>[
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
              if (widget.controller.state.activeChaosEvent != null)
                PopIn(
                  key: ObjectKey(widget.controller.state.activeChaosEvent),
                  beginScale: 1.4,
                  child: _buildHudChip(
                    Icons.bolt_rounded,
                    _chaosEventLabel(localization,
                        widget.controller.state.activeChaosEvent!),
                    tint: VerseColors.energy,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _chaosEventLabel(AppLocalizations localization, ChaosEvent event) {
    switch (event.type) {
      case ChaosEffectType.removePiece:
        return localization.chaosRemovePiece;
      case ChaosEffectType.blockCell:
        return localization.chaosBlockCell;
      case ChaosEffectType.swapSymbols:
        return localization.chaosSwapSymbols;
    }
  }

  Widget _buildHudChip(IconData icon, String label,
      {Color tint = Colors.lightBlueAccent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: tint),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white),
            ),
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
    // Partida encerrada: ignorar toques, senão a partida é re-contada nas
    // estatísticas e o modal/review/interstitial disparam de novo.
    // Durante a pausa da CPU, um toque moveria PELA CPU - bloquear também.
    if (widget.controller.state.result.isFinal || _cpuThinking) {
      return;
    }
    final List<PlayerMarker?> previousBoard =
        List<PlayerMarker?>.from(widget.controller.state.board);
    final ChaosEvent? previousEvent = widget.controller.state.activeChaosEvent;
    setState(() {
      widget.controller.selectCellHumanOnly(index);
    });
    final int newPlacements =
        _countNewPlacements(previousBoard, widget.controller.state.board);
    if (newPlacements > 0) {
      audioService.playMoveSfx(
          isNought:
              widget.controller.state.board[index] == PlayerMarker.nought);
      haptics.play(HapticCue.place);
    }
    _announceChaosEvent(previousEvent);
    if (widget.controller.state.result.isFinal) {
      _onMatchEnded();
      return;
    }
    if (widget.controller.isCpuMovePending) {
      _cpuThinking = true;
      _cpuMoveTimer?.cancel();
      _cpuMoveTimer = Timer(_cpuThinkDelay, _performDelayedCpuMove);
    }
  }

  void _performDelayedCpuMove() {
    if (!mounted) {
      return;
    }
    final List<PlayerMarker?> previousBoard =
        List<PlayerMarker?>.from(widget.controller.state.board);
    final ChaosEvent? previousEvent = widget.controller.state.activeChaosEvent;
    setState(() {
      widget.controller.performPendingCpuMove();
      _cpuThinking = false;
    });
    if (_countNewPlacements(previousBoard, widget.controller.state.board) > 0) {
      audioService.playMoveSfx(isNought: true);
    }
    _announceChaosEvent(previousEvent);
    final int? cpuMoveIndex =
        _findCpuMoveIndex(previousBoard, widget.controller.state.board);
    if (cpuMoveIndex != null) {
      _triggerCpuMoveHighlight(cpuMoveIndex);
    }
    if (widget.controller.state.result.isFinal) {
      _onMatchEnded();
    }
  }

  /// Evento novo do Caos: som de "arranhão", pulso e tremida curta.
  void _announceChaosEvent(ChaosEvent? previousEvent) {
    final ChaosEvent? event = widget.controller.state.activeChaosEvent;
    if (event == null || identical(event, previousEvent)) {
      return;
    }
    audioService.play(Sfx.chaos);
    haptics.play(HapticCue.capture);
    if (!widget.controller.state.result.isFinal) {
      setState(() {
        _shakeTick++;
      });
    }
  }

  /// Traduz o fim da partida para a progressão (XP, nível, conquistas).
  ProgressionResult _registerProgression(GameResult result) {
    final GameModeType mode = widget.controller.modeDefinition.type;
    final bool vsCpu = widget.controller.playAgainstCpu;
    return ProgressionService.instance.registerMatch(
      MatchOutcome(
        mode: mode,
        vsCpu: vsCpu,
        difficulty: widget.controller.cpuDifficulty,
        humanWon: vsCpu &&
            result.resolution == GameResolution.victory &&
            result.winner == PlayerMarker.cross,
        isDraw: result.resolution == GameResolution.draw,
        // No Clássico nenhuma peça sai do tabuleiro, então contar os X é a
        // contagem exata de jogadas do humano. Nos outros modos a contagem
        // seria ambígua, e a conquista de vitória rápida não vale lá.
        humanMoveCount: mode == GameModeType.classic
            ? widget.controller.state.board
                .where((PlayerMarker? cell) => cell == PlayerMarker.cross)
                .length
            : null,
      ),
    );
  }

  void _onMatchEnded() {
    final GameResult finalResult = widget.controller.state.result;
    final bool vsCpu = widget.controller.playAgainstCpu;
    widget.metricsService.recordMatch(widget.controller.modeDefinition.type);
    StorageService.instance.recordMatch(
      mode: widget.controller.modeDefinition.type,
      result: finalResult,
      vsCpu: vsCpu,
    );
    final ProgressionResult progression = _registerProgression(finalResult);
    _progressionResult = progression;
    _doubleXpOffer.onMatchEnded(progression);

    // Celebração antes do modal: tabuleiro travado (result.isFinal), shake de
    // impacto e a linha neon desenhando por inteiro. Review/interstitial só
    // depois, senão cobrem a animação.
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
    // Som/vibração/confete entram quando a linha termina de desenhar (ou logo
    // no empate), para a festa não atropelar o "risco" da linha.
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

  void _showGameOverSheet(MatchEndKind kind) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    final GameResult result = widget.controller.state.result;
    final bool vsCpu = widget.controller.playAgainstCpu;
    final ProgressState progress = ProgressionService.instance.state;
    final bool celebrate =
        kind == MatchEndKind.humanWin || kind == MatchEndKind.twoPlayerWin;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      // Sem isto o sheet trava em 9/16 da tela e o modal cheio (sequências,
      // nível, conquista, barra, oferta) sairia cortado; o modal limita a
      // própria altura e rola por dentro.
      isScrollControlled: true,
      builder: (BuildContext context) => GameOverModal(
        title: matchEndTitle(localization, result, vsCpu: vsCpu),
        subtitle: localization.playAgain,
        progression: _progressionResult,
        onWatchAdForDoubleXp: _doubleXpOffer.build(),
        xpAfter: ProgressionService.instance.xp,
        winStreak: vsCpu ? progress.currentWinStreak : 0,
        isNewBestStreak: vsCpu &&
            kind == MatchEndKind.humanWin &&
            progress.currentWinStreak >= 2 &&
            progress.currentWinStreak == progress.bestWinStreak,
        dailyStreak:
            ProgressionEngine.effectiveDailyStreak(progress, DateTime.now()),
        celebrate: celebrate,
        onPlayAgain: () {
          Navigator.of(context).pop();
          _cpuMoveTimer?.cancel();
          _cpuHighlightTimer?.cancel();
          _screenParticles.clear();
          setState(() {
            widget.controller.resetMatch();
            _cpuThinking = false;
            _cpuMoveHighlightIndex = null;
          });
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

  int _countNewPlacements(
      List<PlayerMarker?> previousBoard, List<PlayerMarker?> currentBoard) {
    int count = 0;
    for (int index = 0; index < currentBoard.length; index++) {
      if (previousBoard[index] == null && currentBoard[index] != null) {
        count++;
      }
    }
    return count;
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
      builder: (BuildContext context) => SafeArea(
        child: Dialog(
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
                    onPressed: () {
                      audioService.playUiClick();
                      Navigator.of(context).pop();
                    },
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

/// Três pontos pulsando em sequência enquanto a máquina "pensa". Ocupa o lugar
/// do botão de ajuda para a HUD não mudar de altura.
class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Opacity(
                      opacity: 0.35 +
                          0.65 *
                              (0.5 + 0.5 * _wave(_controller.value - i * 0.18)),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.cyanAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static double _wave(double t) {
    final double phase = (t % 1 + 1) % 1;
    return phase < 0.5 ? (phase * 4 - 1) : (3 - phase * 4);
  }
}

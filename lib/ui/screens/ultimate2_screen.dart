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
import '../../services/daily_challenge.dart';
import '../../services/double_xp_offer.dart';
import '../../services/haptics_service.dart';
import '../../services/match_feedback.dart';
import '../../services/metrics_service.dart';
import '../../services/progression_engine.dart';
import '../../services/progression_service.dart';
import '../../services/review_service.dart';
import '../../services/share_victory.dart';
import '../../services/storage_service.dart';
import '../../services/visual_assets.dart';
import '../widgets/board_shake.dart';
import '../widgets/game_over_modal.dart';
import '../widgets/juice/particles.dart';
import '../widgets/juice/pulse.dart';
import '../widgets/modern_background.dart';
import '../widgets/neon_win_line.dart';
import '../widgets/ultimate_macro_board.dart';
import '../widgets/ultimate_tutorial.dart';

class Ultimate2Screen extends StatefulWidget {
  const Ultimate2Screen({
    super.key,
    required this.playAgainstCpu,
    required this.cpuDifficulty,
    required this.metricsService,
    this.challenge,
  });

  final bool playAgainstCpu;
  final CpuDifficulty cpuDifficulty;
  final MetricsService metricsService;

  /// Desafio diário: a partida vale o prêmio se o jogador vencer a máquina
  /// em até `moveLimit` jogadas. Nulo = partida normal.
  final DailyChallenge? challenge;

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

  /// A próxima tremida é a do impacto da linha da vitória (forte).
  bool _strongShake = false;

  /// Jogadas do humano na partida (o desafio diário conta isso).
  int _humanMoves = 0;

  /// Moldura do tabuleiro que vira a imagem do "compartilhar vitória".
  final GlobalKey _boardShotKey = GlobalKey();

  /// Recompensa da última partida, exibida dentro do modal de fim.
  ProgressionResult? _progressionResult;

  static const Duration _cpuThinkDelay = Duration(milliseconds: 550);
  static const Duration _winCelebration = Duration(milliseconds: 1900);
  static const Duration _drawPause = Duration(milliseconds: 650);

  @override
  void initState() {
    super.initState();
    state = engine.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AdsConfiguration.passiveAdsEnabled) {
        bannerAdController.loadBannerAd(
          context: context,
          onAdLoaded: _refresh,
          onAdFailed: _refresh,
        );
      }
      audioService.ensureBackgroundMusic();
      _maybeShowTutorial();
    });
    if (AdsConfiguration.passiveAdsEnabled) {
      interstitialAdController.loadInterstitialAd();
    }
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

  /// Na primeira vez, o tutorial jogável: a regra de "a casa manda o outro
  /// para o tabuleiro" é a que mais faz o jogador novo desistir.
  Future<void> _maybeShowTutorial() async {
    if (StorageService.instance.ultimateTutorialDone || !mounted) {
      return;
    }
    await StorageService.instance.markUltimateTutorialDone();
    if (!mounted) {
      return;
    }
    await showUltimateTutorial(context, AppLocalizations.of(context)!);
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
      if (!widget.playAgainstCpu ||
          previous.currentPlayer == PlayerMarker.cross) {
        _humanMoves++;
      }
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
          _strongShake = false;
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
    _settleChallenge();
    _doubleXpOffer.onMatchEnded(progression);
    // Celebração antes do modal: shake + linha neon do macro-tabuleiro
    // desenhando por inteiro; review/interstitial só depois.
    final GameResult finalResult = state.result;
    final bool hasWinLine =
        finalResult.winningLine != null && finalResult.winner != null;
    final MatchEndKind kind = classifyMatchEnd(finalResult, vsCpu: vsCpu);
    if (hasWinLine) {
      setState(() {
        _strongShake = false;
        _shakeTick++;
      });
      audioService.play(Sfx.winLine);
      // Quando o risco fecha: tremida forte junto com o clarão da linha.
      Timer(NeonWinLine.impactDelay, () {
        if (mounted) {
          setState(() {
            _strongShake = true;
            _shakeTick++;
          });
        }
      });
    }
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final Duration delay = reduceMotion
        ? const Duration(milliseconds: 200)
        : (hasWinLine ? _winCelebration : _drawPause);
    Timer(
      reduceMotion || !hasWinLine
          ? Duration.zero
          : NeonWinLine.impactDelay,
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
      if (ReviewService.isGoodMoment(
        humanWonVsCpu: vsCpu && finalResult.winner == PlayerMarker.cross,
        newAchievements: _progressionResult?.newlyUnlocked.length ?? 0,
      )) {
        ReviewService.instance.maybeRequestReview();
      }
      bool interstitialShown = false;
      if (!AdsConfiguration.passiveAdsEnabled) {
        // Comprou "sem anúncios": nem conta a cadência.
      } else if (adService.shouldShowInterstitialOnMatchEnd()) {
        interstitialShown =
            interstitialAdController.showInterstitialAdIfAvailable();
      } else {
        interstitialAdController.loadInterstitialAd();
      }
      _doubleXpOffer.onCelebrationDone(interstitialShown: interstitialShown);
      _showGameOverSheet(kind);
    });
  }

  /// Texto da faixa do desafio no modal de fim (nulo fora do desafio).
  String? _challengeBanner;
  bool _challengeBannerSuccess = true;

  void _settleChallenge() {
    final DailyChallenge? challenge = widget.challenge;
    _challengeBanner = null;
    if (challenge == null || !mounted) {
      return;
    }
    final AppLocalizations l = AppLocalizations.of(context)!;
    const DailyChallengeEngine rules = DailyChallengeEngine();
    final ProgressState progress = StorageService.instance.progress;
    final DateTime now = DateTime.now();
    final bool won = state.result.resolution == GameResolution.victory &&
        state.result.winner == PlayerMarker.cross;
    final bool alreadyDone = !rules.canComplete(progress, now);
    final int reward = rules.complete(progress, now,
        won: won, humanMoves: _humanMoves, challenge: challenge);
    if (reward > 0) {
      StorageService.instance.saveProgress();
      ProgressionService.instance.revision.value += 1;
      _challengeBanner = l.challengeWon(reward);
      _challengeBannerSuccess = true;
      // Conquista do dia: som de conquista e faíscas, um pouco depois do
      // confete da vitória para os dois não brigarem.
      Timer(const Duration(milliseconds: 1400), () {
        if (mounted) {
          audioService.play(Sfx.achievement);
          haptics.play(HapticCue.capture);
          _screenParticles.burst(
            center: _screenParticles.viewport.center(Offset.zero),
            color: VerseColors.coin,
            accent: Colors.white,
            count: 40,
            speed: 2,
            size: 6,
          );
        }
      });
    } else if (alreadyDone && won) {
      _challengeBanner = l.challengeAlreadyDone;
      _challengeBannerSuccess = true;
    } else if (won) {
      _challengeBanner = l.challengeLate(challenge.moveLimit);
      _challengeBannerSuccess = false;
    }
  }

  Future<void> _shareVictory() {
    final AppLocalizations l = AppLocalizations.of(context)!;
    return ShareVictory.share(_boardShotKey, message: l.shareMessage);
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
        banner: _challengeBanner,
        bannerSuccess: _challengeBannerSuccess,
        onShare:
            kind == MatchEndKind.humanWin || kind == MatchEndKind.twoPlayerWin
                ? _shareVictory
                : null,
        onPlayAgain: () {
          Navigator.of(context).pop();
          _cpuMoveTimer?.cancel();
          _screenParticles.clear();
          setState(() {
            state = engine.start();
            _cpuThinking = false;
            _humanMoves = 0;
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
          // Bengali/hindi não cabem inteiros ao lado de dois ícones em 360px:
          // encolhe em vez de cortar com reticências.
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(localization.modeUltimate2Title),
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
                    if (widget.challenge != null) ...<Widget>[
                      const SizedBox(height: 8),
                      _buildChallengeBar(localization, widget.challenge!),
                    ],
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
                                amplitude: _strongShake ? 18 : 7,
                                // Vira a foto do "compartilhar vitória" (o
                                // fundo é pintado só na imagem).
                                child: RepaintBoundary(
                                  key: _boardShotKey,
                                  child: UltimateMacroBoard(
                                    state: state,
                                    visualAssets: visualAssets,
                                    onCellTap: _handleTap,
                                    particles: _boardParticles,
                                    interactive:
                                        !_cpuThinking && !state.result.isFinal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (AdsConfiguration.passiveAdsEnabled) ...<Widget>[
                      const SizedBox(height: 10),
                      GlassPanel(
                        padding: EdgeInsets.zero,
                        child: SafeArea(
                          top: false,
                          child: SizedBox(
                            width: double.infinity,
                            height: bannerAdController.expectedAdHeightFor(
                                MediaQuery.of(context).size),
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

  Widget _buildChallengeBar(
      AppLocalizations localization, DailyChallenge challenge) {
    final bool over = _humanMoves > challenge.moveLimit;
    final Color tint = over ? VerseColors.danger : VerseColors.coin;
    return GlassPanel(
      key: const ValueKey<String>('challenge-bar'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(Icons.emoji_events_rounded, color: tint, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              over
                  ? localization.challengeOverLimit(challenge.moveLimit)
                  : localization.challengeTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: tint, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            localization.challengeMoves(_humanMoves, challenge.moveLimit),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: tint, fontWeight: FontWeight.w800),
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey<String>('help-tutorial'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showUltimateTutorial(this.context, localization);
                  },
                  icon: const Icon(Icons.school_rounded),
                  label: Text(localization.tutorialReplay),
                ),
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

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
import '../../services/ad_service.dart';
import '../../services/ads_configuration.dart';
import '../../services/audio_service.dart';
import '../../services/metrics_service.dart';
import '../../services/progression_engine.dart';
import '../../services/progression_service.dart';
import '../../services/review_service.dart';
import '../../services/storage_service.dart';
import '../../services/visual_assets.dart';
import '../widgets/board_shake.dart';
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
  final AdService adService = AdService.instance;
  final AudioService audioService = AudioService.instance;
  Timer? _cpuHighlightTimer;
  Timer? _cpuMoveTimer;
  Timer? _gameOverTimer;
  int? _cpuMoveHighlightIndex;
  bool _cpuThinking = false;
  int _shakeTick = 0;

  /// Recompensa da última partida, exibida dentro do modal de fim.
  ProgressionResult? _progressionResult;

  /// O intersticial foi realmente exibido no fim desta partida. Quando foi, a
  /// oferta de anúncio premiado é suprimida: encadear "anúncio, agora quer ver
  /// outro?" queima o jogador e é o tipo de padrão que chama atenção da
  /// política do AdMob. Vale um convite a menos.
  bool _interstitialShownThisMatch = false;

  /// O convite de dobrar o XP caiu no intervalo desta partida. Contado uma vez
  /// em `_onMatchEnded`, nunca dentro do `builder` do modal - o `builder` pode
  /// rodar de novo num rebuild e adiantaria o intervalo.
  bool _rewardedOfferDueThisMatch = false;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.controller.modeDefinition.title(localization)),
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
                                child: BoardShake(
                                  trigger: _shakeTick,
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
                onPressed: () {
                  audioService.playUiClick();
                  _showHelpModal(localization);
                },
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
              if (widget.controller.state.activeChaosEvent != null)
                _buildHudChip(
                  Icons.bolt_rounded,
                  _chaosEventLabel(
                      localization, widget.controller.state.activeChaosEvent!),
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
    // Partida encerrada: ignorar toques, senão a partida é re-contada nas
    // estatísticas e o modal/review/interstitial disparam de novo.
    // Durante a pausa da CPU, um toque moveria PELA CPU - bloquear também.
    if (widget.controller.state.result.isFinal || _cpuThinking) {
      return;
    }
    final List<PlayerMarker?> previousBoard =
        List<PlayerMarker?>.from(widget.controller.state.board);
    setState(() {
      widget.controller.selectCellHumanOnly(index);
    });
    final int newPlacements =
        _countNewPlacements(previousBoard, widget.controller.state.board);
    if (newPlacements > 0) {
      audioService.playMoveSfx();
    }
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
    setState(() {
      widget.controller.performPendingCpuMove();
      _cpuThinking = false;
    });
    if (_countNewPlacements(previousBoard, widget.controller.state.board) > 0) {
      audioService.playMoveSfx();
    }
    final int? cpuMoveIndex =
        _findCpuMoveIndex(previousBoard, widget.controller.state.board);
    if (cpuMoveIndex != null) {
      _triggerCpuMoveHighlight(cpuMoveIndex);
    }
    if (widget.controller.state.result.isFinal) {
      _onMatchEnded();
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
    widget.metricsService.recordMatch(widget.controller.modeDefinition.type);
    StorageService.instance.recordMatch(
      mode: widget.controller.modeDefinition.type,
      result: finalResult,
      vsCpu: widget.controller.playAgainstCpu,
    );
    _progressionResult = _registerProgression(finalResult);
    _interstitialShownThisMatch = false;
    _rewardedOfferDueThisMatch = false;
    rewardedAdController.loadRewardedAd();

    // Celebração antes do modal: tabuleiro travado (result.isFinal), shake de
    // impacto e a linha neon desenhando por inteiro. Review/interstitial só
    // depois, senão cobrem a animação.
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
      if (widget.controller.playAgainstCpu &&
          finalResult.winner == PlayerMarker.cross) {
        ReviewService.instance.maybeRequestReview();
      }
      if (adService.shouldShowInterstitialOnMatchEnd()) {
        _interstitialShownThisMatch =
            interstitialAdController.showInterstitialAdIfAvailable();
      } else {
        interstitialAdController.loadInterstitialAd();
      }
      _rewardedOfferDueThisMatch = adService.shouldOfferRewardedOnMatchEnd();
      _showGameOverSheet();
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

  /// A oferta de dobrar o XP, ou `null` quando não há o que oferecer.
  ///
  /// Só convida com anúncio JÁ carregado: prometer o bônus e depois não ter o
  /// que exibir é pior do que ficar calado.
  Future<ProgressionResult?> Function()? _doubleXpOffer() {
    if (!AdsConfiguration.adsEnabled) {
      return null;
    }
    if (_interstitialShownThisMatch) {
      return null;
    }
    if (!_rewardedOfferDueThisMatch) {
      return null;
    }
    if (!rewardedAdController.isReady) {
      return null;
    }
    final ProgressionResult? earned = _progressionResult;
    if (earned == null || earned.xpGained <= 0) {
      return null;
    }
    return _watchAdForDoubleXp;
  }

  /// Exibe o anúncio premiado e credita o bônus, devolvendo o que mudou.
  ///
  /// O valor do bônus é fixado ANTES de abrir o anúncio (o XP da partida que
  /// acabou), então dobrar é sempre dobrar aquele número - e o crédito só
  /// acontece se o SDK confirmar que o jogador assistiu até o fim.
  Future<ProgressionResult?> _watchAdForDoubleXp() async {
    final ProgressionResult? earned = _progressionResult;
    if (earned == null || earned.xpGained <= 0) {
      return null;
    }
    final int bonusXp = earned.xpGained;
    final bool rewarded = await rewardedAdController.showForReward();
    if (!rewarded) {
      return null;
    }
    return ProgressionService.instance.grantBonusXp(bonusXp);
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
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => GameOverModal(
        title: title,
        subtitle: subtitle,
        progression: _progressionResult,
        onWatchAdForDoubleXp: _doubleXpOffer(),
        onPlayAgain: () {
          Navigator.of(context).pop();
          _cpuMoveTimer?.cancel();
          _cpuHighlightTimer?.cancel();
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

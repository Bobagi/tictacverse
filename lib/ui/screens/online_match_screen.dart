import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../controllers/banner_ad_controller.dart';
import '../../controllers/interstitial_ad_controller.dart';
import '../../controllers/modes/ultimate2_engine.dart';
import '../../models/game_mode.dart';
import '../../models/game_result.dart';
import '../../models/online_match.dart';
import '../../models/player_marker.dart';
import '../../services/ad_service.dart';
import '../../services/ads_configuration.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../services/match_feedback.dart';
import '../../services/metrics_service.dart';
import '../../services/online/online_api.dart';
import '../../services/online/online_avatar.dart';
import '../../services/online/online_service.dart';
import '../../services/progression_engine.dart';
import '../../services/progression_service.dart';
import '../../services/share_victory.dart';
import '../../services/visual_assets.dart';
import '../widgets/board_shake.dart';
import '../widgets/game_over_modal.dart';
import '../widgets/juice/motion.dart';
import '../widgets/juice/particles.dart';
import '../widgets/juice/pulse.dart';
import '../widgets/modern_background.dart';
import '../widgets/neon_win_line.dart';
import '../widgets/piece_glyph.dart';
import '../widgets/ultimate_macro_board.dart';
import '../widgets/ultimate_tutorial.dart';

/// Mensagem de erro do online já traduzida.
String onlineErrorText(AppLocalizations l, Object error) {
  if (error is OnlineApiException) {
    switch (error.code) {
      case 'taken':
        return l.onlineTaken;
      case 'expired':
        return l.onlineExpired;
      case 'not_found':
        return l.onlineNotFound;
      case 'own_match':
        return l.onlineOwnMatch;
      case 'too_many_open':
      case 'too_many_today':
        return l.onlineTooMany;
    }
  }
  return l.onlineError;
}

/// Partida online do Super Jogo da Velha contra um amigo. O servidor é o juiz:
/// a jogada aparece na hora (otimista) e é confirmada por ele; a do amigo
/// chega por long poll, então os dois veem tudo em tempo real quando estão
/// com o jogo aberto, e quem volta depois encontra a partida onde parou.
class OnlineMatchScreen extends StatefulWidget {
  const OnlineMatchScreen({
    super.key,
    required this.initial,
    required this.metricsService,
  });

  final OnlineMatch initial;
  final MetricsService metricsService;

  @override
  State<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends State<OnlineMatchScreen>
    with WidgetsBindingObserver {
  final OnlineService online = OnlineService.instance;
  final Ultimate2Engine engine = Ultimate2Engine();
  final VisualAssetConfig visualAssets = VisualAssetConfig();
  final AudioService audioService = AudioService.instance;
  final HapticsService haptics = HapticsService.instance;
  final AdService adService = AdService.instance;
  final BannerAdController bannerAdController = BannerAdController();
  final InterstitialAdController interstitialAdController =
      InterstitialAdController();
  final ParticleController _screenParticles = ParticleController();
  final ParticleController _boardParticles = ParticleController();
  final GlobalKey _boardShotKey = GlobalKey();

  late OnlineMatch match = widget.initial;
  late Ultimate2State board = match.toState();

  /// Jogada mostrada antes de o servidor confirmar.
  bool _sending = false;
  bool _offline = false;
  bool _polling = false;
  bool _paused = false;
  bool _disposed = false;
  bool _endHandled = false;
  int _shakeTick = 0;
  bool _strongShake = false;
  Timer? _endTimer;

  static const Duration _winCelebration = Duration(milliseconds: 1900);
  static const Duration _retryDelay = Duration(seconds: 3);
  static const Duration _quickReply = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AdsConfiguration.passiveAdsEnabled) {
        bannerAdController.loadBannerAd(
          context: context,
          onAdLoaded: _refresh,
          onAdFailed: _refresh,
        );
      }
      audioService.ensureBackgroundMusic();
      // Partida que já chegou terminada (voltou depois): mostra o fim sem a
      // festa da linha, que já passou.
      if (match.status == OnlineStatus.finished) {
        _onFinished(live: false);
      }
    });
    if (AdsConfiguration.passiveAdsEnabled) {
      interstitialAdController.loadInterstitialAd();
    }
    _pollLoop();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _endTimer?.cancel();
    bannerAdController.dispose();
    interstitialAdController.dispose();
    _screenParticles.dispose();
    _boardParticles.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Em segundo plano não segura conexão aberta; ao voltar, retoma.
    _paused = state != AppLifecycleState.resumed;
    if (!_paused) {
      _pollLoop();
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Fica perguntando "mudou algo?" enquanto a tela está aberta. Termina
  /// quando a partida não tem mais o que mudar (expirada, ou terminada com a
  /// revanche já criada).
  Future<void> _pollLoop() async {
    if (_polling) {
      return;
    }
    _polling = true;
    try {
      while (!_disposed && !_paused && !_settled) {
        try {
          final int since = match.version;
          final Stopwatch waited = Stopwatch()..start();
          final OnlineMatch next = await online.fetch(match.id, since: since);
          if (_disposed) {
            return;
          }
          if (_offline) {
            setState(() => _offline = false);
          }
          _apply(next);
          // O servidor respondeu na hora sem novidade (cheio, ou teto de
          // esperas): espera um pouco em vez de martelar em loop.
          if (next.version <= since && waited.elapsed < _quickReply) {
            await Future<void>.delayed(_retryDelay);
          }
        } on OnlineApiException catch (e) {
          if (_disposed) {
            return;
          }
          if (e.status == 404) {
            return;
          }
          if (!_offline) {
            setState(() => _offline = true);
          }
          await Future<void>.delayed(_retryDelay);
        }
      }
    } finally {
      _polling = false;
    }
  }

  bool get _settled =>
      match.status == OnlineStatus.expired ||
      (match.status == OnlineStatus.finished && match.rematchId != null);

  /// Estado novo do servidor: toca o som da jogada do amigo, anuncia captura,
  /// e trata o fim. Ignora respostas velhas.
  void _apply(OnlineMatch next) {
    if (next.version < match.version) {
      return;
    }
    final Ultimate2State before = board;
    final OnlineMatch previous = match;
    final Ultimate2State after = next.toState();
    setState(() {
      match = next;
      board = after;
    });
    if (next.moves.length > previous.moves.length && !_sending) {
      final (int, int) last = next.moves.last;
      final bool opponentMoved = (next.moves.length.isOdd
              ? PlayerMarker.cross
              : PlayerMarker.nought) !=
          next.you;
      if (opponentMoved) {
        audioService.playMoveSfx(isNought: next.moves.length.isEven);
        haptics.play(HapticCue.place);
      }
      _announceCapture(before, after, last.$1);
    }
    if (previous.status == OnlineStatus.waiting &&
        next.status == OnlineStatus.active) {
      // O amigo entrou: aviso sonoro e de toque, a partida começou.
      audioService.play(Sfx.achievement);
      haptics.play(HapticCue.capture);
    }
    if (next.status == OnlineStatus.finished && !_endHandled) {
      _onFinished(live: true);
    }
  }

  void _announceCapture(Ultimate2State before, Ultimate2State after, int b) {
    if (before.macro[b] == null && after.macro[b] != null) {
      audioService.play(Sfx.capture);
      haptics.play(HapticCue.capture);
      if (!after.result.isFinal) {
        setState(() {
          _strongShake = false;
          _shakeTick++;
        });
      }
    }
  }

  Future<void> _handleTap(int b, int c) async {
    if (_sending || !match.isMyTurn || !board.isCellPlayable(b, c)) {
      return;
    }
    final Ultimate2State before = board;
    final OnlineMatch sentFrom = match;
    // Otimista: a peça aparece já, o servidor confirma em seguida.
    setState(() {
      _sending = true;
      board = engine.handleMove(board, b, c);
    });
    audioService.playMoveSfx(isNought: match.you == PlayerMarker.nought);
    haptics.play(HapticCue.place);
    _announceCapture(before, board, b);
    try {
      final OnlineMatch confirmed =
          await online.move(sentFrom.id, b, c, sentFrom.version);
      if (_disposed) {
        return;
      }
      _sending = false;
      _apply(confirmed);
    } on OnlineApiException catch (e) {
      if (_disposed) {
        return;
      }
      _sending = false;
      if (e.match != null) {
        // O servidor sabe mais (versão velha, partida acabou): segue ele.
        setState(() {
          match = e.match!;
          board = match.toState();
        });
        if (match.status == OnlineStatus.finished && !_endHandled) {
          _onFinished(live: true);
        }
      } else {
        setState(() => board = sentFrom.toState());
        _toast(onlineErrorText(AppLocalizations.of(context)!, e));
      }
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  MatchEndKind get _kind {
    switch (match.outcome) {
      case OnlineOutcome.win:
        return MatchEndKind.humanWin;
      case OnlineOutcome.loss:
        return MatchEndKind.cpuWin;
      case OnlineOutcome.draw:
      case null:
        return MatchEndKind.draw;
    }
  }

  /// Fim da partida: credita (uma vez), festeja se viu ao vivo e abre o modal.
  Future<void> _onFinished({required bool live}) async {
    if (_endHandled) {
      return;
    }
    _endHandled = true;
    widget.metricsService.recordMatch(GameModeType.ultimate2);
    final ProgressionResult? reward = await online.settleReward(match);
    if (!mounted) {
      return;
    }
    final GameResult result = match.gameResult;
    final bool hasWinLine = result.winningLine != null && live;
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    if (hasWinLine) {
      setState(() {
        _strongShake = false;
        _shakeTick++;
      });
      audioService.play(Sfx.winLine);
      Timer(NeonWinLine.impactDelay, () {
        if (mounted) {
          setState(() {
            _strongShake = true;
            _shakeTick++;
          });
        }
      });
    }
    Timer(hasWinLine && !reduceMotion ? NeonWinLine.impactDelay : Duration.zero,
        () {
      if (mounted) {
        playMatchEndFeedback(_kind, screenParticles: _screenParticles);
      }
    });
    _endTimer?.cancel();
    _endTimer = Timer(
      reduceMotion || !hasWinLine
          ? const Duration(milliseconds: 500)
          : _winCelebration,
      () {
        if (!mounted) {
          return;
        }
        if (live && AdsConfiguration.passiveAdsEnabled) {
          if (adService.shouldShowInterstitialOnMatchEnd()) {
            interstitialAdController.showInterstitialAdIfAvailable();
          } else {
            interstitialAdController.loadInterstitialAd();
          }
        }
        _showGameOver(reward);
      },
    );
  }

  /// Linha de baixo do título: por que acabou (desistência, prazo) ou contra
  /// quem foi.
  String _endDetail(AppLocalizations l) {
    final bool won = match.outcome == OnlineOutcome.win;
    switch (match.endReason) {
      case 'resign':
        return won ? l.onlineEndResignWin : l.onlineEndResignLoss;
      case 'timeout':
        return won ? l.onlineEndTimeoutWin : l.onlineEndTimeoutLoss;
      case 'abandon':
        return l.onlineEndAbandon;
      default:
        return '${l.onlineVsShort} ${opponentHandle(match.opponent)}';
    }
  }

  String _title(AppLocalizations l) {
    switch (match.outcome) {
      case OnlineOutcome.win:
        return l.onlineWinTitle;
      case OnlineOutcome.loss:
        return l.onlineLossTitle;
      case OnlineOutcome.draw:
      case null:
        return l.onlineDrawTitle;
    }
  }

  void _showGameOver(ProgressionResult? reward) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool won = match.outcome == OnlineOutcome.win;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => GameOverModal(
        progression: reward,
        title: _title(l),
        subtitle: _endDetail(l),
        // A faixa conta por que acabou (desistência, prazo) ou contra quem.
        banner: _endDetail(l),
        bannerSuccess: won || match.outcome == OnlineOutcome.draw,
        xpAfter: ProgressionService.instance.xp,
        celebrate: won,
        onShare: won
            ? () => ShareVictory.share(_boardShotKey, message: l.shareMessage)
            : null,
        playAgainLabel: l.onlineRematch,
        backLabel: l.onlineBackToLobby,
        onPlayAgain: () {
          Navigator.of(sheetContext).pop();
          _rematch();
        },
        onBackToMenu: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).pop();
        },
        winner: match.gameResult.winner,
        visualAssets: visualAssets,
      ),
    );
  }

  Future<void> _rematch() async {
    try {
      final OnlineMatch next = await online.rematch(match.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (BuildContext context) => OnlineMatchScreen(
          initial: next,
          metricsService: widget.metricsService,
        ),
      ));
    } on OnlineApiException catch (e) {
      if (mounted) {
        _toast(onlineErrorText(AppLocalizations.of(context)!, e));
      }
    }
  }

  Future<void> _shareInvite() async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    audioService.playUiClick();
    haptics.play(HapticCue.tap);
    try {
      await SharePlus.instance.share(ShareParams(
        text:
            l.onlineShareMessage(OnlineService.linkFor(match.code), match.code),
      ));
    } catch (_) {
      // Sem app para compartilhar: o código continua na tela.
    }
  }

  Future<void> _confirmResign() async {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool waiting = match.status == OnlineStatus.waiting;
    final bool? ok = waiting
        ? true
        : await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              backgroundColor: VerseColors.surface,
              content: Text(l.onlineResignConfirm),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l.cancelLabel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: VerseColors.danger),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l.onlineResign),
                ),
              ],
            ),
          );
    if (ok != true || !mounted) {
      return;
    }
    try {
      final OnlineMatch next = await online.resign(match.id);
      if (!mounted) {
        return;
      }
      if (waiting) {
        Navigator.of(context).pop();
        return;
      }
      _apply(next);
    } on OnlineApiException catch (e) {
      if (mounted) {
        _toast(onlineErrorText(l, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final bool waiting = match.status == OnlineStatus.waiting;
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(l.modeUltimate2Title),
          ),
          actions: <Widget>[
            if (waiting)
              IconButton(
                key: const ValueKey<String>('online-share-app-bar'),
                icon: const Icon(Icons.share_rounded),
                tooltip: l.onlineShareInvite,
                onPressed: _shareInvite,
              ),
            if (match.isOpen && !waiting)
              IconButton(
                key: const ValueKey<String>('online-resign'),
                icon: const Icon(Icons.flag_rounded),
                tooltip: l.onlineResign,
                onPressed: _confirmResign,
              ),
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: l.helpTitle,
              onPressed: () {
                audioService.playUiClick();
                showUltimateTutorial(context, l);
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
                    _buildHud(l),
                    if (_offline) ...<Widget>[
                      const SizedBox(height: 8),
                      _Notice(
                        key: const ValueKey<String>('online-offline'),
                        icon: Icons.wifi_off_rounded,
                        text: l.onlineReconnecting,
                        color: VerseColors.danger,
                      ),
                    ],
                    if (match.status == OnlineStatus.finished &&
                        match.rematchId != null &&
                        _endHandled) ...<Widget>[
                      const SizedBox(height: 8),
                      _buildRematchOffer(l),
                    ],
                    const SizedBox(height: 10),
                    Expanded(
                      child: waiting
                          ? _buildWaiting(l)
                          : LayoutBuilder(
                              builder: (BuildContext context,
                                  BoxConstraints constraints) {
                                final double size =
                                    constraints.biggest.shortestSide;
                                return Center(
                                  child: SizedBox(
                                    width: size,
                                    height: size,
                                    child: BoardShake(
                                      trigger: _shakeTick,
                                      amplitude: _strongShake ? 18 : 7,
                                      child: RepaintBoundary(
                                        key: _boardShotKey,
                                        child: UltimateMacroBoard(
                                          state: board,
                                          visualAssets: visualAssets,
                                          onCellTap: _handleTap,
                                          particles: _boardParticles,
                                          interactive:
                                              match.isMyTurn && !_sending,
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

  Widget _buildHud(AppLocalizations l) {
    final TextTheme text = Theme.of(context).textTheme;
    final String status;
    final Color tint;
    switch (match.status) {
      case OnlineStatus.waiting:
        status = l.onlineStatusWaiting;
        tint = VerseColors.mutedText;
      case OnlineStatus.active:
        status =
            match.isMyTurn ? l.onlineStatusYourTurn : l.onlineStatusTheirTurn;
        tint = match.isMyTurn ? VerseColors.coin : Colors.cyanAccent;
      case OnlineStatus.finished:
        status = switch (match.outcome) {
          OnlineOutcome.win => l.onlineStatusWon,
          OnlineOutcome.loss => l.onlineStatusLost,
          _ => l.onlineStatusDraw,
        };
        tint = match.outcome == OnlineOutcome.win
            ? VerseColors.coin
            : VerseColors.mutedText;
      case OnlineStatus.expired:
        status = l.onlineStatusExpired;
        tint = VerseColors.mutedText;
    }
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 26,
            height: 26,
            child: PieceGlyph(marker: match.you),
          ),
          const SizedBox(width: 8),
          Text(l.onlineVsShort, style: text.bodySmall),
          const SizedBox(width: 8),
          Breathe(
            child: Text(
              opponentHandle(match.opponent),
              key: const ValueKey<String>('online-opponent'),
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Pulse(
                key: ValueKey<String>(status),
                active: match.isMyTurn,
                maxScale: 1.08,
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: text.titleSmall
                      ?.copyWith(color: tint, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRematchOffer(AppLocalizations l) {
    return GlassPanel(
      key: const ValueKey<String>('online-rematch-offer'),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: <Widget>[
          const Wobble(
            child: Icon(Icons.replay_rounded, color: VerseColors.coin),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.onlineRematchOffered,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: VerseColors.coin,
              foregroundColor: VerseColors.bgTop,
            ),
            onPressed: _rematch,
            child: Text(l.onlineRematch),
          ),
        ],
      ),
    );
  }

  /// Convite criado, amigo ainda não entrou: código grande e o botão de
  /// mandar o link, que é o que o jogador precisa fazer agora.
  Widget _buildWaiting(AppLocalizations l) {
    final TextTheme text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
        child: Column(
          children: <Widget>[
            const SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Sunburst(size: 72, color: VerseColors.coin),
                  Breathe(
                    amount: 0.12,
                    child: Icon(Icons.mark_email_unread_rounded,
                        color: VerseColors.coin, size: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Semantics(
              label: l.onlineCodeLabel(match.code),
              child: GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: match.code));
                  haptics.play(HapticCue.tap);
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    match.code,
                    key: const ValueKey<String>('online-code'),
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      color: VerseColors.coin,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // A ação da tela vem antes da explicação: em 320x568 com banner
            // ela precisa caber sem rolar.
            Shine(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey<String>('online-share'),
                  style: FilledButton.styleFrom(
                    backgroundColor: VerseColors.coin,
                    foregroundColor: VerseColors.bgTop,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  onPressed: _shareInvite,
                  icon: const Icon(Icons.share_rounded),
                  label: Text(l.onlineShareInvite),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.onlineWaitingBody,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              l.onlineTurnRule,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: VerseColors.mutedText),
            ),
            TextButton(
              key: const ValueKey<String>('online-cancel-invite'),
              onPressed: _confirmResign,
              child: Text(l.onlineCancelInvite),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

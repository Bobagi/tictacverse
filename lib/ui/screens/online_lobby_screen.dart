import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../models/online_match.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../services/metrics_service.dart';
import '../../services/online/online_api.dart';
import '../../services/online/online_avatar.dart';
import '../../services/online/online_service.dart';
import '../widgets/juice/motion.dart';
import '../widgets/juice/press_scale.dart';
import '../widgets/juice/pulse.dart';
import '../widgets/modern_background.dart';
import 'online_match_screen.dart';

/// Porta do online: criar convite, entrar com código e as partidas abertas.
/// Com [joinCode] (veio de um link), entra na partida assim que abre.
class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({
    super.key,
    required this.metricsService,
    this.joinCode,
  });

  final MetricsService metricsService;
  final String? joinCode;

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final OnlineService online = OnlineService.instance;
  final TextEditingController _codeController = TextEditingController();
  List<OnlineMatch>? _matches;
  bool _loadFailed = false;
  bool _busy = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.joinCode != null) {
        _join(widget.joinCode!);
      }
    });
    _load();
    // Lista viva enquanto a tela está aberta ("sua vez" aparece sozinho).
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      final List<OnlineMatch> list = await online.myMatches();
      unawaited(online.refreshProfile().then((_) {}, onError: (_) {}));
      if (mounted) {
        setState(() {
          _matches = list;
          _loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted && !quiet) {
        setState(() => _loadFailed = true);
      }
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _open(OnlineMatch match) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (BuildContext context) => OnlineMatchScreen(
        initial: match,
        metricsService: widget.metricsService,
      ),
    ));
    if (mounted) {
      _load(quiet: true);
    }
  }

  Future<void> _run(Future<OnlineMatch> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final OnlineMatch match = await action();
      if (mounted) {
        setState(() => _busy = false);
        await _open(match);
      }
    } on OnlineApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _toast(onlineErrorText(AppLocalizations.of(context)!, e));
      }
    }
  }

  void _create() {
    AudioService.instance.playUiClick();
    HapticsService.instance.play(HapticCue.tap);
    _run(online.create);
  }

  void _join(String raw) {
    final String? code = OnlineService.normalizeCode(raw);
    if (code == null) {
      _toast(AppLocalizations.of(context)!.onlineCodeInvalid);
      return;
    }
    AudioService.instance.playUiClick();
    HapticsService.instance.play(HapticCue.tap);
    FocusScope.of(context).unfocus();
    _run(() => online.join(code));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
    final TextTheme text = Theme.of(context).textTheme;
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(l.onlineTitle),
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _buildHero(l, text),
                const SizedBox(height: 14),
                _buildCreate(l),
                const SizedBox(height: 14),
                _buildJoin(l, text),
                const SizedBox(height: 22),
                Text(l.onlineYourMatches,
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ..._buildMatches(l, text),
                const SizedBox(height: 18),
                Text(
                  l.onlinePrivacyNote,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: VerseColors.mutedText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(AppLocalizations l, TextTheme text) {
    return GlassPanel(
      child: Row(
        children: <Widget>[
          const Breathe(
            amount: 0.1,
            child:
                Icon(Icons.public_rounded, color: VerseColors.coin, size: 44),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ValueListenableBuilder<OnlineProfile?>(
              valueListenable: online.profile,
              builder: (BuildContext context, OnlineProfile? me, Widget? _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l.onlineIntro,
                        style: text.bodyMedium?.copyWith(height: 1.35)),
                    if (me != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        '${l.onlineYouAre(onlineHandle(me.avatar, me.tag))} · '
                        '${l.onlineStats(me.wins, me.losses, me.draws)}',
                        key: const ValueKey<String>('online-profile'),
                        style: text.bodySmall?.copyWith(
                            color: VerseColors.coin,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreate(AppLocalizations l) {
    return Shine(
      borderRadius: BorderRadius.circular(20),
      child: PressScale(
        pressedScale: 0.96,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey<String>('online-create'),
            style: FilledButton.styleFrom(
              backgroundColor: VerseColors.coin,
              foregroundColor: VerseColors.bgTop,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              textStyle: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 19,
                  fontWeight: FontWeight.w700),
            ),
            onPressed: _busy ? null : _create,
            icon: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Breathe(child: Icon(Icons.add_link_rounded)),
            label: Text(l.onlineCreate),
          ),
        ),
      ),
    );
  }

  Widget _buildJoin(AppLocalizations l, TextTheme text) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l.onlineJoinTitle,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('online-code-field'),
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: 7,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 -]')),
                  ],
                  style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 20,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: l.onlineCodeHint,
                    hintStyle: const TextStyle(
                        fontSize: 14, letterSpacing: 0, color: Colors.white38),
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _join,
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonal(
                key: const ValueKey<String>('online-join'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: _busy ? null : () => _join(_codeController.text),
                child: Text(l.onlineJoin),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMatches(AppLocalizations l, TextTheme text) {
    final List<OnlineMatch>? matches = _matches;
    if (matches == null) {
      if (_loadFailed) {
        return <Widget>[
          GlassPanel(
            child: Column(
              children: <Widget>[
                Text(l.onlineError, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l.retryLabel),
                ),
              ],
            ),
          ),
        ];
      }
      return const <Widget>[
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final List<OnlineMatch> visible = matches
        .where((OnlineMatch m) => m.status != OnlineStatus.expired)
        .toList();
    if (visible.isEmpty) {
      return <Widget>[
        GlassPanel(
          child: Text(l.onlineNoMatches,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: VerseColors.mutedText)),
        ),
      ];
    }
    // Sua vez primeiro: é o que o jogador veio fazer.
    visible.sort((OnlineMatch a, OnlineMatch b) {
      final int byTurn = (b.isMyTurn ? 1 : 0) - (a.isMyTurn ? 1 : 0);
      if (byTurn != 0) {
        return byTurn;
      }
      final int byOpen = (b.isOpen ? 1 : 0) - (a.isOpen ? 1 : 0);
      return byOpen != 0 ? byOpen : b.updatedAt.compareTo(a.updatedAt);
    });
    return <Widget>[
      for (int i = 0; i < visible.length; i++) ...<Widget>[
        _MatchTile(
          match: visible[i],
          breathPhase: (i * 0.21) % 1,
          onTap: () {
            AudioService.instance.playUiClick();
            HapticsService.instance.play(HapticCue.tap);
            _open(visible[i]);
          },
        ),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.match,
    required this.onTap,
    this.breathPhase = 0,
  });

  final OnlineMatch match;
  final VoidCallback onTap;
  final double breathPhase;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context)!;
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
    final bool hot = match.isMyTurn;
    return Semantics(
      button: true,
      label: '${opponentHandle(match.opponent)}. $status',
      child: PressScale(
        pressedScale: 0.97,
        child: GestureDetector(
          onTap: onTap,
          child: Pulse(
            active: hot,
            maxScale: 1.02,
            period: const Duration(milliseconds: 1400),
            child: Container(
              key: ValueKey<String>('online-match-${match.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: hot ? 0.09 : 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: tint.withValues(alpha: hot ? 0.85 : 0.35),
                  width: hot ? 1.6 : 1.2,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Breathe(
                    phase: breathPhase,
                    child: Text(
                      match.opponent == null
                          ? '⏳'
                          : avatarEmoji(match.opponent!.avatar),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          match.opponent == null
                              ? l.onlineCodeLabel(match.code)
                              : '${l.onlineVsShort} ${opponentHandle(match.opponent)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                              color: tint, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

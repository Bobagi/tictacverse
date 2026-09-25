import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tictacverse/l10n/app_localizations.dart';
import '../../models/achievement.dart';
import '../../models/player_marker.dart';
import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../services/progression_engine.dart';
import '../../services/visual_assets.dart';
import 'achievements_sheet.dart';
import 'juice/count_up_text.dart';
import 'juice/particles.dart';
import 'juice/press_scale.dart';
import 'juice/pulse.dart';
import 'modern_background.dart';
import 'pop_in.dart';

class GameOverModal extends StatefulWidget {
  const GameOverModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPlayAgain,
    required this.onBackToMenu,
    this.winner,
    this.visualAssets,
    this.progression,
    this.onWatchAdForDoubleXp,
    this.xpAfter,
    this.winStreak = 0,
    this.isNewBestStreak = false,
    this.dailyStreak = 0,
    this.celebrate = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToMenu;
  final PlayerMarker? winner;
  final VisualAssetConfig? visualAssets;

  /// Recompensa da partida. Fica dentro do modal de propósito: um SnackBar
  /// aqui apareceria atrás dele (é o bug já conhecido do sheet de ajustes).
  final ProgressionResult? progression;

  /// Exibe o anúncio premiado e devolve a recompensa JÁ CREDITADA, ou `null` se
  /// o jogador não assistiu até o fim. Quando é `null`, a oferta não aparece -
  /// é assim que a tela desliga o convite (anúncios off, nada carregado, ou
  /// logo depois de um intersticial).
  final Future<ProgressionResult?> Function()? onWatchAdForDoubleXp;

  /// XP total DEPOIS da partida. Com ele a barra de nível anima do valor
  /// anterior ao atual (inclusive atravessando a virada de nível). `null`
  /// esconde a barra.
  final int? xpAfter;

  /// Sequência de vitórias contra a máquina depois desta partida.
  final int winStreak;
  final bool isNewBestStreak;

  /// Dias seguidos jogando (já contando hoje).
  final int dailyStreak;

  /// A partida foi uma vitória a comemorar (título com brilho, carimbo).
  final bool celebrate;

  @override
  State<GameOverModal> createState() => _GameOverModalState();
}

class _GameOverModalState extends State<GameOverModal> {
  /// Progressão exibida: começa na da partida e passa a incluir o bônus depois
  /// que o anúncio é assistido.
  ProgressionResult? _progression;
  int? _xpAfter;
  bool _isWatchingAd = false;
  bool _claimed = false;
  bool _adFailed = false;
  final ParticleController _particles = ParticleController();
  final List<Timer> _timers = <Timer>[];

  static const Duration _rewardsStagger = Duration(milliseconds: 160);
  static const Duration _rewardsStart = Duration(milliseconds: 260);

  @override
  void initState() {
    super.initState();
    _progression = widget.progression;
    _xpAfter = widget.xpAfter;
    _scheduleFanfare(_progression, first: true);
  }

  @override
  void dispose() {
    for (final Timer timer in _timers) {
      timer.cancel();
    }
    _particles.dispose();
    super.dispose();
  }

  void _after(Duration delay, VoidCallback action) {
    _timers.add(Timer(delay, () {
      if (mounted) {
        action();
      }
    }));
  }

  /// Sons e vibrações dos avisos, no ritmo em que os chips aparecem.
  void _scheduleFanfare(ProgressionResult? result, {required bool first}) {
    if (result == null) {
      return;
    }
    Duration at = _rewardsStart + _rewardsStagger;
    if (result.leveledUp) {
      _after(at, () {
        AudioService.instance.play(Sfx.levelUp);
        HapticsService.instance.play(HapticCue.levelUp);
      });
      at += _rewardsStagger;
    }
    for (int i = 0; i < result.newlyUnlocked.length; i++) {
      _after(at, () {
        AudioService.instance.play(Sfx.achievement);
        HapticsService.instance.play(HapticCue.capture);
      });
      at += _rewardsStagger;
    }
    if (first && widget.winStreak >= 3) {
      _after(at, () => AudioService.instance.play(Sfx.streak));
    }
  }

  /// Uma oferta por partida: depois de creditada, o botão sai de cena. O
  /// `_claimed` é travado ANTES do `await` para que um toque duplo rápido não
  /// dispare dois anúncios.
  Future<void> _handleWatchAd() async {
    final Future<ProgressionResult?> Function()? request =
        widget.onWatchAdForDoubleXp;
    if (request == null || _isWatchingAd || _claimed) {
      return;
    }
    AudioService.instance.playUiClick();
    HapticsService.instance.play(HapticCue.tap);
    setState(() {
      _isWatchingAd = true;
      _adFailed = false;
    });
    final ProgressionResult? bonus = await request();
    if (!mounted) {
      return;
    }
    setState(() {
      _isWatchingAd = false;
      if (bonus == null) {
        _adFailed = true;
        return;
      }
      _claimed = true;
      final ProgressionResult? current = _progression;
      _progression = current == null ? bonus : current.mergedWith(bonus);
      final int? xp = _xpAfter;
      if (xp != null) {
        _xpAfter = xp + bonus.xpGained;
      }
    });
    _scheduleFanfare(bonus, first: false);
    _sparkleXp();
  }

  void _sparkleXp() {
    final Size size = _particles.viewport;
    _particles.sparkle(
      area: Rect.fromLTWH(size.width * 0.15, size.height * 0.35,
          size.width * 0.7, size.height * 0.2),
      color: VerseColors.energy,
      count: 26,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    // Com sequências, nível, conquista, barra e oferta juntos, o conteúdo
    // passa de 568px (menor Android atendido): o miolo rola e a linha de
    // ações fica fixa embaixo, para "jogar de novo" nunca sair da tela.
    final double maxHeight = MediaQuery.of(context).size.height * 0.88;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: GlassPanel(
            child: Stack(
              children: <Widget>[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            PopIn(
                              beginScale: widget.celebrate ? 1.5 : 0.8,
                              duration: const Duration(milliseconds: 360),
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontFamily: 'Fredoka',
                                      fontWeight: FontWeight.w700,
                                      shadows: widget.celebrate
                                          ? <Shadow>[
                                              Shadow(
                                                color: VerseColors.energy
                                                    .withOpacity(0.7),
                                                blurRadius: 18,
                                              ),
                                            ]
                                          : null,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildWinnerDetails(context),
                            _buildStreaks(context, localization),
                            _buildProgressionRewards(context, localization),
                            _buildXpBar(context, localization),
                            _buildDoubleXpOffer(context, localization),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Wrap, não Row: em 360x640 os dois botões não cabem lado a
                    // lado em inglês (estourava 85px), e menos ainda em hindi.
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: <Widget>[
                        PressScale(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent.shade400,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 12),
                            ),
                            onPressed: () {
                              AudioService.instance.playUiClick();
                              HapticsService.instance.play(HapticCue.tap);
                              widget.onPlayAgain();
                            },
                            child: Text(localization.playAgain),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            AudioService.instance.playUiClick();
                            HapticsService.instance.play(HapticCue.tap);
                            widget.onBackToMenu();
                          },
                          child: Text(localization.backToMenu),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned.fill(child: ParticleField(controller: _particles)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sequências: vitórias seguidas contra a máquina e dias seguidos jogando.
  /// São o gancho de retorno mais forte do jogo, então ganham fogo e pulso.
  Widget _buildStreaks(BuildContext context, AppLocalizations localization) {
    final List<Widget> chips = <Widget>[];
    if (widget.winStreak >= 2) {
      chips.add(Pulse(
        maxScale: 1.05,
        child: _RewardChip(
          icon: Icons.local_fire_department_rounded,
          label: widget.isNewBestStreak
              ? '${localization.winStreakChip(widget.winStreak)} '
                  '${localization.newRecordChip}'
              : localization.winStreakChip(widget.winStreak),
          tint: VerseColors.danger,
        ),
      ));
    }
    if (widget.dailyStreak >= 2) {
      chips.add(_RewardChip(
        icon: Icons.calendar_month_rounded,
        label: localization.dailyStreakChip(widget.dailyStreak),
        tint: const Color(0xFF3EF0C4),
      ));
    }
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (int i = 0; i < chips.length; i++)
            PopIn(
              delay: Duration(milliseconds: 120 + 120 * i),
              beginScale: 0.5,
              child: chips[i],
            ),
        ],
      ),
    );
  }

  /// Faixa de recompensa: XP sempre (contando para cima), e chips de nível e
  /// conquista entrando um a um.
  Widget _buildProgressionRewards(
    BuildContext context,
    AppLocalizations localization,
  ) {
    final ProgressionResult? result = _progression;
    if (result == null || result.xpGained <= 0) {
      return const SizedBox.shrink();
    }
    int slot = 0;
    Duration nextDelay() => _rewardsStart + _rewardsStagger * (slot++);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          PopIn(
            delay: nextDelay(),
            beginScale: 0.5,
            child: _RewardChip(
              icon: Icons.bolt_rounded,
              tint: VerseColors.cross,
              child: CountUpText(
                value: result.xpGained,
                format: localization.xpGained,
                duration: const Duration(milliseconds: 800),
                onTick: () => AudioService.instance.play(Sfx.xpTick),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          if (result.leveledUp)
            PopIn(
              delay: nextDelay(),
              beginScale: 1.6,
              duration: const Duration(milliseconds: 380),
              onStart: _sparkleXp,
              child: Pulse(
                maxScale: 1.06,
                child: _RewardChip(
                  icon: Icons.trending_up_rounded,
                  label: localization.levelUpToast(result.levelAfter),
                  tint: VerseColors.energy,
                  emphasized: true,
                ),
              ),
            ),
          for (final AchievementDefinition achievement in result.newlyUnlocked)
            PopIn(
              delay: nextDelay(),
              beginScale: 1.6,
              duration: const Duration(milliseconds: 380),
              child: _RewardChip(
                icon: Icons.emoji_events_rounded,
                label: achievement.title(localization),
                tint: achievementTierColor(achievement.tier),
                emphasized: true,
              ),
            ),
        ],
      ),
    );
  }

  /// Barra de nível enchendo do XP anterior ao atual.
  Widget _buildXpBar(BuildContext context, AppLocalizations localization) {
    final ProgressionResult? result = _progression;
    final int? xpAfter = _xpAfter;
    if (result == null || result.xpGained <= 0 || xpAfter == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _AnimatedXpBar(
        key: ValueKey<int>(xpAfter),
        from: xpAfter - result.xpGained,
        to: xpAfter,
        localization: localization,
      ),
    );
  }

  /// Convite para dobrar o XP assistindo a um anúncio premiado.
  ///
  /// Fica **abaixo** dos chips e separado da linha de ações por um respiro
  /// maior, com estilo de contorno em vez do verde sólido do "jogar de novo":
  /// clique acidental em anúncio é justamente o que derrubou a conta do AdMob
  /// em 2026-07, então a oferta nunca imita o botão primário nem encosta nele.
  Widget _buildDoubleXpOffer(
    BuildContext context,
    AppLocalizations localization,
  ) {
    if (widget.onWatchAdForDoubleXp == null) {
      return const SizedBox.shrink();
    }
    final ProgressionResult? result = _progression;
    if (result == null || result.xpGained <= 0) {
      return const SizedBox.shrink();
    }
    if (_claimed) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: PopIn(
          beginScale: 1.5,
          child: _RewardChip(
            icon: Icons.check_circle_rounded,
            label: localization.doubleXpDone,
            tint: VerseColors.energy,
            emphasized: true,
          ),
        ),
      );
    }
    if (_adFailed) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text(
          localization.doubleXpUnavailable,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: OutlinedButton.icon(
        onPressed: _isWatchingAd ? null : _handleWatchAd,
        style: OutlinedButton.styleFrom(
          foregroundColor: VerseColors.energy,
          side: BorderSide(color: VerseColors.energy.withOpacity(0.7)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        icon: _isWatchingAd
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_circle_outline_rounded, size: 20),
        label: Text(
          localization.doubleXpCta,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildWinnerDetails(BuildContext context) {
    if (widget.winner == null) {
      // Empate: selo neutro. Antes aparecia o texto "Jogar novamente" aqui,
      // repetindo o botão logo abaixo.
      return PopIn(
        beginScale: 1.6,
        duration: const Duration(milliseconds: 380),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: VerseColors.mutedText.withOpacity(0.7), width: 2),
            color: Colors.white.withOpacity(0.06),
          ),
          child: const Icon(Icons.handshake_rounded,
              size: 34, color: VerseColors.mutedText),
        ),
      );
    }
    if (widget.visualAssets == null) {
      return Text(widget.subtitle,
          style: Theme.of(context).textTheme.bodyMedium);
    }

    final String assetPath = widget.winner == PlayerMarker.cross
        ? widget.visualAssets!.crossAssetPath
        : widget.visualAssets!.noughtAssetPath;
    final Color accentColor = widget.winner == PlayerMarker.cross
        ? const Color(0xFF6BE0FF)
        : const Color(0xFFFF6BD9);

    return PopIn(
      beginScale: 1.8,
      duration: const Duration(milliseconds: 420),
      child: Pulse(
        active: widget.celebrate,
        maxScale: 1.08,
        period: const Duration(milliseconds: 1100),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withOpacity(0.9), width: 2.5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                  color: accentColor.withOpacity(0.55),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
            gradient: RadialGradient(
              colors: <Color>[
                accentColor.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: Image.asset(
            assetPath,
            width: 38,
            height: 38,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// Barra de XP que anima de [from] a [to], mostrando o nível corrente. Quando
/// atravessa uma virada de nível, enche até o fim, "estala" e recomeça do
/// zero no nível seguinte - é o momento que o jogador espera ver.
class _AnimatedXpBar extends StatelessWidget {
  const _AnimatedXpBar({
    super.key,
    required this.from,
    required this.to,
    required this.localization,
  });

  final int from;
  final int to;
  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final int levels =
        ProgressionEngine.levelForXp(to) - ProgressionEngine.levelForXp(from);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: reduceMotion ? to.toDouble() : from.toDouble(),
        end: to.toDouble(),
      ),
      duration: Duration(milliseconds: 900 + 350 * levels),
      curve: Curves.easeInOutCubic,
      builder: (BuildContext context, double animated, Widget? _) {
        final int xp = animated.round();
        final int level = ProgressionEngine.levelForXp(xp);
        final (int into, int span) = ProgressionEngine.levelBar(xp);
        final double fraction = span == 0 ? 0 : (into / span).clamp(0.0, 1.0);
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VerseColors.energy.withOpacity(0.18),
                    border:
                        Border.all(color: VerseColors.energy.withOpacity(0.7)),
                  ),
                  child: Text(
                    '$level',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: VerseColors.energy,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 9,
                      backgroundColor: Colors.white.withOpacity(0.10),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          VerseColors.energy),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  localization.xpProgress(into, span),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: VerseColors.mutedText),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.tint,
    this.label,
    this.child,
    this.emphasized = false,
  }) : assert(label != null || child != null);

  final IconData icon;
  final String? label;
  final Widget? child;
  final Color tint;

  /// Brilho mais forte para o que é raro (nível, conquista).
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tint.withOpacity(emphasized ? 0.26 : 0.16),
        border: Border.all(color: tint.withOpacity(emphasized ? 0.95 : 0.65)),
        boxShadow: emphasized
            ? <BoxShadow>[
                BoxShadow(color: tint.withOpacity(0.45), blurRadius: 14),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: tint),
          const SizedBox(width: 6),
          Flexible(
            child: child ??
                Text(
                  label!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
          ),
        ],
      ),
    );
  }
}

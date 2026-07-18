import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../controllers/banner_ad_controller.dart';
import '../../controllers/game_controller.dart';
import '../../models/cpu_difficulty.dart';
import '../../models/game_mode.dart';
import '../../services/ads_configuration.dart';
import '../../services/audio_service.dart';
import '../../services/metrics_service.dart';
import '../../services/storage_service.dart';
import '../widgets/mode_card.dart';
import '../widgets/modern_background.dart';
import 'game_screen.dart';
import 'ultimate2_screen.dart';

class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({
    super.key,
    required this.playAgainstCpu,
    required this.metricsService,
  });

  final bool playAgainstCpu;
  final MetricsService metricsService;

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  final List<GameModeDefinition> modes = createGameModes();
  final BannerAdController bannerAdController = BannerAdController();
  final AudioService audioService = AudioService.instance;
  CpuDifficulty cpuDifficulty = StorageService.instance.cpuDifficulty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bannerAdController.loadBannerAd(
        context: context,
        onAdLoaded: _refresh,
        onAdFailed: _refresh,
      );
    });
  }

  @override
  void dispose() {
    bannerAdController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(localization.chooseModeTitle),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (widget.playAgainstCpu) ...<Widget>[
                  _buildDifficultySelector(localization),
                  const SizedBox(height: 14),
                ],
                Expanded(
                  child: ListView.separated(
                    itemCount: modes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final GameModeDefinition definition = modes[index];
                      final (Color, IconData) look = _modeLook(definition.type);
                      final Widget card = ModeCard(
                        title: definition.title(localization),
                        subtitle: definition.subtitle(localization),
                        buttonLabel: localization.playLabel,
                        accent: look.$1,
                        icon: look.$2,
                        onStart: () => _openGame(definition),
                      );
                      if (definition.type == GameModeType.ultimate2) {
                        return _FlagshipGlow(child: card);
                      }
                      return card;
                    },
                  ),
                ),
                if (AdsConfiguration.adsEnabled) ...<Widget>[
                  const SizedBox(height: 14),
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

  Widget _buildDifficultySelector(AppLocalizations localization) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            localization.difficultyLabel,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              for (final CpuDifficulty difficulty in CpuDifficulty.values) ...<Widget>[
                if (difficulty != CpuDifficulty.values.first)
                  const SizedBox(width: 8),
                Expanded(
                  child: _DifficultyPill(
                    label: _difficultyLabel(localization, difficulty),
                    accent: _difficultyColor(difficulty),
                    isActive: cpuDifficulty == difficulty,
                    onTap: () {
                      audioService.playUiClick();
                      setState(() {
                        cpuDifficulty = difficulty;
                      });
                      StorageService.instance.saveCpuDifficulty(difficulty);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _difficultyLabel(
      AppLocalizations localization, CpuDifficulty difficulty) {
    switch (difficulty) {
      case CpuDifficulty.easy:
        return localization.difficultyEasy;
      case CpuDifficulty.medium:
        return localization.difficultyMedium;
      case CpuDifficulty.hard:
        return localization.difficultyHard;
    }
  }

  Color _difficultyColor(CpuDifficulty difficulty) {
    switch (difficulty) {
      case CpuDifficulty.easy:
        return const Color(0xFF35A2FF);
      case CpuDifficulty.medium:
        return VerseColors.energy;
      case CpuDifficulty.hard:
        return VerseColors.danger;
    }
  }

  (Color, IconData) _modeLook(GameModeType type) {
    switch (type) {
      case GameModeType.ultimate2:
        return (VerseColors.energy, Icons.grid_view_rounded);
      case GameModeType.classic:
        return (VerseColors.cross, Icons.grid_3x3_rounded);
      case GameModeType.shift:
        return (const Color(0xFF3EF0C4), Icons.autorenew_rounded);
      case GameModeType.chaos:
        return (VerseColors.nought, Icons.bolt_rounded);
      case GameModeType.ultimateMini:
        return (const Color(0xFFB98BFF), Icons.auto_awesome_rounded);
    }
  }

  void _openGame(GameModeDefinition definition) {
    if (definition.type == GameModeType.ultimate2) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => Ultimate2Screen(
            playAgainstCpu: widget.playAgainstCpu,
            cpuDifficulty: cpuDifficulty,
            metricsService: widget.metricsService,
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => GameScreen(
          controller: GameController(
            modeDefinition: definition,
            playAgainstCpu: widget.playAgainstCpu,
            cpuDifficulty: cpuDifficulty,
          ),
          metricsService: widget.metricsService,
        ),
      ),
    );
  }
}

/// Moldura neon pulsante do carro-chefe (Tic Tac Toe 2).
class _FlagshipGlow extends StatefulWidget {
  const _FlagshipGlow({required this.child});

  final Widget child;

  @override
  State<_FlagshipGlow> createState() => _FlagshipGlowState();
}

class _FlagshipGlowState extends State<_FlagshipGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        final Color glow =
            Color.lerp(VerseColors.cross, VerseColors.nought, t)!;
        // Preenchimento em gradiente (vira a "borda") + sombra: com fill
        // sólido a sombra segue o raio arredondado — sem halo quadrado.
        return Container(
          padding: const EdgeInsets.all(2.4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: <Color>[glow, VerseColors.energy, glow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: glow.withOpacity(0.28 + 0.22 * t),
                blurRadius: 16 + 8 * t,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17.6),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  const _DifficultyPill({
    required this.label,
    required this.accent,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? accent : accent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? Colors.white : accent.withOpacity(0.55),
            ),
            boxShadow: isActive
                ? <BoxShadow>[
                    BoxShadow(color: accent.withOpacity(0.5), blurRadius: 12),
                  ]
                : const <BoxShadow>[],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: isActive ? const Color(0xFF160B29) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

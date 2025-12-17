import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';
import '../../localization/app_localizations.dart';
import '../../models/game_mode.dart';
import '../../services/ad_service.dart';
import '../../services/metrics_service.dart';
import '../widgets/modern_background.dart';
import '../screens/game_screen.dart';
import '../widgets/mode_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.metricsService});

  final MetricsService metricsService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<GameModeDefinition> modes = createGameModes();
  final AdService adService = AdService();
  bool playAgainstCpu = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context);
    return ModernGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(localization.appTitle),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                _buildModeToggle(localization),
                const SizedBox(height: 16),
                Expanded(
                  child: GlassPanel(
                    padding: const EdgeInsets.all(12),
                    child: ListView.separated(
                      itemCount: modes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final GameModeDefinition definition = modes[index];
                        return ModeCard(
                          title: definition.title(localization),
                          subtitle: definition.subtitle(localization),
                          onStart: () => _openGame(definition),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(localization.adsBannerPlacement, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(localization.adInterstitialHint, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openGame(GameModeDefinition definition) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => GameScreen(
          controller: GameController(modeDefinition: definition, playAgainstCpu: playAgainstCpu),
          adService: adService,
          metricsService: widget.metricsService,
        ),
      ),
    );
  }

  Widget _buildModeToggle(AppLocalizations localization) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(localization.gameModeLabel, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: _ModePill(
                  icon: Icons.group_rounded,
                  label: localization.twoPlayers,
                  isActive: !playAgainstCpu,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Switch(
                  value: playAgainstCpu,
                  onChanged: (bool value) {
                    setState(() {
                      playAgainstCpu = value;
                    });
                  },
                  activeColor: Colors.lightBlueAccent,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                ),
              ),
              Expanded(
                child: _ModePill(
                  icon: Icons.computer_rounded,
                  label: localization.cpuOpponent,
                  isActive: playAgainstCpu,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.icon, required this.label, required this.isActive});

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? <Color>[const Color(0xFF1AD1FF), const Color(0xFF6F7CFF)]
              : <Color>[Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? Colors.white : Colors.white.withOpacity(0.25)),
        boxShadow: isActive
            ? <BoxShadow>[
                BoxShadow(color: Colors.cyanAccent.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8)),
              ]
            : <BoxShadow>[],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: isActive ? const Color(0xFF041427) : Colors.white70),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isActive ? const Color(0xFF041427) : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

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
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(localization.gameModeLabel, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(playAgainstCpu ? localization.cpuOpponent : localization.twoPlayers),
                        value: playAgainstCpu,
                        onChanged: (bool value) {
                          setState(() {
                            playAgainstCpu = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
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
}

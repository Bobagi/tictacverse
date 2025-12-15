import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';
import '../../localization/app_localizations.dart';
import '../../models/game_mode.dart';
import '../../services/ad_service.dart';
import '../../services/metrics_service.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.appTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(localization.gameModeLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(playAgainstCpu ? localization.cpuOpponent : localization.twoPlayers),
              value: playAgainstCpu,
              onChanged: (bool value) {
                setState(() {
                  playAgainstCpu = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: modes.length,
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
            const SizedBox(height: 8),
            Text(localization.adsBannerPlacement),
            Text(localization.adInterstitialHint),
          ],
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

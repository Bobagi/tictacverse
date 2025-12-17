import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum GameModeType {
  classic,
  shift,
  chaos,
  ultimateMini,
}

class GameModeDefinition {
  GameModeDefinition({
    required this.type,
    required this.titleBuilder,
    required this.subtitleBuilder,
  });

  final GameModeType type;
  final String Function(AppLocalizations localization) titleBuilder;
  final String Function(AppLocalizations localization) subtitleBuilder;

  String title(AppLocalizations localization) => titleBuilder(localization);

  String subtitle(AppLocalizations localization) => subtitleBuilder(localization);
}

List<GameModeDefinition> createGameModes() => <GameModeDefinition>[
      GameModeDefinition(
        type: GameModeType.classic,
        titleBuilder: (AppLocalizations localization) => localization.modeClassicTitle,
        subtitleBuilder: (AppLocalizations localization) => localization.modeClassicSubtitle,
      ),
      GameModeDefinition(
        type: GameModeType.shift,
        titleBuilder: (AppLocalizations localization) => localization.modeShiftTitle,
        subtitleBuilder: (AppLocalizations localization) => localization.modeShiftSubtitle,
      ),
      GameModeDefinition(
        type: GameModeType.chaos,
        titleBuilder: (AppLocalizations localization) => localization.modeChaosTitle,
        subtitleBuilder: (AppLocalizations localization) => localization.modeChaosSubtitle,
      ),
      GameModeDefinition(
        type: GameModeType.ultimateMini,
        titleBuilder: (AppLocalizations localization) => localization.modeUltimateTitle,
        subtitleBuilder: (AppLocalizations localization) => localization.modeUltimateSubtitle,
      ),
    ];

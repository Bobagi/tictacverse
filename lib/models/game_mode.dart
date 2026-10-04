import 'package:tictacverse/l10n/app_localizations.dart';

enum GameModeType {
  classic,
  shift,
  chaos,
  ultimateMini,
  ultimate2,
  fourByFour,
  gomoku,
}

/// Formato do tabuleiro de cada modo que roda no `GameController`.
///
/// Os modos 3x3 seguem com tabuleiro 3 e linha de 3. O Super Jogo da Velha
/// (`ultimate2`) tem tela e engine próprias: aqui ele aparece como 3x3 só
/// porque o macro-tabuleiro é 3x3, ninguém deve desenhar o tabuleiro dele por
/// estes números.
extension GameModeBoardShape on GameModeType {
  /// Lado do tabuleiro quadrado (o tabuleiro tem `boardSize * boardSize` casas).
  int get boardSize {
    switch (this) {
      case GameModeType.fourByFour:
        return 4;
      case GameModeType.gomoku:
        return 10;
      case GameModeType.classic:
      case GameModeType.shift:
      case GameModeType.chaos:
      case GameModeType.ultimateMini:
      case GameModeType.ultimate2:
        return 3;
    }
  }

  /// Quantas peças seguidas vencem. No Cinco em linha vale 5 ou mais
  /// (regra livre: seis seguidas também ganham).
  int get winLength {
    switch (this) {
      case GameModeType.fourByFour:
        return 4;
      case GameModeType.gomoku:
        return 5;
      case GameModeType.classic:
      case GameModeType.shift:
      case GameModeType.chaos:
      case GameModeType.ultimateMini:
      case GameModeType.ultimate2:
        return 3;
    }
  }

  /// Modo de tabuleiro maior que o 3x3, jogado pelas regras de linha
  /// genéricas (`LineRulesEngine`) e pela CPU de linha (`LineCpu`).
  bool get isLineMode =>
      this == GameModeType.fourByFour || this == GameModeType.gomoku;
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
        type: GameModeType.ultimate2,
        titleBuilder: (AppLocalizations localization) => localization.modeUltimate2Title,
        subtitleBuilder: (AppLocalizations localization) => localization.modeUltimate2Subtitle,
      ),
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
      GameModeDefinition(
        type: GameModeType.fourByFour,
        titleBuilder: (AppLocalizations localization) => localization.modeFourByFourTitle,
        subtitleBuilder: (AppLocalizations localization) => localization.modeFourByFourSubtitle,
      ),
      GameModeDefinition(
        type: GameModeType.gomoku,
        titleBuilder: (AppLocalizations localization) => localization.modeGomokuTitle,
        subtitleBuilder: (AppLocalizations localization) => localization.modeGomokuSubtitle,
      ),
    ];

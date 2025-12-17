// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Tic Tac Verse';

  @override
  String get modeClassicTitle => 'Jogo da Velha Clássico';

  @override
  String get modeClassicSubtitle => 'Regras tradicionais para partidas rápidas.';

  @override
  String get modeShiftTitle => 'Tic Tac Turno';

  @override
  String get modeShiftSubtitle => 'Apenas três peças ativas por jogador.';

  @override
  String get modeChaosTitle => 'Tic Tac Caos';

  @override
  String get modeChaosSubtitle => 'A cada poucos turnos surge uma regra caótica.';

  @override
  String get modeUltimateTitle => 'Tic Tac Mini Supremo';

  @override
  String get modeUltimateSubtitle => 'Vença com condições de desafio rotativas.';

  @override
  String get startMatch => 'Iniciar partida';

  @override
  String get twoPlayers => 'Dois jogadores';

  @override
  String get cpuOpponent => 'Jogar contra CPU';

  @override
  String get currentPlayer => 'Jogador atual';

  @override
  String get drawResult => 'Empate!';

  @override
  String get winnerResult => 'Vencedor';

  @override
  String get playAgain => 'Jogar novamente';

  @override
  String get backToMenu => 'Voltar ao menu';

  @override
  String get chaosRemovePiece => 'Caos: Uma peça aleatória foi removida!';

  @override
  String get chaosBlockCell => 'Caos: Uma célula está bloqueada neste turno!';

  @override
  String get chaosSwapSymbols => 'Caos: Símbolos trocados por um turno!';

  @override
  String get ultimateNoCenter => 'Vença sem usar a célula central.';

  @override
  String get ultimateLimitedMoves => 'Vença dentro de um número limitado de jogadas.';

  @override
  String get ultimateCornersOnly => 'Vença usando apenas as quinas.';

  @override
  String get movesRemaining => 'Jogadas restantes';

  @override
  String get adsBannerPlacement => 'Banners aparecem apenas na tela de jogo.';

  @override
  String get adInterstitialHint => 'Intersticiais aparecem após algumas partidas.';

  @override
  String get gameModeLabel => 'Modo de jogo';

  @override
  String get tapToClaim => 'Toque em qualquer célula para capturá-la';

  @override
  String get winInstruction => 'Forme uma linha de três para vencer a corrida neon.';

  @override
  String get takeTurnCta => 'Faça sua jogada e ilumine o tabuleiro';

  @override
  String get playLabel => 'Jogar';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languagePortuguese => 'Português';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Tic Tac Verse';

  @override
  String get modeClassicTitle => 'Tres en raya clásico';

  @override
  String get modeClassicSubtitle =>
      'Reglas tradicionales para partidas rápidas.';

  @override
  String get modeShiftTitle => 'Tic Tac Cambio';

  @override
  String get modeShiftSubtitle => 'Solo tres piezas activas por jugador.';

  @override
  String get modeChaosTitle => 'Tic Tac Caos';

  @override
  String get modeChaosSubtitle =>
      'Cada pocos turnos aparece una regla caótica.';

  @override
  String get modeUltimateTitle => 'Tic Tac Mini Supremo';

  @override
  String get modeUltimateSubtitle =>
      'Gana con condiciones de desafío rotativas.';

  @override
  String get startMatch => 'Iniciar partida';

  @override
  String get twoPlayers => 'Dos jugadores';

  @override
  String get cpuOpponent => 'Jugar contra CPU';

  @override
  String get currentPlayer => 'Jugador actual';

  @override
  String get drawResult => '¡Empate!';

  @override
  String get winnerResult => 'Ganador';

  @override
  String get playAgain => 'Jugar de nuevo';

  @override
  String get backToMenu => 'Volver al menú';

  @override
  String get chaosRemovePiece => 'Caos: ¡Se eliminó una pieza aleatoria!';

  @override
  String get chaosBlockCell => 'Caos: ¡Una celda está bloqueada este turno!';

  @override
  String get chaosSwapSymbols => 'Caos: ¡Símbolos intercambiados por un turno!';

  @override
  String get ultimateNoCenter => 'Gana sin usar la celda central.';

  @override
  String get ultimateLimitedMoves =>
      'Gana dentro de un número limitado de jugadas.';

  @override
  String get movesRemaining => 'Jugadas restantes';

  @override
  String get adsBannerPlacement =>
      'Los banners aparecen solo en la pantalla de juego.';

  @override
  String get adInterstitialHint =>
      'Los intersticiales aparecen después de algunas partidas.';

  @override
  String get gameModeLabel => 'Modo de juego';

  @override
  String get helpTitle => 'Ayuda';

  @override
  String get tapToClaim => 'Toca cualquier celda para capturarla';

  @override
  String get closeLabel => 'Cerrar';

  @override
  String get winInstruction =>
      'Forma una línea de tres para ganar la carrera neón.';

  @override
  String get takeTurnCta => 'Haz tu jugada e ilumina el tablero';

  @override
  String get playLabel => 'Jugar';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Portugués';

  @override
  String get languageSpanish => 'Español';

  @override
  String get audioLabel => 'Audio';

  @override
  String get muteLabel => 'Silenciar';

  @override
  String get volumeLabel => 'Volumen';
}

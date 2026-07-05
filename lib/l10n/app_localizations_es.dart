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
  String get modeClassicTitle => 'Tres en Raya Clásico';

  @override
  String get modeClassicSubtitle =>
      'Reglas tradicionales para partidas rápidas.';

  @override
  String get modeShiftTitle => 'Modo Shift';

  @override
  String get modeShiftSubtitle =>
      'Solo 3 fichas por jugador — la más antigua desaparece.';

  @override
  String get modeChaosTitle => 'Modo Caos';

  @override
  String get modeChaosSubtitle =>
      'Cada pocas rondas, un evento cambia las reglas.';

  @override
  String get modeUltimateTitle => 'Mini Supremo';

  @override
  String get modeUltimateSubtitle =>
      'Gana bajo una condición especial que cambia cada partida.';

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

  @override
  String get difficultyLabel => 'Dificultad';

  @override
  String get difficultyEasy => 'Fácil';

  @override
  String get difficultyMedium => 'Medio';

  @override
  String get difficultyHard => 'Imposible';

  @override
  String get statsTitle => 'Estadísticas';

  @override
  String get statsTotalMatches => 'Partidas jugadas';

  @override
  String get statsVsCpu => 'Contra la CPU';

  @override
  String get statsWins => 'Victorias';

  @override
  String get statsLosses => 'Derrotas';

  @override
  String get statsDraws => 'Empates';

  @override
  String get statsStreak => 'Racha de victorias';

  @override
  String get statsBestStreak => 'Mejor racha';

  @override
  String get statsByMode => 'Por modo';

  @override
  String get statsEmpty => '¡Juega una partida para empezar tus estadísticas!';

  @override
  String get updatesLabel => 'Actualizaciones';

  @override
  String get checkUpdatesLabel => 'Buscar actualizaciones';

  @override
  String get upToDateMessage => '¡Ya estás en la versión más reciente!';

  @override
  String get updateFailedMessage =>
      'No se pudo comprobar si hay actualizaciones. Inténtalo más tarde.';

  @override
  String get modeUltimate2Title => 'Súper Tres en Raya';

  @override
  String get modeUltimate2Subtitle =>
      '9 tableros en uno. Tu jugada decide dónde juega el rival.';

  @override
  String get ultimate2FreeMove => 'Jugada libre: juega en cualquier tablero';

  @override
  String get ultimate2PlayIn => 'Juega en el tablero resaltado';

  @override
  String get ultimate2Help =>
      'Cada casilla del tablero grande guarda un tres en raya pequeño. La casilla que marcas dentro de un tablero pequeño envía a tu rival al tablero correspondiente. Gana un tablero pequeño para conquistar su casilla en el grande — haz tres casillas conquistadas en línea para ganar. Si el destino está cerrado, la jugada es libre.';

  @override
  String get playVsCpuBig => 'Jugar contra la máquina';

  @override
  String get playWithFriend => 'Jugar con un amigo';

  @override
  String get chooseModeTitle => 'Elige el modo';
}

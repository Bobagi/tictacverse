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
      'Solo 3 fichas por jugador - la más antigua desaparece.';

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
  String get winInstruction => 'Alinea tres para ganar.';

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
  String get languageHindi => 'हिन्दी';

  @override
  String get languageBengali => 'বাংলা';

  @override
  String get languageNepali => 'नेपाली';

  @override
  String get langSuggestTitle => '¡Ahora disponible en tu idioma!';

  @override
  String get langSuggestAccept => 'Cambiar idioma';

  @override
  String get langSuggestKeep => 'Seguir en español';

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
  String get modeFourByFourTitle => '4x4';

  @override
  String get modeFourByFourSubtitle =>
      'Cuatro en línea en un tablero más grande.';

  @override
  String get modeGomokuTitle => 'Cinco en línea';

  @override
  String get modeGomokuSubtitle =>
      'Gomoku: alinea cinco en un tablero de 10x10.';

  @override
  String get winInstructionFour => 'Alinea cuatro para ganar.';

  @override
  String get winInstructionFive => 'Alinea cinco para ganar.';

  @override
  String get ultimate2FreeMove => 'Jugada libre: cualquier tablero';

  @override
  String get ultimate2PlayIn => 'Juega en el tablero iluminado';

  @override
  String get ultimate2Help =>
      'Cada casilla del tablero grande guarda un tres en raya pequeño. La casilla que marcas dentro de un tablero pequeño envía a tu rival al tablero correspondiente. Gana un tablero pequeño para conquistar su casilla en el grande - haz tres casillas conquistadas en línea para ganar. Si el destino está cerrado, la jugada es libre.';

  @override
  String get playVsCpuBig => 'Jugar contra la máquina';

  @override
  String get playWithFriend => 'Jugar con un amigo';

  @override
  String get chooseModeTitle => 'Elige el modo';

  @override
  String get achievementsTitle => 'Logros';

  @override
  String achievementsProgress(int unlocked, int total) {
    return '$unlocked de $total desbloqueados';
  }

  @override
  String get achievementsEmpty =>
      'Juega una partida para empezar a desbloquear logros.';

  @override
  String levelLabel(int level) {
    return 'Nivel $level';
  }

  @override
  String xpProgress(int into, int span) {
    return '$into / $span XP';
  }

  @override
  String xpGained(int amount) {
    return '+$amount XP';
  }

  @override
  String get achUnlockedToast => '¡Logro desbloqueado!';

  @override
  String get doubleXpCta => 'Ver anuncio y duplicar XP y monedas';

  @override
  String get doubleXpDone => '¡XP y monedas duplicados!';

  @override
  String get doubleXpUnavailable =>
      'El anuncio no cargó. Inténtalo en la próxima partida.';

  @override
  String levelUpToast(int level) {
    return '¡Nivel $level alcanzado!';
  }

  @override
  String get achFirstWinTitle => 'Primera victoria';

  @override
  String get achFirstWinDesc => 'Vence a la máquina por primera vez';

  @override
  String get achWins10Title => 'Ganador';

  @override
  String get achWins50Title => 'Dominante';

  @override
  String get achWins200Title => 'Leyenda';

  @override
  String achDescWins(int count) {
    return 'Gana $count partidas contra la máquina';
  }

  @override
  String get achStreak3Title => 'Calentando';

  @override
  String get achStreak7Title => 'En racha';

  @override
  String get achStreak15Title => 'Imparable';

  @override
  String achDescStreak(int count) {
    return 'Gana $count partidas seguidas';
  }

  @override
  String get achHardWinTitle => 'No tan imposible';

  @override
  String get achHardWinDesc => 'Vence a la máquina en Imposible';

  @override
  String get achAllModesTitle => 'Explorador';

  @override
  String get achAllModesDesc => 'Juega 5 modos de juego distintos';

  @override
  String get achUltimateWinsTitle => 'Maestro del tablero';

  @override
  String achDescUltimateWins(int count) {
    return 'Gana $count partidas en Súper Tres en Raya';
  }

  @override
  String get achDaily3Title => 'Rutina';

  @override
  String get achDaily7Title => 'Semana completa';

  @override
  String get achDaily30Title => 'Dedicado';

  @override
  String achDescDaily(int count) {
    return 'Juega $count días seguidos';
  }

  @override
  String get achFastWinTitle => 'Relámpago';

  @override
  String get achFastWinDesc => 'Gana el Clásico en solo 3 jugadas';

  @override
  String get achMatches50Title => 'Veterano';

  @override
  String get achMatches250Title => 'Maratonista';

  @override
  String achDescMatches(int count) {
    return 'Juega $count partidas';
  }

  @override
  String get playGamesOpen => 'Ver en Play Games';

  @override
  String get hapticsLabel => 'Vibración';

  @override
  String get youWinTitle => '¡Ganaste!';

  @override
  String get cpuWinsTitle => 'La máquina ganó';

  @override
  String playerWinsTitle(String symbol) {
    return '¡Ganó $symbol!';
  }

  @override
  String winStreakChip(int count) {
    return '¡$count victorias seguidas!';
  }

  @override
  String dailyStreakChip(int count) {
    return '$count días seguidos';
  }

  @override
  String get newRecordChip => '¡Nuevo récord!';

  @override
  String get cpuThinking => 'Pensando...';

  @override
  String get yourTurn => 'Tu turno';

  @override
  String get updateAvailableTitle => 'Nueva versión disponible';

  @override
  String get updateAvailableBody =>
      'Actualiza ahora para tener las últimas mejoras y correcciones.';

  @override
  String get updateNowLabel => 'Actualizar';

  @override
  String get updateLaterLabel => 'Después';

  @override
  String get coinsLabel => 'Monedas';

  @override
  String coinsGained(int amount) {
    return '+$amount monedas';
  }

  @override
  String get shopTitle => 'Estilo de fichas';

  @override
  String get shopSubtitle =>
      'Gana monedas jugando y cambia el estilo de la X y la O.';

  @override
  String get shopEquip => 'Usar';

  @override
  String get shopEquipped => 'En uso';

  @override
  String get shopPurchased => '¡Nuevo estilo desbloqueado!';

  @override
  String get skinAurora => 'Aurora';

  @override
  String get skinNeon => 'Neón';

  @override
  String get skinFireIce => 'Fuego y hielo';

  @override
  String get skinCandy => 'Caramelo';

  @override
  String get skinGold => 'Oro y plata';

  @override
  String get skinGalaxy => 'Galaxia';

  @override
  String adCoinsCta(int amount) {
    return 'Ver anuncio: +$amount monedas';
  }

  @override
  String adCoinsLeft(int count) {
    return 'Quedan $count hoy';
  }

  @override
  String get adCoinsSoldOut => 'Vuelve mañana para más monedas por anuncio.';

  @override
  String get adUnavailable => 'No hay anuncios ahora. Inténtalo en un momento.';

  @override
  String get dailyTitle => 'Bono diario';

  @override
  String get dailyReady => '¡Listo!';

  @override
  String get dailyComeBack => 'Vuelve mañana';

  @override
  String dailyDay(int day) {
    return 'Día $day';
  }

  @override
  String get dailyClaim => 'Reclamar';

  @override
  String get dailyHint => 'Vuelve cada día: el bono crece hasta el día 7.';

  @override
  String get dailyDoubleCta => 'Ver anuncio y duplicar';

  @override
  String get shopTabSkins => 'Estilos';

  @override
  String get removeAdsTitle => 'Sin anuncios';

  @override
  String get removeAdsBody =>
      'Quita los banners y los anuncios entre partidas, para siempre. Los anuncios con recompensa siguen siendo opcionales.';

  @override
  String get removeAdsOwned => 'Anuncios eliminados. ¡Gracias!';

  @override
  String get storeLoading => 'Cargando la tienda...';

  @override
  String get storeUnavailable =>
      'Las compras no están disponibles ahora. Revisa tu conexión e inténtalo más tarde.';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get purchasePending =>
      'Pago pendiente. La compra llega en cuanto Google Play la confirme.';

  @override
  String get purchaseFailed => 'La compra no se completó.';

  @override
  String get starterTitle => 'Paquete de bienvenida';

  @override
  String get starterSee => 'Ver oferta';

  @override
  String get notNow => 'Ahora no';

  @override
  String get challengeTitle => 'Desafío del día';

  @override
  String challengeMoves(int used, int limit) {
    return '$used/$limit';
  }

  @override
  String challengeOverLimit(int limit) {
    return 'Pasaste de $limit jugadas: sin premio esta vez';
  }

  @override
  String challengeWon(int coins) {
    return '¡Desafío del día completado! +$coins monedas';
  }

  @override
  String challengeLate(int limit) {
    return 'Ganaste, pero pasaste de $limit jugadas. ¡Inténtalo otra vez!';
  }

  @override
  String get challengeAlreadyDone =>
      'El desafío de hoy ya está completado. ¡Vuelve mañana!';

  @override
  String get challengeDoneHome => '¡Hecho! Vuelve mañana';

  @override
  String get shareVictory => 'Compartir';

  @override
  String get shareMessage => '¡Acabo de ganar en Tic Tac Verse! ¿Me ganas?';

  @override
  String get tutorialTitle => 'Cómo funciona el Súper Tres en Raya';

  @override
  String get tutorialIntro =>
      'Hay 9 tableros pequeños dentro de uno grande. Gana uno pequeño para quedártelo, y consigue 3 en línea para ganar.';

  @override
  String get tutorialTapFirst =>
      'Tu turno. Toca la casilla que brilla: la esquina superior derecha del tablero del medio.';

  @override
  String get tutorialSent =>
      'Jugaste en la esquina superior derecha, así que el rival ahora debe jugar en el TABLERO superior derecho. La casilla que eliges decide dónde juega el otro.';

  @override
  String get tutorialTapSecond =>
      'El rival jugó en la casilla del centro, así que ahora TÚ vas al tablero del medio. Toca la casilla que brilla.';

  @override
  String get tutorialFinal =>
      '¡Eso es todo! Si te mandan a un tablero ya ganado o lleno, puedes jugar en cualquiera. Piensa por adelantado: cada jugada manda al rival a algún sitio.';

  @override
  String get tutorialSkip => 'Saltar';

  @override
  String get tutorialNext => 'Siguiente';

  @override
  String get tutorialPlay => '¡A jugar!';

  @override
  String get tutorialReplay => 'Ver el tutorial';

  @override
  String get shopTabBoards => 'Tableros';

  @override
  String get boardsSubtitle =>
      'Cambia los colores del tablero en todos los modos.';

  @override
  String get themeNeonGrid => 'Neón';

  @override
  String get themeSunset => 'Atardecer';

  @override
  String get themeOcean => 'Océano';

  @override
  String get themeEmerald => 'Esmeralda';

  @override
  String get themeRoyal => 'Realeza';

  @override
  String challengeGoalShort(int limit) {
    return 'Gana el Súper en $limit jugadas';
  }

  @override
  String get shopTabPremium => 'Premium';

  @override
  String get starterBody =>
      'Sin anuncios para siempre + el estilo Aurora, el más cuidado del juego.';

  @override
  String get starterBadge => '+ AURORA';

  @override
  String get collectionTitle => 'Colección completa';

  @override
  String get collectionBody =>
      'Todos los estilos y temas de tablero, los de hoy y los que vengan, y sin anuncios.';

  @override
  String get collectionOwned => 'Todo desbloqueado. ¡Gracias!';

  @override
  String get purchaseUnlocked => '¡Desbloqueado! Disfrútalo.';

  @override
  String needMoreCoinsPremium(int amount) {
    return 'Te faltan $amount monedas. Juega para ganarlas o llévate todo con la Colección completa.';
  }

  @override
  String get onlineButton => 'Desafiar a un amigo en línea';

  @override
  String get onlineTitle => 'En línea con amigos';

  @override
  String get onlineIntro =>
      'Súper Tres en Raya contra un amigo, cada uno en su celular. Jueguen al mismo tiempo o cuando cada uno pueda.';

  @override
  String get onlineCreate => 'Crear invitación';

  @override
  String get onlineJoinTitle => 'Recibí un código';

  @override
  String get onlineCodeHint => '6 letras, ej.: K7P2QX';

  @override
  String get onlineJoin => 'Entrar';

  @override
  String get onlineCodeInvalid => 'Código inválido. Revisa las 6 letras.';

  @override
  String get onlineYourMatches => 'Tus partidas';

  @override
  String get onlineNoMatches =>
      'Aún no hay partidas. Crea una invitación y envíala a un amigo.';

  @override
  String onlineStats(int wins, int losses, int draws) {
    return '$wins G · $losses P · $draws E';
  }

  @override
  String onlineYouAre(String handle) {
    return 'Eres $handle';
  }

  @override
  String get onlineStatusWaiting => 'Esperando a tu amigo';

  @override
  String get onlineStatusYourTurn => '¡Tu turno!';

  @override
  String get onlineStatusTheirTurn => 'Turno del amigo';

  @override
  String get onlineStatusWon => 'Ganaste';

  @override
  String get onlineStatusLost => 'Perdiste';

  @override
  String get onlineStatusDraw => 'Empate';

  @override
  String get onlineStatusExpired => 'Cerrada';

  @override
  String get onlineShareInvite => 'Enviar invitación';

  @override
  String onlineShareMessage(String link, String code) {
    return '¡Te desafío al Súper Tres en Raya! Toca el enlace para jugar conmigo: $link (código $code)';
  }

  @override
  String get onlineWaitingBody =>
      'Envía el enlace a un amigo. La partida empieza en cuanto entre.';

  @override
  String onlineCodeLabel(String code) {
    return 'Código: $code';
  }

  @override
  String get onlineCancelInvite => 'Cancelar invitación';

  @override
  String get onlineResign => 'Rendirse';

  @override
  String get onlineResignConfirm =>
      '¿Rendirte en esta partida? Cuenta como derrota.';

  @override
  String onlineYouPlayAs(String symbol) {
    return 'Juegas con $symbol';
  }

  @override
  String get onlineReconnecting => 'Sin conexión. Intentando de nuevo...';

  @override
  String get onlineError =>
      'No se pudo conectar con el servidor. Revisa tu internet e inténtalo de nuevo.';

  @override
  String get onlineTaken => 'Esta partida ya tiene dos jugadores.';

  @override
  String get onlineExpired =>
      'Esta invitación expiró. Pide una nueva a tu amigo.';

  @override
  String get onlineNotFound =>
      'No encontramos esa invitación. Revisa el código.';

  @override
  String get onlineOwnMatch => 'Esta invitación es tuya. Envíala a un amigo.';

  @override
  String get onlineTooMany =>
      'Tienes demasiadas partidas abiertas. Termina o cancela alguna.';

  @override
  String get onlineRematch => 'Revancha';

  @override
  String get onlineRematchOffered => '¡Tu amigo quiere la revancha!';

  @override
  String get onlineWinTitle => '¡Ganaste!';

  @override
  String get onlineLossTitle => 'Ganó tu amigo';

  @override
  String get onlineDrawTitle => '¡Empate!';

  @override
  String get onlineEndResignWin => 'Tu amigo se rindió.';

  @override
  String get onlineEndResignLoss => 'Te rendiste.';

  @override
  String get onlineEndTimeoutWin => 'Tu amigo no jugó a tiempo.';

  @override
  String get onlineEndTimeoutLoss => 'No jugaste a tiempo.';

  @override
  String get onlineEndAbandon => 'Tu amigo dejó el modo en línea.';

  @override
  String get onlineTurnRule =>
      'Cada uno tiene hasta 3 días para jugar su turno.';

  @override
  String get onlineDeleteData => 'Borrar mis datos en línea';

  @override
  String get onlineDeleteConfirm =>
      'Esto borra del servidor tus partidas y estadísticas en línea. Las partidas en curso cuentan como derrota.';

  @override
  String get onlineDeleteDone => 'Datos en línea borrados.';

  @override
  String get onlinePrivacyNote =>
      'El modo en línea usa un número anónimo. Sin nombre, correo ni inicio de sesión.';

  @override
  String get onlineBackToLobby => 'Partidas';

  @override
  String get cancelLabel => 'Cancelar';

  @override
  String get confirmLabel => 'Confirmar';

  @override
  String get onlineVsShort => 'vs';

  @override
  String get retryLabel => 'Reintentar';
}

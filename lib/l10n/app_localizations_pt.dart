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
  String get modeClassicSubtitle =>
      'Regras tradicionais para partidas rápidas.';

  @override
  String get modeShiftTitle => 'Modo Shift';

  @override
  String get modeShiftSubtitle =>
      'Só 3 peças por jogador - a mais antiga some.';

  @override
  String get modeChaosTitle => 'Modo Caos';

  @override
  String get modeChaosSubtitle =>
      'A cada poucas rodadas, um evento muda as regras.';

  @override
  String get modeUltimateTitle => 'Mini Supremo';

  @override
  String get modeUltimateSubtitle =>
      'Vença sob uma condição especial que muda a cada partida.';

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
  String get ultimateLimitedMoves =>
      'Vença dentro de um número limitado de jogadas.';

  @override
  String get movesRemaining => 'Jogadas restantes';

  @override
  String get adsBannerPlacement => 'Banners aparecem apenas na tela de jogo.';

  @override
  String get adInterstitialHint =>
      'Intersticiais aparecem após algumas partidas.';

  @override
  String get gameModeLabel => 'Modo de jogo';

  @override
  String get helpTitle => 'Ajuda';

  @override
  String get tapToClaim => 'Toque em qualquer célula para capturá-la';

  @override
  String get closeLabel => 'Fechar';

  @override
  String get winInstruction => 'Alinhe três para vencer.';

  @override
  String get takeTurnCta => 'Faça sua jogada e ilumine o tabuleiro';

  @override
  String get playLabel => 'Jogar';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageBengali => 'বাংলা';

  @override
  String get languageNepali => 'नेपाली';

  @override
  String get langSuggestTitle => 'Agora disponível no seu idioma!';

  @override
  String get langSuggestAccept => 'Trocar de idioma';

  @override
  String get langSuggestKeep => 'Continuar em português';

  @override
  String get audioLabel => 'Áudio';

  @override
  String get muteLabel => 'Silenciar';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get difficultyLabel => 'Dificuldade';

  @override
  String get difficultyEasy => 'Fácil';

  @override
  String get difficultyMedium => 'Médio';

  @override
  String get difficultyHard => 'Impossível';

  @override
  String get statsTitle => 'Estatísticas';

  @override
  String get statsTotalMatches => 'Partidas jogadas';

  @override
  String get statsVsCpu => 'Contra a CPU';

  @override
  String get statsWins => 'Vitórias';

  @override
  String get statsLosses => 'Derrotas';

  @override
  String get statsDraws => 'Empates';

  @override
  String get statsStreak => 'Sequência de vitórias';

  @override
  String get statsBestStreak => 'Melhor sequência';

  @override
  String get statsByMode => 'Por modo';

  @override
  String get statsEmpty => 'Jogue uma partida para começar suas estatísticas!';

  @override
  String get updatesLabel => 'Atualizações';

  @override
  String get checkUpdatesLabel => 'Buscar atualizações';

  @override
  String get upToDateMessage => 'Você já está na versão mais recente!';

  @override
  String get updateFailedMessage =>
      'Não foi possível verificar atualizações. Tente de novo mais tarde.';

  @override
  String get modeUltimate2Title => 'Super Jogo da Velha';

  @override
  String get modeUltimate2Subtitle =>
      '9 tabuleiros em um. Sua jogada define onde o rival joga.';

  @override
  String get ultimate2FreeMove => 'Jogada livre: qualquer tabuleiro';

  @override
  String get ultimate2PlayIn => 'Jogue no tabuleiro aceso';

  @override
  String get ultimate2Help =>
      'Cada casa do tabuleirão guarda um jogo da velha pequeno. A casa que você marca dentro de um tabuleiro pequeno manda o adversário para o tabuleiro correspondente. Vença um tabuleiro pequeno para conquistar a casa dele no tabuleirão - faça três casas conquistadas em linha para vencer a partida. Se o destino estiver fechado, a jogada é livre.';

  @override
  String get playVsCpuBig => 'Jogar contra a máquina';

  @override
  String get playWithFriend => 'Jogar com um amigo';

  @override
  String get chooseModeTitle => 'Escolha o modo';

  @override
  String get achievementsTitle => 'Conquistas';

  @override
  String achievementsProgress(int unlocked, int total) {
    return '$unlocked de $total desbloqueadas';
  }

  @override
  String get achievementsEmpty =>
      'Jogue uma partida para começar a desbloquear conquistas.';

  @override
  String levelLabel(int level) {
    return 'Nível $level';
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
  String get achUnlockedToast => 'Conquista desbloqueada!';

  @override
  String get doubleXpCta => 'Ver anúncio e dobrar XP e moedas';

  @override
  String get doubleXpDone => 'XP e moedas dobrados!';

  @override
  String get doubleXpUnavailable =>
      'O anúncio não carregou. Tente na próxima partida.';

  @override
  String levelUpToast(int level) {
    return 'Nível $level alcançado!';
  }

  @override
  String get achFirstWinTitle => 'Primeira vitória';

  @override
  String get achFirstWinDesc => 'Vença a máquina pela primeira vez';

  @override
  String get achWins10Title => 'Vitorioso';

  @override
  String get achWins50Title => 'Dominante';

  @override
  String get achWins200Title => 'Lenda';

  @override
  String achDescWins(int count) {
    return 'Vença $count partidas contra a máquina';
  }

  @override
  String get achStreak3Title => 'Esquentando';

  @override
  String get achStreak7Title => 'Pegando fogo';

  @override
  String get achStreak15Title => 'Imparável';

  @override
  String achDescStreak(int count) {
    return 'Vença $count partidas seguidas';
  }

  @override
  String get achHardWinTitle => 'Nem tão impossível';

  @override
  String get achHardWinDesc => 'Vença a máquina no Impossível';

  @override
  String get achAllModesTitle => 'Explorador';

  @override
  String get achAllModesDesc => 'Jogue os 5 modos de jogo';

  @override
  String get achUltimateWinsTitle => 'Mestre do tabuleirão';

  @override
  String achDescUltimateWins(int count) {
    return 'Vença $count partidas no Super Jogo da Velha';
  }

  @override
  String get achDaily3Title => 'Rotina';

  @override
  String get achDaily7Title => 'Semana cheia';

  @override
  String get achDaily30Title => 'Dedicado';

  @override
  String achDescDaily(int count) {
    return 'Jogue $count dias seguidos';
  }

  @override
  String get achFastWinTitle => 'Relâmpago';

  @override
  String get achFastWinDesc => 'Vença o Clássico em apenas 3 jogadas';

  @override
  String get achMatches50Title => 'Veterano';

  @override
  String get achMatches250Title => 'Maratonista';

  @override
  String achDescMatches(int count) {
    return 'Jogue $count partidas';
  }

  @override
  String get playGamesOpen => 'Ver no Play Games';

  @override
  String get hapticsLabel => 'Vibração';

  @override
  String get youWinTitle => 'Você venceu!';

  @override
  String get cpuWinsTitle => 'A máquina venceu';

  @override
  String playerWinsTitle(String symbol) {
    return '$symbol venceu!';
  }

  @override
  String winStreakChip(int count) {
    return '$count vitórias seguidas!';
  }

  @override
  String dailyStreakChip(int count) {
    return '$count dias seguidos';
  }

  @override
  String get newRecordChip => 'Novo recorde!';

  @override
  String get cpuThinking => 'Pensando...';

  @override
  String get yourTurn => 'Sua vez';

  @override
  String get updateAvailableTitle => 'Nova versão disponível';

  @override
  String get updateAvailableBody =>
      'Atualize agora para ter as últimas melhorias e correções.';

  @override
  String get updateNowLabel => 'Atualizar';

  @override
  String get updateLaterLabel => 'Depois';

  @override
  String get coinsLabel => 'Moedas';

  @override
  String coinsGained(int amount) {
    return '+$amount moedas';
  }

  @override
  String get shopTitle => 'Visual das peças';

  @override
  String get shopSubtitle =>
      'Ganhe moedas jogando e mude o visual do X e do O.';

  @override
  String get shopEquip => 'Usar';

  @override
  String get shopEquipped => 'Em uso';

  @override
  String get shopPurchased => 'Visual novo desbloqueado!';

  @override
  String get skinAurora => 'Aurora';

  @override
  String get skinNeon => 'Neon';

  @override
  String get skinFireIce => 'Fogo e gelo';

  @override
  String get skinCandy => 'Bala';

  @override
  String get skinGold => 'Ouro e prata';

  @override
  String get skinGalaxy => 'Galáxia';

  @override
  String adCoinsCta(int amount) {
    return 'Ver anúncio: +$amount moedas';
  }

  @override
  String adCoinsLeft(int count) {
    return 'Restam $count hoje';
  }

  @override
  String get adCoinsSoldOut => 'Volte amanhã para mais moedas por anúncio.';

  @override
  String get adUnavailable =>
      'Nenhum anúncio disponível agora. Tente de novo daqui a pouco.';

  @override
  String get dailyTitle => 'Bônus diário';

  @override
  String get dailyReady => 'Resgate já!';

  @override
  String get dailyComeBack => 'Volte amanhã';

  @override
  String dailyDay(int day) {
    return 'Dia $day';
  }

  @override
  String get dailyClaim => 'Resgatar';

  @override
  String get dailyHint => 'Volte todo dia: o bônus cresce até o dia 7.';

  @override
  String get dailyDoubleCta => 'Ver anúncio e dobrar';

  @override
  String get shopTabSkins => 'Visuais';

  @override
  String get shopTabCoins => 'Moedas';

  @override
  String coinPackTitle(int amount) {
    return '$amount moedas';
  }

  @override
  String get coinPackBestValue => 'Melhor oferta';

  @override
  String get removeAdsTitle => 'Sem anúncios';

  @override
  String get removeAdsBody =>
      'Tira os banners e os anúncios entre partidas, para sempre. Anúncios com recompensa continuam opcionais.';

  @override
  String get removeAdsOwned => 'Anúncios removidos. Obrigado!';

  @override
  String get storeLoading => 'Carregando a loja...';

  @override
  String get storeUnavailable =>
      'As compras não estão disponíveis agora. Confira a conexão e tente mais tarde.';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get purchasePending =>
      'Pagamento pendente. A compra entra assim que o Google Play confirmar.';

  @override
  String get purchaseFailed => 'A compra não foi concluída.';

  @override
  String needMoreCoins(int amount) {
    return 'Faltam $amount moedas para este visual.';
  }
}

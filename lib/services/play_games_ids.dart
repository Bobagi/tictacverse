/// Ids do Play Games Services.
///
/// O Play Games gera ids opacos próprios (algo como `CgkI8...EAIQAQ`) para cada
/// conquista e placar, diferentes dos nossos ids estáveis do catálogo. Este
/// arquivo é a tradução entre os dois mundos e é a **única** peça que falta para
/// ligar a integração.
///
/// Enquanto os mapas estiverem vazios, [playGamesConfigured] é falso e toda a
/// ponte vira no-op: o app se comporta exatamente como antes, com a progressão
/// funcionando 100% local. Ou seja, publicar assim é seguro.
///
/// Para preencher: depois que o jogo existir no Play Console (Serviços de jogos
/// do Play), as conquistas podem ser criadas pela Publishing API do PGS, que
/// devolve o id de cada uma. Ver o passo a passo em `docs/play-games.md`.
library;

/// Nosso id do catálogo (`lib/models/achievement.dart`) -> id no Play Games.
///
/// Uma conquista ausente daqui simplesmente não é espelhada, então dá para
/// ligar o mapa aos poucos sem quebrar nada.
const Map<String, String> playGamesAchievementIds = <String, String>{};

/// Placar de nível. Vazio = não envia pontuação.
const String playGamesLevelLeaderboardId = '';

/// A integração só liga quando existe pelo menos uma conquista mapeada.
bool get playGamesConfigured => playGamesAchievementIds.isNotEmpty;

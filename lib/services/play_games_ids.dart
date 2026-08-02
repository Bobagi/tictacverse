/// Ids do Play Games Services.
///
/// GERADO por `tool/play_games_setup.py` a partir do catalogo em
/// `lib/models/achievement.dart` e das traducoes das ARB. Nao editar a mao:
/// rode a ferramenta de novo depois de acrescentar uma conquista.
///
/// Com os mapas vazios a integracao inteira vira no-op e o app se comporta
/// como se o Play Games nao existisse, o que torna seguro publicar antes de
/// o projeto do PGS estar pronto.
library;

/// Nosso id do catalogo -> id no Play Games.
const Map<String, String> playGamesAchievementIds = <String, String>{
  'first_win': 'CgkI-6LP3ckeEAIQAQ',
  'wins_10': 'CgkI-6LP3ckeEAIQAg',
  'wins_50': 'CgkI-6LP3ckeEAIQAw',
  'wins_200': 'CgkI-6LP3ckeEAIQBA',
  'streak_3': 'CgkI-6LP3ckeEAIQBQ',
  'streak_7': 'CgkI-6LP3ckeEAIQBg',
  'streak_15': 'CgkI-6LP3ckeEAIQBw',
  'hard_win': 'CgkI-6LP3ckeEAIQCA',
  'all_modes': 'CgkI-6LP3ckeEAIQCQ',
  'ultimate_wins_10': 'CgkI-6LP3ckeEAIQCg',
  'daily_3': 'CgkI-6LP3ckeEAIQCw',
  'daily_7': 'CgkI-6LP3ckeEAIQDA',
  'daily_30': 'CgkI-6LP3ckeEAIQDQ',
  'fast_win': 'CgkI-6LP3ckeEAIQDg',
  'matches_50': 'CgkI-6LP3ckeEAIQDw',
  'matches_250': 'CgkI-6LP3ckeEAIQEA',
};

/// Placar de nivel. Vazio = nao envia pontuacao.
const String playGamesLevelLeaderboardId = 'CgkI-6LP3ckeEAIQEQ';

/// A integracao so liga quando existe pelo menos uma conquista mapeada.
bool get playGamesConfigured => playGamesAchievementIds.isNotEmpty;

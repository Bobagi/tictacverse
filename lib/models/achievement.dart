import 'package:tictacverse/l10n/app_localizations.dart';

import 'progress_state.dart';

/// Faixa da conquista. Define a cor do selo e o XP de bônus ao desbloquear.
enum AchievementTier { bronze, silver, gold }

extension AchievementTierXp on AchievementTier {
  int get xpReward {
    switch (this) {
      case AchievementTier.bronze:
        return 50;
      case AchievementTier.silver:
        return 120;
      case AchievementTier.gold:
        return 300;
    }
  }
}

/// Uma conquista do catálogo.
///
/// O [id] é estável e serve como chave de persistência local **e** como o id
/// da conquista no Play Games Services (fase 2), então nunca deve ser
/// renomeado depois de publicado.
///
/// [progressOf] é lógica pura sobre o [ProgressState]: não conhece a UI, o que
/// permite testar o catálogo inteiro sem widget e reavaliar tudo do zero
/// quando o catálogo cresce (conquistas novas já nascem com o progresso certo
/// para quem joga há tempo).
class AchievementDefinition {
  AchievementDefinition({
    required this.id,
    required this.tier,
    required this.target,
    required this.titleBuilder,
    required this.descriptionBuilder,
    required this.progressOf,
  });

  final String id;
  final AchievementTier tier;
  final int target;
  final String Function(AppLocalizations localization) titleBuilder;
  final String Function(AppLocalizations localization) descriptionBuilder;
  final int Function(ProgressState state) progressOf;

  String title(AppLocalizations localization) => titleBuilder(localization);

  String description(AppLocalizations localization) =>
      descriptionBuilder(localization);

  /// Progresso limitado à meta, para a barra da UI não estourar.
  int progress(ProgressState state) {
    final int raw = progressOf(state);
    return raw > target ? target : raw;
  }

  bool isUnlockedBy(ProgressState state) => progressOf(state) >= target;
}

/// Catálogo de conquistas.
///
/// Vitórias, sequência e "impossível" contam **somente contra a máquina**: no
/// modo dois jogadores no mesmo aparelho seria trivial farmar vitória, e essas
/// contagens vão para o placar do Play Games na fase 2. Partidas, modos
/// jogados e dias seguidos contam em qualquer modo.
List<AchievementDefinition> createAchievements() => <AchievementDefinition>[
      AchievementDefinition(
        id: 'first_win',
        tier: AchievementTier.bronze,
        target: 1,
        titleBuilder: (AppLocalizations l) => l.achFirstWinTitle,
        descriptionBuilder: (AppLocalizations l) => l.achFirstWinDesc,
        progressOf: (ProgressState s) => s.cpuWins,
      ),
      AchievementDefinition(
        id: 'wins_10',
        tier: AchievementTier.bronze,
        target: 10,
        titleBuilder: (AppLocalizations l) => l.achWins10Title,
        descriptionBuilder: (AppLocalizations l) => l.achDescWins(10),
        progressOf: (ProgressState s) => s.cpuWins,
      ),
      AchievementDefinition(
        id: 'wins_50',
        tier: AchievementTier.silver,
        target: 50,
        titleBuilder: (AppLocalizations l) => l.achWins50Title,
        descriptionBuilder: (AppLocalizations l) => l.achDescWins(50),
        progressOf: (ProgressState s) => s.cpuWins,
      ),
      AchievementDefinition(
        id: 'wins_200',
        tier: AchievementTier.gold,
        target: 200,
        titleBuilder: (AppLocalizations l) => l.achWins200Title,
        descriptionBuilder: (AppLocalizations l) => l.achDescWins(200),
        progressOf: (ProgressState s) => s.cpuWins,
      ),
      AchievementDefinition(
        id: 'streak_3',
        tier: AchievementTier.bronze,
        target: 3,
        titleBuilder: (AppLocalizations l) => l.achStreak3Title,
        descriptionBuilder: (AppLocalizations l) => l.achDescStreak(3),
        progressOf: (ProgressState s) => s.bestWinStreak,
      ),
      AchievementDefinition(
        id: 'streak_7',
        tier: AchievementTier.silver,
        target: 7,
        titleBuilder: (AppLocalizations l) => l.achStreak7Title,
        descriptionBuilder: (AppLocalizations l) => l.achDescStreak(7),
        progressOf: (ProgressState s) => s.bestWinStreak,
      ),
      AchievementDefinition(
        id: 'streak_15',
        tier: AchievementTier.gold,
        target: 15,
        titleBuilder: (AppLocalizations l) => l.achStreak15Title,
        descriptionBuilder: (AppLocalizations l) => l.achDescStreak(15),
        progressOf: (ProgressState s) => s.bestWinStreak,
      ),
      AchievementDefinition(
        id: 'hard_win',
        tier: AchievementTier.gold,
        target: 1,
        titleBuilder: (AppLocalizations l) => l.achHardWinTitle,
        descriptionBuilder: (AppLocalizations l) => l.achHardWinDesc,
        progressOf: (ProgressState s) => s.hardWins,
      ),
      AchievementDefinition(
        id: 'all_modes',
        tier: AchievementTier.silver,
        target: 5,
        titleBuilder: (AppLocalizations l) => l.achAllModesTitle,
        descriptionBuilder: (AppLocalizations l) => l.achAllModesDesc,
        progressOf: (ProgressState s) => s.modesPlayed.length,
      ),
      AchievementDefinition(
        id: 'ultimate_wins_10',
        tier: AchievementTier.silver,
        target: 10,
        titleBuilder: (AppLocalizations l) => l.achUltimateWinsTitle,
        descriptionBuilder: (AppLocalizations l) => l.achDescUltimateWins(10),
        progressOf: (ProgressState s) => s.ultimateWins,
      ),
      AchievementDefinition(
        id: 'daily_3',
        tier: AchievementTier.bronze,
        target: 3,
        titleBuilder: (AppLocalizations l) => l.achDaily3Title,
        descriptionBuilder: (AppLocalizations l) => l.achDescDaily(3),
        progressOf: (ProgressState s) => s.bestDailyStreak,
      ),
      AchievementDefinition(
        id: 'daily_7',
        tier: AchievementTier.silver,
        target: 7,
        titleBuilder: (AppLocalizations l) => l.achDaily7Title,
        descriptionBuilder: (AppLocalizations l) => l.achDescDaily(7),
        progressOf: (ProgressState s) => s.bestDailyStreak,
      ),
      AchievementDefinition(
        id: 'daily_30',
        tier: AchievementTier.gold,
        target: 30,
        titleBuilder: (AppLocalizations l) => l.achDaily30Title,
        descriptionBuilder: (AppLocalizations l) => l.achDescDaily(30),
        progressOf: (ProgressState s) => s.bestDailyStreak,
      ),
      AchievementDefinition(
        id: 'fast_win',
        tier: AchievementTier.silver,
        target: 1,
        titleBuilder: (AppLocalizations l) => l.achFastWinTitle,
        descriptionBuilder: (AppLocalizations l) => l.achFastWinDesc,
        progressOf: (ProgressState s) => s.hasFastWin ? 1 : 0,
      ),
      AchievementDefinition(
        id: 'matches_50',
        tier: AchievementTier.bronze,
        target: 50,
        titleBuilder: (AppLocalizations l) => l.achMatches50Title,
        descriptionBuilder: (AppLocalizations l) => l.achDescMatches(50),
        progressOf: (ProgressState s) => s.matches,
      ),
      AchievementDefinition(
        id: 'matches_250',
        tier: AchievementTier.gold,
        target: 250,
        titleBuilder: (AppLocalizations l) => l.achMatches250Title,
        descriptionBuilder: (AppLocalizations l) => l.achDescMatches(250),
        progressOf: (ProgressState s) => s.matches,
      ),
    ];

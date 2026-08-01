import 'dart:math' as math;

import '../models/achievement.dart';
import '../models/cpu_difficulty.dart';
import '../models/game_mode.dart';
import '../models/progress_state.dart';

/// O que aconteceu numa partida, do ponto de vista da progressão.
class MatchOutcome {
  const MatchOutcome({
    required this.mode,
    required this.vsCpu,
    required this.difficulty,
    required this.humanWon,
    required this.isDraw,
    this.humanMoveCount,
  });

  final GameModeType mode;
  final bool vsCpu;
  final CpuDifficulty difficulty;

  /// No modo contra a máquina o humano é sempre o X. No modo dois jogadores
  /// isto é sempre `false`: vitória local não conta para XP de vitória nem
  /// para as conquistas de vitória (ver nota no catálogo).
  final bool humanWon;
  final bool isDraw;

  /// Jogadas feitas pelo humano até o fim. Só é informado no Clássico, onde a
  /// contagem é inequívoca (no Shift as peças sao removidas e no Super Jogo da
  /// Velha o tabuleiro é outro).
  final int? humanMoveCount;
}

/// Efeito de uma partida na progressão, para a UI mostrar o que mudou.
class ProgressionResult {
  const ProgressionResult({
    required this.xpGained,
    required this.levelBefore,
    required this.levelAfter,
    required this.newlyUnlocked,
  });

  final int xpGained;
  final int levelBefore;
  final int levelAfter;
  final List<AchievementDefinition> newlyUnlocked;

  bool get leveledUp => levelAfter > levelBefore;
  bool get hasNews => leveledUp || newlyUnlocked.isNotEmpty;
}

/// Regras de XP, nível e desbloqueio de conquistas.
///
/// Tudo aqui é função pura sobre [ProgressState] mais um relógio injetável,
/// então o comportamento é testável sem plugin, sem widget e sem esperar a
/// virada do dia.
class ProgressionEngine {
  ProgressionEngine({List<AchievementDefinition>? catalog})
      : catalog = catalog ?? createAchievements();

  final List<AchievementDefinition> catalog;

  /// Jogadas mínimas para vencer o Clássico: o X fecha uma linha na 3ª marca.
  static const int fastWinMoves = 3;

  /// XP acumulado necessário para alcançar [level].
  ///
  /// O custo do nível N para o N+1 é `80 + 40 * (N - 1)`, ou seja, 80, 120,
  /// 160, 200… Curva quadratica suave: os primeiros níveis caem rápido (a
  /// recompensa aparece já na primeira sessão) e os altos viram meta longa.
  static int xpToReachLevel(int level) {
    if (level <= 1) {
      return 0;
    }
    final int n = level - 1;
    return 80 * n + 20 * n * (n - 1);
  }

  /// Nível correspondente a [xp]. Começa em 1.
  static int levelForXp(int xp) {
    if (xp <= 0) {
      return 1;
    }
    // Inverte 20n² + 60n = xp e corrige com passo inteiro, porque a raiz em
    // ponto flutuante erra por 1 exatamente nos limites de nível.
    int level = ((-60 + math.sqrt(3600 + 80 * xp)) / 40).floor() + 1;
    if (level < 1) {
      level = 1;
    }
    while (xpToReachLevel(level + 1) <= xp) {
      level += 1;
    }
    while (level > 1 && xpToReachLevel(level) > xp) {
      level -= 1;
    }
    return level;
  }

  /// XP dentro do nível atual e quanto o nível inteiro custa, para a barra.
  static (int into, int span) levelBar(int xp) {
    final int level = levelForXp(xp);
    final int floor = xpToReachLevel(level);
    final int ceiling = xpToReachLevel(level + 1);
    return (xp - floor, ceiling - floor);
  }

  /// XP ganho por concluir uma partida.
  static int xpForMatch(MatchOutcome outcome) {
    int xp = 10;
    if (outcome.humanWon) {
      xp += 25;
    } else if (outcome.isDraw) {
      xp += 5;
    }
    if (outcome.vsCpu) {
      switch (outcome.difficulty) {
        case CpuDifficulty.easy:
          break;
        case CpuDifficulty.medium:
          xp += 5;
        case CpuDifficulty.hard:
          xp += 12;
      }
    }
    // O Super Jogo da Velha é o carro-chefe: rende 50% a mais para puxar o
    // jogador para o modo que diferencia o app.
    if (outcome.mode == GameModeType.ultimate2) {
      xp = (xp * 1.5).round();
    }
    return xp;
  }

  /// Aplica uma partida ao [state], mutando-o, e devolve o que mudou.
  ProgressionResult applyMatch(
    ProgressState state,
    MatchOutcome outcome,
    DateTime now,
  ) {
    final int levelBefore = levelForXp(state.xp);
    final int xpBefore = state.xp;

    state.matches += 1;
    state.modesPlayed.add(outcome.mode);
    _applyDailyStreak(state, now);

    if (outcome.vsCpu) {
      if (outcome.humanWon) {
        state.cpuWins += 1;
        state.currentWinStreak += 1;
        if (state.currentWinStreak > state.bestWinStreak) {
          state.bestWinStreak = state.currentWinStreak;
        }
        if (outcome.mode == GameModeType.ultimate2) {
          state.ultimateWins += 1;
        }
        if (outcome.difficulty == CpuDifficulty.hard) {
          state.hardWins += 1;
        }
        if (outcome.mode == GameModeType.classic &&
            outcome.humanMoveCount != null &&
            outcome.humanMoveCount! <= fastWinMoves) {
          state.hasFastWin = true;
        }
      } else {
        state.currentWinStreak = 0;
      }
    }

    state.xp += xpForMatch(outcome);

    // Reavalia o catálogo inteiro (não só o que a partida tocou) para que uma
    // conquista adicionada numa versão futura já nasça desbloqueada para quem
    // ha muito tempo cumpre o requisito.
    final List<AchievementDefinition> unlocked = _collectNewlyUnlocked(state);
    for (final AchievementDefinition achievement in unlocked) {
      state.unlockedAchievements.add(achievement.id);
      state.xp += achievement.tier.xpReward;
    }

    return ProgressionResult(
      xpGained: state.xp - xpBefore,
      levelBefore: levelBefore,
      levelAfter: levelForXp(state.xp),
      newlyUnlocked: unlocked,
    );
  }

  /// Desbloqueios pendentes sem registrar partida. Usado no boot para
  /// reconciliar o estado depois de uma atualização que trouxe conquistas
  /// novas ou que mudou uma meta.
  List<AchievementDefinition> reconcile(ProgressState state) {
    final List<AchievementDefinition> unlocked = _collectNewlyUnlocked(state);
    for (final AchievementDefinition achievement in unlocked) {
      state.unlockedAchievements.add(achievement.id);
      state.xp += achievement.tier.xpReward;
    }
    return unlocked;
  }

  List<AchievementDefinition> _collectNewlyUnlocked(ProgressState state) {
    return <AchievementDefinition>[
      for (final AchievementDefinition achievement in catalog)
        if (!state.unlockedAchievements.contains(achievement.id) &&
            achievement.isUnlockedBy(state))
          achievement,
    ];
  }

  void _applyDailyStreak(ProgressState state, DateTime now) {
    final String today = dayKey(now);
    final String? last = state.lastPlayedDay;
    if (last == today) {
      return;
    }
    if (last != null && last == _yesterdayKey(now)) {
      state.dailyStreak += 1;
    } else {
      state.dailyStreak = 1;
    }
    state.lastPlayedDay = today;
    if (state.dailyStreak > state.bestDailyStreak) {
      state.bestDailyStreak = state.dailyStreak;
    }
  }

  /// Chave do dia no calendário local, `yyyy-mm-dd`.
  static String dayKey(DateTime moment) {
    final String month = moment.month.toString().padLeft(2, '0');
    final String day = moment.day.toString().padLeft(2, '0');
    return '${moment.year}-$month-$day';
  }

  /// O dia anterior ao de [now] no calendário local.
  ///
  /// A subtração é feita em UTC de propósito: subtrair 24 h de um `DateTime`
  /// local pula ou repete o dia quando o fuso tem horário de verão, e aí a
  /// sequência diária quebraria sozinha duas vezes por ano.
  static String _yesterdayKey(DateTime now) {
    final DateTime previous = DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    return dayKey(previous);
  }
}

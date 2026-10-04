import 'dart:math';

import '../models/cpu_difficulty.dart';
import '../models/progress_state.dart';
import 'progression_engine.dart';

/// O desafio de um dia: vencer a máquina no Super Jogo da Velha em até
/// [moveLimit] jogadas suas, na dificuldade [difficulty].
class DailyChallenge {
  const DailyChallenge({
    required this.day,
    required this.moveLimit,
    required this.difficulty,
  });

  /// `yyyy-mm-dd` local.
  final String day;
  final int moveLimit;
  final CpuDifficulty difficulty;
}

/// Desafio diário do carro-chefe: um motivo para voltar todo dia.
///
/// O desafio do dia é o mesmo para todo mundo (sorteado pela data), então dá
/// para comparar com amigo. Paga uma vez por dia, e dias seguidos concluídos
/// aumentam o prêmio. Mesma filosofia dos outros motores: função pura com
/// relógio injetado; quem persiste é a tela via `StorageService`.
class DailyChallengeEngine {
  const DailyChallengeEngine();

  static const int baseReward = 60;
  static const int streakBonusPerDay = 10;
  static const int maxStreakBonus = 60;

  DailyChallenge forDay(DateTime now) {
    final String day = ProgressionEngine.dayKey(now);
    final Random rng = Random(now.year * 10000 + now.month * 100 + now.day);
    // Fim de semana é mais difícil e com mais folga de jogadas.
    final bool weekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    return DailyChallenge(
      day: day,
      moveLimit: weekend ? 28 + rng.nextInt(6) : 22 + rng.nextInt(7),
      difficulty: weekend ? CpuDifficulty.hard : CpuDifficulty.medium,
    );
  }

  /// Também recusa quando o último desafio concluído está no FUTURO: voltar
  /// a data do aparelho não libera o prêmio de novo.
  bool canComplete(ProgressState state, DateTime now) {
    final String? last = state.lastChallengeDay;
    return last == null || last.compareTo(ProgressionEngine.dayKey(now)) < 0;
  }

  /// Dias seguidos que o PRÓXIMO desafio concluído contaria.
  int nextStreak(ProgressState state, DateTime now) {
    final String? last = state.lastChallengeDay;
    if (last != null && last == ProgressionEngine.yesterdayKey(now)) {
      return state.challengeStreak + 1;
    }
    if (last == ProgressionEngine.dayKey(now)) {
      return state.challengeStreak;
    }
    return 1;
  }

  /// Sequência que ainda vale hoje (0 se o jogador pulou um dia).
  int currentStreak(ProgressState state, DateTime now) {
    final String? last = state.lastChallengeDay;
    if (last == ProgressionEngine.dayKey(now) ||
        last == ProgressionEngine.yesterdayKey(now)) {
      return state.challengeStreak;
    }
    return 0;
  }

  static int rewardForStreak(int streak) {
    final int bonus = (streak - 1) * streakBonusPerDay;
    return baseReward + bonus.clamp(0, maxStreakBonus);
  }

  /// Registra a vitória de uma partida do desafio. Paga só se a vitória veio
  /// dentro do limite de jogadas e o desafio de hoje ainda não foi pago.
  /// Devolve as moedas creditadas (0 = não pagou).
  int complete(
    ProgressState state,
    DateTime now, {
    required bool won,
    required int humanMoves,
    required DailyChallenge challenge,
  }) {
    if (!won ||
        humanMoves > challenge.moveLimit ||
        challenge.day != ProgressionEngine.dayKey(now) ||
        !canComplete(state, now)) {
      return 0;
    }
    final int streak = nextStreak(state, now);
    final int reward = rewardForStreak(streak);
    state.challengeStreak = streak;
    state.bestChallengeStreak = max(state.bestChallengeStreak, streak);
    state.lastChallengeDay = challenge.day;
    state.coins += reward;
    return reward;
  }
}

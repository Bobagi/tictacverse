import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/models/achievement.dart';
import 'package:tictacverse/models/cpu_difficulty.dart';
import 'package:tictacverse/models/game_mode.dart';
import 'package:tictacverse/models/progress_state.dart';
import 'package:tictacverse/services/progression_engine.dart';

/// Engine sem catálogo: isola o XP da partida do bônus das conquistas.
ProgressionEngine bareEngine() =>
    ProgressionEngine(catalog: <AchievementDefinition>[]);

MatchOutcome outcome({
  GameModeType mode = GameModeType.classic,
  bool vsCpu = true,
  CpuDifficulty difficulty = CpuDifficulty.easy,
  bool humanWon = false,
  bool isDraw = false,
  int? humanMoveCount,
}) {
  return MatchOutcome(
    mode: mode,
    vsCpu: vsCpu,
    difficulty: difficulty,
    humanWon: humanWon,
    isDraw: isDraw,
    humanMoveCount: humanMoveCount,
  );
}

void main() {
  group('curva de nível', () {
    test('nível 1 começa em 0 XP e a curva é estritamente crescente', () {
      expect(ProgressionEngine.xpToReachLevel(1), 0);
      expect(ProgressionEngine.levelForXp(0), 1);
      expect(ProgressionEngine.levelForXp(-50), 1);
      for (int level = 1; level < 60; level++) {
        expect(
          ProgressionEngine.xpToReachLevel(level + 1),
          greaterThan(ProgressionEngine.xpToReachLevel(level)),
          reason: 'o custo do nível $level precisa ser positivo',
        );
      }
    });

    test('levelForXp é a inversa exata de xpToReachLevel nos limites', () {
      for (int level = 2; level <= 60; level++) {
        final int threshold = ProgressionEngine.xpToReachLevel(level);
        expect(ProgressionEngine.levelForXp(threshold), level,
            reason: 'o XP exato do nível $level tem de dar nível $level');
        expect(ProgressionEngine.levelForXp(threshold - 1), level - 1,
            reason: '1 XP a menos ainda é o nível anterior');
        expect(ProgressionEngine.levelForXp(threshold + 1), level,
            reason: '1 XP a mais continua no nível $level');
      }
    });

    test('o custo de cada nível segue 80 + 40 * (n - 1)', () {
      expect(ProgressionEngine.xpToReachLevel(2), 80);
      expect(
          ProgressionEngine.xpToReachLevel(3) -
              ProgressionEngine.xpToReachLevel(2),
          120);
      expect(
          ProgressionEngine.xpToReachLevel(4) -
              ProgressionEngine.xpToReachLevel(3),
          160);
    });

    test('levelBar devolve o progresso dentro do nível, não o XP total', () {
      final (int into, int span) = ProgressionEngine.levelBar(100);
      expect(ProgressionEngine.levelForXp(100), 2);
      expect(into, 20, reason: '100 XP menos os 80 do nível 2');
      expect(span, 120, reason: 'o nível 2 custa 120 para virar 3');
    });

    test('não trava nem estoura com XP muito alto', () {
      final int level = ProgressionEngine.levelForXp(5000000);
      expect(level, greaterThan(100));
      expect(ProgressionEngine.xpToReachLevel(level),
          lessThanOrEqualTo(5000000));
      expect(ProgressionEngine.xpToReachLevel(level + 1),
          greaterThan(5000000));
    });
  });

  group('XP por partida', () {
    test('derrota no fácil rende só a participação', () {
      expect(ProgressionEngine.xpForMatch(outcome()), 10);
    });

    test('vitória e empate somam bônus diferentes', () {
      expect(ProgressionEngine.xpForMatch(outcome(humanWon: true)), 35);
      expect(ProgressionEngine.xpForMatch(outcome(isDraw: true)), 15);
    });

    test('a dificuldade só pontua contra a máquina', () {
      expect(
        ProgressionEngine.xpForMatch(
            outcome(difficulty: CpuDifficulty.medium)),
        15,
      );
      expect(
        ProgressionEngine.xpForMatch(outcome(difficulty: CpuDifficulty.hard)),
        22,
      );
      expect(
        ProgressionEngine.xpForMatch(
            outcome(vsCpu: false, difficulty: CpuDifficulty.hard)),
        10,
        reason: 'no dois jogadores a dificuldade da CPU não vale nada',
      );
    });

    test('o Super Jogo da Velha multiplica o total por 1,5', () {
      // 10 base + 25 vitória + 12 impossível = 47; 47 * 1,5 = 70,5 -> 71.
      expect(
        ProgressionEngine.xpForMatch(outcome(
          mode: GameModeType.ultimate2,
          humanWon: true,
          difficulty: CpuDifficulty.hard,
        )),
        71,
      );
      expect(
        ProgressionEngine.xpForMatch(outcome(mode: GameModeType.ultimate2)),
        15,
        reason: '10 de base viram 15 no carro-chefe',
      );
    });
  });

  group('sequência diária', () {
    final DateTime day1 = DateTime(2026, 3, 10, 9);
    final DateTime day1Night = DateTime(2026, 3, 10, 23, 30);
    final DateTime day2 = DateTime(2026, 3, 11, 8);
    final DateTime day4 = DateTime(2026, 3, 13, 8);

    test('a primeira partida do dia abre a sequência em 1', () {
      final ProgressState state = ProgressState();
      bareEngine().applyMatch(state, outcome(), day1);
      expect(state.dailyStreak, 1);
      expect(state.bestDailyStreak, 1);
      expect(state.lastPlayedDay, '2026-03-10');
    });

    test('duas partidas no mesmo dia não contam duas vezes', () {
      final ProgressState state = ProgressState();
      final ProgressionEngine engine = bareEngine();
      engine.applyMatch(state, outcome(), day1);
      engine.applyMatch(state, outcome(), day1Night);
      expect(state.dailyStreak, 1);
      expect(state.matches, 2, reason: 'as partidas em si contam as duas');
    });

    test('jogar de novo no mesmo dia não derruba a sequência já construída',
        () {
      // Cenário que o teste acima NÃO distingue: sem o curto-circuito do
      // "mesmo dia", a segunda partida do dia 2 cairia no ramo de reset e
      // zeraria uma sequência de 2 para 1.
      final ProgressState state = ProgressState();
      final ProgressionEngine engine = bareEngine();
      engine.applyMatch(state, outcome(), day1);
      engine.applyMatch(state, outcome(), day2);
      expect(state.dailyStreak, 2);

      engine.applyMatch(state, outcome(), DateTime(2026, 3, 11, 21));
      expect(state.dailyStreak, 2, reason: 'a sequência não pode regredir');
      expect(state.bestDailyStreak, 2);
    });

    test('jogar no dia seguinte incrementa', () {
      final ProgressState state = ProgressState();
      final ProgressionEngine engine = bareEngine();
      engine.applyMatch(state, outcome(), day1);
      engine.applyMatch(state, outcome(), day2);
      expect(state.dailyStreak, 2);
      expect(state.bestDailyStreak, 2);
    });

    test('pular um dia reseta a sequência mas preserva o recorde', () {
      final ProgressState state = ProgressState();
      final ProgressionEngine engine = bareEngine();
      engine.applyMatch(state, outcome(), day1);
      engine.applyMatch(state, outcome(), day2);
      engine.applyMatch(state, outcome(), day4);
      expect(state.dailyStreak, 1, reason: 'o dia 12 ficou vazio');
      expect(state.bestDailyStreak, 2);
    });

    test('a virada de mês e de ano continua sendo dia seguinte', () {
      final ProgressState state = ProgressState();
      final ProgressionEngine engine = bareEngine();
      engine.applyMatch(state, outcome(), DateTime(2026, 12, 31, 22));
      engine.applyMatch(state, outcome(), DateTime(2027, 1, 1, 7));
      expect(state.dailyStreak, 2);
    });
  });

  group('contadores de vitória', () {
    test('vitória no dois jogadores não conta como vitória do jogador', () {
      final ProgressState state = ProgressState(
        currentWinStreak: 4,
        bestWinStreak: 4,
      );
      // `humanWon: true` de propósito: é o guard do vsCpu que tem de barrar,
      // não o resultado. Com `humanWon: false` o teste passaria mesmo sem o
      // guard, porque o ramo de vitória nem seria alcançado.
      bareEngine().applyMatch(
        state,
        outcome(
            vsCpu: false, humanWon: true, mode: GameModeType.ultimate2,
            difficulty: CpuDifficulty.hard),
        DateTime(2026, 3, 10),
      );
      expect(state.cpuWins, 0);
      expect(state.ultimateWins, 0);
      expect(state.hardWins, 0);
      expect(state.currentWinStreak, 4,
          reason: 'partida local não mexe na sequência contra a máquina');
      expect(state.matches, 1, reason: 'a partida em si conta');
      expect(state.modesPlayed, <GameModeType>{GameModeType.ultimate2});
    });

    test('a sequência sobe a cada vitória e zera na derrota', () {
      final ProgressState state = ProgressState();
      final ProgressionEngine engine = bareEngine();
      final DateTime now = DateTime(2026, 3, 10);
      engine.applyMatch(state, outcome(humanWon: true), now);
      engine.applyMatch(state, outcome(humanWon: true), now);
      expect(state.currentWinStreak, 2);
      expect(state.bestWinStreak, 2);

      engine.applyMatch(state, outcome(), now);
      expect(state.currentWinStreak, 0);
      expect(state.bestWinStreak, 2, reason: 'o recorde não regride');
    });

    test('o empate contra a máquina também zera a sequência', () {
      final ProgressState state = ProgressState();
      final ProgressionEngine engine = bareEngine();
      final DateTime now = DateTime(2026, 3, 10);
      engine.applyMatch(state, outcome(humanWon: true), now);
      engine.applyMatch(state, outcome(isDraw: true), now);
      expect(state.currentWinStreak, 0);
    });

    test('vitória no impossível e no carro-chefe alimenta os contadores', () {
      final ProgressState state = ProgressState();
      bareEngine().applyMatch(
        state,
        outcome(
          mode: GameModeType.ultimate2,
          humanWon: true,
          difficulty: CpuDifficulty.hard,
        ),
        DateTime(2026, 3, 10),
      );
      expect(state.ultimateWins, 1);
      expect(state.hardWins, 1);
    });

    test('vitória rápida só vale no Clássico e com 3 jogadas ou menos', () {
      final DateTime now = DateTime(2026, 3, 10);

      final ProgressState slow = ProgressState();
      bareEngine().applyMatch(
          slow, outcome(humanWon: true, humanMoveCount: 4), now);
      expect(slow.hasFastWin, isFalse);

      final ProgressState other = ProgressState();
      bareEngine().applyMatch(
        other,
        outcome(
            mode: GameModeType.shift, humanWon: true, humanMoveCount: 3),
        now,
      );
      expect(other.hasFastWin, isFalse,
          reason: 'fora do Clássico a contagem de jogadas é ambígua');

      final ProgressState fast = ProgressState();
      bareEngine().applyMatch(
          fast, outcome(humanWon: true, humanMoveCount: 3), now);
      expect(fast.hasFastWin, isTrue);
    });
  });

  group('desbloqueio de conquistas', () {
    test('desbloqueia ao bater a meta e credita o bônus uma única vez', () {
      final ProgressionEngine engine = ProgressionEngine();
      final ProgressState state = ProgressState();
      final DateTime now = DateTime(2026, 3, 10);

      final ProgressionResult first =
          engine.applyMatch(state, outcome(humanWon: true), now);
      expect(
        first.newlyUnlocked.map((AchievementDefinition a) => a.id),
        contains('first_win'),
      );
      final int xpAfterUnlock = state.xp;

      final ProgressionResult second =
          engine.applyMatch(state, outcome(humanWon: true), now);
      expect(
        second.newlyUnlocked.map((AchievementDefinition a) => a.id),
        isNot(contains('first_win')),
        reason: 'a mesma conquista não pode cair duas vezes',
      );
      expect(
        state.xp - xpAfterUnlock,
        ProgressionEngine.xpForMatch(outcome(humanWon: true)),
        reason: 'a segunda vitória rende só o XP da partida, sem bônus de novo',
      );
      expect(state.unlockedAchievements.where((String id) => id == 'first_win'),
          hasLength(1));
    });

    test('o resultado reporta a subida de nível de fato', () {
      final ProgressionEngine engine = bareEngine();
      final ProgressState state = ProgressState(xp: 79);
      final ProgressionResult result =
          engine.applyMatch(state, outcome(), DateTime(2026, 3, 10));
      expect(result.levelBefore, 1);
      expect(result.levelAfter, 2);
      expect(result.leveledUp, isTrue);
      expect(result.xpGained, 10);
      expect(result.hasNews, isTrue);
    });

    test('uma partida sem novidade não anuncia nada além do XP', () {
      final ProgressionEngine engine = bareEngine();
      final ProgressState state = ProgressState(xp: 5);
      final ProgressionResult result =
          engine.applyMatch(state, outcome(), DateTime(2026, 3, 10));
      expect(result.leveledUp, isFalse);
      expect(result.newlyUnlocked, isEmpty);
      expect(result.hasNews, isFalse);
    });
  });

  group('reconcile retroativo', () {
    test('quem já cumpria o requisito recebe sem jogar de novo', () {
      final ProgressionEngine engine = ProgressionEngine();
      // Jogador antigo: contadores cheios, nenhuma conquista registrada.
      final ProgressState state = ProgressState(cpuWins: 60, matches: 120);

      final List<AchievementDefinition> unlocked = engine.reconcile(state);
      final Set<String> ids =
          unlocked.map((AchievementDefinition a) => a.id).toSet();
      expect(ids, containsAll(<String>['first_win', 'wins_10', 'wins_50']));
      expect(ids, contains('matches_50'));
      expect(ids, isNot(contains('wins_200')));
      expect(state.xp, greaterThan(0), reason: 'o bônus foi creditado');
    });

    test('reconcile é idempotente', () {
      final ProgressionEngine engine = ProgressionEngine();
      final ProgressState state = ProgressState(cpuWins: 60, matches: 120);
      engine.reconcile(state);
      final int xpAfterFirst = state.xp;
      final int unlockedAfterFirst = state.unlockedAchievements.length;

      final List<AchievementDefinition> again = engine.reconcile(state);
      expect(again, isEmpty);
      expect(state.xp, xpAfterFirst);
      expect(state.unlockedAchievements, hasLength(unlockedAfterFirst));
    });
  });

  group('catálogo', () {
    test('os ids são únicos e estáveis (chave do Play Games)', () {
      final List<AchievementDefinition> catalog = createAchievements();
      final Set<String> ids =
          catalog.map((AchievementDefinition a) => a.id).toSet();
      expect(ids, hasLength(catalog.length));
      expect(catalog, isNotEmpty);
    });

    test('toda conquista tem meta positiva e progresso limitado à meta', () {
      final ProgressState maxed = ProgressState(
        cpuWins: 99999,
        matches: 99999,
        ultimateWins: 99999,
        hardWins: 99999,
        bestWinStreak: 99999,
        bestDailyStreak: 99999,
        hasFastWin: true,
        modesPlayed: GameModeType.values.toSet(),
      );
      for (final AchievementDefinition achievement in createAchievements()) {
        expect(achievement.target, greaterThan(0), reason: achievement.id);
        expect(achievement.progress(maxed), achievement.target,
            reason: achievement.id);
        expect(achievement.isUnlockedBy(maxed), isTrue,
            reason: '${achievement.id} precisa ser alcançável');
      }
    });

    test('nada vem desbloqueado num estado zerado', () {
      final ProgressState fresh = ProgressState();
      for (final AchievementDefinition achievement in createAchievements()) {
        expect(achievement.isUnlockedBy(fresh), isFalse,
            reason: achievement.id);
      }
    });
  });

  group('persistência do ProgressState', () {
    test('round-trip preserva contadores, modos e conquistas', () {
      final ProgressState original = ProgressState(
        xp: 1234,
        matches: 57,
        cpuWins: 30,
        ultimateWins: 8,
        hardWins: 2,
        currentWinStreak: 3,
        bestWinStreak: 9,
        dailyStreak: 4,
        bestDailyStreak: 11,
        hasFastWin: true,
        lastPlayedDay: '2026-03-10',
        modesPlayed: <GameModeType>{
          GameModeType.classic,
          GameModeType.ultimate2,
        },
        unlockedAchievements: <String>{'first_win', 'wins_10'},
      );

      final ProgressState restored = ProgressState.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.xp, 1234);
      expect(restored.matches, 57);
      expect(restored.cpuWins, 30);
      expect(restored.ultimateWins, 8);
      expect(restored.hardWins, 2);
      expect(restored.currentWinStreak, 3);
      expect(restored.bestWinStreak, 9);
      expect(restored.dailyStreak, 4);
      expect(restored.bestDailyStreak, 11);
      expect(restored.hasFastWin, isTrue);
      expect(restored.lastPlayedDay, '2026-03-10');
      expect(restored.modesPlayed,
          <GameModeType>{GameModeType.classic, GameModeType.ultimate2});
      expect(restored.unlockedAchievements, <String>{'first_win', 'wins_10'});
    });

    test('json ausente ou com lixo vira estado zerado sem lançar', () {
      expect(ProgressState.fromJson(null).xp, 0);

      final ProgressState garbage = ProgressState.fromJson(<String, dynamic>{
        'xp': 'muito',
        'matches': null,
        'hasFastWin': 'sim',
        'modesPlayed': <Object?>['inexistente', 42, 'classic'],
        'unlocked': <Object?>[7, 'first_win', null],
      });
      expect(garbage.xp, 0);
      expect(garbage.matches, 0);
      expect(garbage.hasFastWin, isFalse);
      expect(garbage.modesPlayed, <GameModeType>{GameModeType.classic},
          reason: 'entradas inválidas são descartadas, a válida fica');
      expect(garbage.unlockedAchievements, <String>{'first_win'});
    });

    test('um modo removido do enum no futuro não quebra a leitura', () {
      final ProgressState state = ProgressState.fromJson(<String, dynamic>{
        'modesPlayed': <Object?>['modo_que_nao_existe_mais'],
      });
      expect(state.modesPlayed, isEmpty);
    });
  });
}

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/models/board_theme.dart';
import 'package:tictacverse/models/cpu_difficulty.dart';
import 'package:tictacverse/models/progress_state.dart';
import 'package:tictacverse/services/daily_challenge.dart';
import 'package:tictacverse/services/economy_engine.dart';
import 'package:tictacverse/services/review_service.dart';
import 'package:tictacverse/services/starter_offer.dart';
import 'package:tictacverse/services/storage_service.dart';

void main() {
  const DailyChallengeEngine rules = DailyChallengeEngine();
  final DateTime monday = DateTime(2026, 10, 5, 10);
  final DateTime tuesday = DateTime(2026, 10, 6, 10);
  final DateTime thursday = DateTime(2026, 10, 8, 10);
  final DateTime saturday = DateTime(2026, 10, 10, 10);

  group('desafio diário', () {
    test('o desafio do dia é o mesmo para todo mundo e muda com o dia', () {
      final DailyChallenge a = rules.forDay(monday);
      final DailyChallenge b = rules.forDay(DateTime(2026, 10, 5, 23, 59));
      expect(a.moveLimit, b.moveLimit);
      expect(a.difficulty, b.difficulty);
      expect(a.day, '2026-10-05');
      // Em 60 dias o limite varia (não é um número fixo).
      final Set<int> limits = <int>{
        for (int i = 0; i < 60; i++)
          rules.forDay(monday.add(Duration(days: i))).moveLimit,
      };
      expect(limits.length, greaterThan(3));
      for (final int l in limits) {
        expect(l, inInclusiveRange(22, 33), reason: 'limite jogável');
      }
    });

    test('fim de semana é mais difícil', () {
      expect(rules.forDay(saturday).difficulty, CpuDifficulty.hard);
      expect(rules.forDay(monday).difficulty, CpuDifficulty.medium);
    });

    test('paga só vencendo dentro do limite, uma vez por dia', () {
      final ProgressState s = ProgressState();
      final DailyChallenge c = rules.forDay(monday);
      expect(
          rules.complete(s, monday,
              won: true, humanMoves: c.moveLimit + 1, challenge: c),
          0,
          reason: 'passou do limite');
      expect(
          rules.complete(s, monday, won: false, humanMoves: 10, challenge: c),
          0,
          reason: 'perdeu');
      expect(
          rules.complete(s, monday,
              won: true, humanMoves: c.moveLimit, challenge: c),
          DailyChallengeEngine.baseReward,
          reason: 'no limite exato vale');
      expect(s.coins, DailyChallengeEngine.baseReward);
      expect(
          rules.complete(s, monday, won: true, humanMoves: 5, challenge: c), 0,
          reason: 'segunda vitória no mesmo dia não paga');
      expect(s.coins, DailyChallengeEngine.baseReward);
    });

    test('desafio de ontem aberto hoje não paga (virou o dia no meio)', () {
      final ProgressState s = ProgressState();
      final DailyChallenge yesterday = rules.forDay(monday);
      expect(
          rules.complete(s, tuesday,
              won: true, humanMoves: 5, challenge: yesterday),
          0);
    });

    test('dias seguidos aumentam o prêmio; pular um dia zera', () {
      final ProgressState s = ProgressState();
      rules.complete(s, monday,
          won: true, humanMoves: 5, challenge: rules.forDay(monday));
      final int second = rules.complete(s, tuesday,
          won: true, humanMoves: 5, challenge: rules.forDay(tuesday));
      expect(
          second,
          DailyChallengeEngine.baseReward +
              DailyChallengeEngine.streakBonusPerDay);
      expect(s.challengeStreak, 2);
      expect(rules.currentStreak(s, thursday), 0, reason: 'pulou a quarta');
      final int after = rules.complete(s, thursday,
          won: true, humanMoves: 5, challenge: rules.forDay(thursday));
      expect(after, DailyChallengeEngine.baseReward);
      expect(s.bestChallengeStreak, 2);
    });

    test('o bônus de sequência tem teto', () {
      expect(
          DailyChallengeEngine.rewardForStreak(100),
          DailyChallengeEngine.baseReward +
              DailyChallengeEngine.maxStreakBonus);
    });

    test('voltar a data do aparelho não libera o prêmio de novo', () {
      final ProgressState s = ProgressState(lastChallengeDay: '2026-10-09');
      expect(rules.canComplete(s, monday), isFalse);
    });

    test('estado do desafio sobrevive ao save', () {
      final ProgressState s = ProgressState();
      rules.complete(s, monday,
          won: true, humanMoves: 5, challenge: rules.forDay(monday));
      final ProgressState back = ProgressState.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back.lastChallengeDay, '2026-10-05');
      expect(back.challengeStreak, 1);
      expect(rules.canComplete(back, monday), isFalse);
    });
  });

  group('convite do pacote de boas-vindas', () {
    bool show({
      int sessions = 3,
      int shows = 0,
      String? last,
      bool adsRemoved = false,
      bool available = true,
    }) =>
        StarterOffer.shouldShow(
          sessions: sessions,
          shows: shows,
          lastShownDay: last,
          now: thursday,
          adsRemoved: adsRemoved,
          productAvailable: available,
        );

    test('a partir da 2ª sessão, com o produto na loja', () {
      expect(show(sessions: 1), isFalse);
      expect(show(sessions: 2), isTrue);
      expect(show(available: false), isFalse);
    });

    test('nunca para quem já tirou os anúncios', () {
      expect(show(adsRemoved: true), isFalse);
    });

    test('no máximo 3 vezes, com 2 dias de intervalo', () {
      expect(show(shows: 3), isFalse);
      expect(show(last: '2026-10-08'), isFalse, reason: 'hoje');
      expect(show(last: '2026-10-07'), isFalse, reason: 'ontem');
      expect(show(last: '2026-10-06'), isTrue, reason: '2 dias');
      expect(show(last: '2026-10-20'), isFalse, reason: 'relógio voltado');
    });
  });

  group('id da instalação', () {
    test('UUID v4 válido, aleatório e no formato que o servidor aceita', () {
      final Set<String> ids = <String>{
        for (int i = 0; i < 200; i++) StorageService.newInstallId(),
      };
      expect(ids.length, 200);
      for (final String id in ids) {
        expect(StorageService.isValidInstallId(id), isTrue, reason: id);
      }
      expect(StorageService.isValidInstallId('nao-e-uuid'), isFalse);
      expect(
          StorageService.isValidInstallId(
              '1B4E28BA-2FA1-4D3B-A3F5-EF19B5A7633B'),
          isFalse,
          reason: 'o servidor só aceita minúsculas');
      // Mesmo gerador com a mesma semente = mesmo id (o formato é estável).
      expect(StorageService.newInstallId(Random(1)),
          StorageService.newInstallId(Random(1)));
    });
  });

  group('temas de tabuleiro', () {
    const EconomyEngine engine = EconomyEngine();

    test('compra debita, entrega e equipa; sem saldo não', () {
      final ProgressState s = ProgressState(coins: 250);
      expect(engine.buyTheme(s, 'ocean'), SkinPurchaseResult.notEnoughCoins);
      expect(s.coins, 250);
      expect(engine.buyTheme(s, 'sunset'), SkinPurchaseResult.purchased);
      expect(s.coins, 50);
      expect(s.equippedTheme, 'sunset');
      expect(engine.buyTheme(s, 'sunset'), SkinPurchaseResult.alreadyOwned);
      expect(engine.equipTheme(s, defaultBoardThemeId), isTrue);
      expect(engine.equipTheme(s, 'royal'), isFalse, reason: 'não tem');
      expect(engine.buyTheme(s, 'hack'), SkinPurchaseResult.unknownSkin);
    });

    test('catálogo: ids únicos, só o inicial é grátis, preço crescente', () {
      expect(boardThemeCatalog.map((BoardTheme t) => t.id).toSet().length,
          boardThemeCatalog.length);
      expect(boardThemeCatalog.where((BoardTheme t) => t.price == 0).single.id,
          defaultBoardThemeId);
      for (int i = 1; i < boardThemeCatalog.length; i++) {
        expect(boardThemeCatalog[i].price,
            greaterThan(boardThemeCatalog[i - 1].price));
      }
    });

    test('estorno também devolve tema comprado com moeda estornada', () {
      final ProgressState s = ProgressState(
          coins: 0,
          ownedThemes: <String>{defaultBoardThemeId, 'royal'},
          equippedTheme: 'royal',
          coinPurchases: <String, int>{'theme:royal': 600});
      final RevocationEffect e = engine.applyRevocation(s,
          redemptionId: 'x', coins: 300, removeAds: false);
      expect(e.lostSkins, <String>['royal']);
      expect(s.equippedTheme, defaultBoardThemeId);
      expect(s.coins, 300);
    });

    test('tema sobrevive ao save e save antigo nasce com o inicial', () {
      final ProgressState s = ProgressState(
          ownedThemes: <String>{defaultBoardThemeId, 'ocean'},
          equippedTheme: 'ocean');
      final ProgressState back = ProgressState.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back.equippedTheme, 'ocean');
      expect(back.ownedThemes, contains('ocean'));
      final ProgressState old =
          ProgressState.fromJson(<String, dynamic>{'xp': 10});
      expect(old.ownedThemes, <String>{defaultBoardThemeId});
      expect(old.equippedTheme, defaultBoardThemeId);
    });
  });

  group('pedido de avaliação', () {
    test('vitória contra a máquina ou conquista nova é bom momento', () {
      expect(
          ReviewService.isGoodMoment(humanWonVsCpu: true, newAchievements: 0),
          isTrue);
      expect(
          ReviewService.isGoodMoment(humanWonVsCpu: false, newAchievements: 1),
          isTrue);
      expect(
          ReviewService.isGoodMoment(humanWonVsCpu: false, newAchievements: 0),
          isFalse);
    });
  });
}

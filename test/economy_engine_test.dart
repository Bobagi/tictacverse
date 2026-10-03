import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/models/cpu_difficulty.dart';
import 'package:tictacverse/models/game_mode.dart';
import 'package:tictacverse/models/piece_skin.dart';
import 'package:tictacverse/models/progress_state.dart';
import 'package:tictacverse/services/economy_engine.dart';
import 'package:tictacverse/services/progression_engine.dart';

/// Moedas são o caminho do dinheiro do jogo: o bônus diário e a loja não
/// podem pagar duas vezes, debitar sem entregar nem passar do teto de anúncio.
void main() {
  const EconomyEngine engine = EconomyEngine();
  final DateTime day1 = DateTime(2026, 10, 3, 9);
  final DateTime day2 = DateTime(2026, 10, 4, 23, 59);
  final DateTime day4 = DateTime(2026, 10, 6, 8);

  group('bônus diário', () {
    test('primeiro resgate paga o dia 1 e um segundo toque no mesmo dia paga 0',
        () {
      final ProgressState s = ProgressState();
      expect(engine.claimDaily(s, day1), 20);
      expect(engine.claimDaily(s, day1.add(const Duration(hours: 5))), 0);
      expect(s.coins, 20);
      expect(engine.canClaimDaily(s, day1), isFalse);
    });

    test('dia seguinte avança a sequência e paga mais', () {
      final ProgressState s = ProgressState();
      engine.claimDaily(s, day1);
      expect(engine.nextDailyStreak(s, day2), 2);
      expect(engine.claimDaily(s, day2), 25);
      expect(s.dailyClaimStreak, 2);
      expect(s.coins, 45);
    });

    test('pular um dia recomeça a sequência do 1', () {
      final ProgressState s = ProgressState();
      engine.claimDaily(s, day1);
      engine.claimDaily(s, day2);
      expect(engine.claimDaily(s, day4), 20);
      expect(s.dailyClaimStreak, 1);
    });

    test('depois do 7º dia o valor volta ao ciclo sem zerar a sequência', () {
      final ProgressState s = ProgressState();
      final List<int> paid = <int>[
        for (int d = 0; d < 9; d++)
          engine.claimDaily(s, DateTime(2026, 10, 1 + d, 12)),
      ];
      expect(paid, <int>[20, 25, 30, 40, 50, 60, 100, 20, 25]);
      expect(s.dailyClaimStreak, 9);
    });

    test('virada de mês e de ano conta como dia seguido', () {
      final ProgressState s = ProgressState();
      engine.claimDaily(s, DateTime(2026, 12, 31, 22));
      expect(engine.claimDaily(s, DateTime(2027, 1, 1, 1)), 25);
    });
  });

  group('relógio do aparelho voltado', () {
    test('não libera o bônus diário nem zera o teto de anúncio', () {
      final ProgressState s = ProgressState();
      engine.claimDaily(s, day2);
      for (int i = 0; i < EconomyEngine.adCoinsDailyCap; i++) {
        engine.grantAdCoins(s, day2);
      }
      final int coins = s.coins;
      expect(engine.claimDaily(s, day1), 0);
      expect(engine.grantAdCoins(s, day1), 0);
      expect(s.coins, coins);
    });
  });

  group('moedas por anúncio premiado na loja', () {
    test('para no teto diário e libera de novo no dia seguinte', () {
      final ProgressState s = ProgressState();
      final List<int> paid = <int>[
        for (int i = 0; i < EconomyEngine.adCoinsDailyCap + 2; i++)
          engine.grantAdCoins(s, day1),
      ];
      expect(
          paid.where((int p) => p > 0).length, EconomyEngine.adCoinsDailyCap);
      expect(paid.last, 0);
      expect(
          s.coins, EconomyEngine.adCoinsDailyCap * EconomyEngine.adCoinsReward);
      expect(engine.adCoinsRemaining(s, day1), 0);
      expect(engine.adCoinsRemaining(s, day2), EconomyEngine.adCoinsDailyCap);
      expect(engine.grantAdCoins(s, day2), EconomyEngine.adCoinsReward);
    });
  });

  group('loja de visuais', () {
    final PieceSkin neon = pieceSkinById('neon');

    test('sem saldo suficiente não debita nem entrega', () {
      final ProgressState s = ProgressState(coins: neon.price - 1);
      expect(engine.buySkin(s, 'neon'), SkinPurchaseResult.notEnoughCoins);
      expect(s.coins, neon.price - 1);
      expect(s.ownedSkins.contains('neon'), isFalse);
      expect(s.equippedSkin, ProgressState.defaultSkinId);
    });

    test('compra debita o preço exato, entrega e equipa', () {
      final ProgressState s = ProgressState(coins: neon.price + 7);
      expect(engine.buySkin(s, 'neon'), SkinPurchaseResult.purchased);
      expect(s.coins, 7);
      expect(s.ownedSkins, contains('neon'));
      expect(s.equippedSkin, 'neon');
    });

    test('comprar de novo o que já tem não cobra outra vez', () {
      final ProgressState s = ProgressState(coins: neon.price * 3);
      engine.buySkin(s, 'neon');
      expect(engine.buySkin(s, 'neon'), SkinPurchaseResult.alreadyOwned);
      expect(s.coins, neon.price * 2);
    });

    test('id desconhecido e equipar o que não tem são recusados', () {
      final ProgressState s = ProgressState(coins: 99999);
      expect(engine.buySkin(s, 'hack'), SkinPurchaseResult.unknownSkin);
      expect(s.coins, 99999);
      expect(engine.equipSkin(s, 'galaxy'), isFalse);
      expect(s.equippedSkin, ProgressState.defaultSkinId);
    });

    test('o catálogo tem ids únicos e só o visual inicial é de graça', () {
      final Set<String> ids =
          pieceSkinCatalog.map((PieceSkin s) => s.id).toSet();
      expect(ids.length, pieceSkinCatalog.length);
      expect(pieceSkinCatalog.where((PieceSkin s) => s.price == 0).single.id,
          ProgressState.defaultSkinId);
    });
  });

  group('moedas junto com o XP', () {
    const MatchOutcome win = MatchOutcome(
      mode: GameModeType.ultimate2,
      vsCpu: true,
      difficulty: CpuDifficulty.hard,
      humanWon: true,
      isDraw: false,
    );

    test('partida credita moedas proporcionais ao XP ganho', () {
      final ProgressState s = ProgressState();
      final ProgressionResult r = ProgressionEngine().applyMatch(s, win, day1);
      expect(r.coinsGained, EconomyEngine.coinsForXp(r.xpGained));
      expect(r.coinsGained, greaterThan(0));
      expect(s.coins, r.coinsGained);
    });

    test('o bônus do premiado também paga moedas, e o merge soma as duas', () {
      final ProgressState s = ProgressState();
      final ProgressionEngine e = ProgressionEngine();
      final ProgressionResult match = e.applyMatch(s, win, day1);
      final ProgressionResult bonus = e.applyBonusXp(s, match.xpGained);
      expect(bonus.coinsGained, greaterThanOrEqualTo(match.coinsGained));
      expect(match.mergedWith(bonus).coinsGained,
          match.coinsGained + bonus.coinsGained);
      expect(s.coins, match.coinsGained + bonus.coinsGained);
    });

    test('XP zero ou negativo não gera moeda', () {
      expect(EconomyEngine.coinsForXp(0), 0);
      expect(EconomyEngine.coinsForXp(-5), 0);
    });
  });

  group('persistência', () {
    test('ida e volta pelo JSON preserva carteira, visuais e bônus', () {
      final ProgressState s = ProgressState(coins: 321);
      s.ownedSkins.add('gold');
      s.equippedSkin = 'gold';
      engine.claimDaily(s, day1);
      engine.grantAdCoins(s, day1);
      final ProgressState back = ProgressState.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back.coins, s.coins);
      expect(back.ownedSkins, s.ownedSkins);
      expect(back.equippedSkin, 'gold');
      expect(back.lastDailyClaimDay, s.lastDailyClaimDay);
      expect(back.dailyClaimStreak, 1);
      expect(back.adCoinsClaimsToday, 1);
      expect(engine.canClaimDaily(back, day1), isFalse);
    });

    test('save antigo (sem carteira) e lixo nos campos não quebram nada', () {
      final ProgressState old = ProgressState.fromJson(<String, dynamic>{
        'xp': 500,
        'coins': -40,
        'ownedSkins': 'x',
        'equippedSkin': 7,
      });
      expect(old.xp, 500);
      expect(old.coins, 0, reason: 'saldo nunca pode nascer negativo');
      expect(old.ownedSkins, <String>{ProgressState.defaultSkinId});
      expect(old.equippedSkin, ProgressState.defaultSkinId);
    });
  });
}

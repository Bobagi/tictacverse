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
    final PieceSkin paid = pieceSkinById('fireIce');

    test('sem saldo suficiente não debita nem entrega', () {
      final ProgressState s = ProgressState(coins: paid.price - 1);
      expect(engine.buySkin(s, 'fireIce'), SkinPurchaseResult.notEnoughCoins);
      expect(s.coins, paid.price - 1);
      expect(s.ownedSkins.contains('fireIce'), isFalse);
      expect(s.equippedSkin, ProgressState.defaultSkinId);
    });

    test('compra debita o preço exato, entrega e equipa', () {
      final ProgressState s = ProgressState(coins: paid.price + 7);
      expect(engine.buySkin(s, 'fireIce'), SkinPurchaseResult.purchased);
      expect(s.coins, 7);
      expect(s.ownedSkins, contains('fireIce'));
      expect(s.equippedSkin, 'fireIce');
    });

    test('comprar de novo o que já tem não cobra outra vez', () {
      final ProgressState s = ProgressState(coins: paid.price * 3);
      engine.buySkin(s, 'fireIce');
      expect(engine.buySkin(s, 'fireIce'), SkinPurchaseResult.alreadyOwned);
      expect(s.coins, paid.price * 2);
    });

    test('id desconhecido e equipar o que não tem são recusados', () {
      final ProgressState s = ProgressState(coins: 99999);
      expect(engine.buySkin(s, 'hack'), SkinPurchaseResult.unknownSkin);
      expect(s.coins, 99999);
      expect(engine.equipSkin(s, 'galaxy'), isFalse);
      expect(s.equippedSkin, ProgressState.defaultSkinId);
    });

    test('Neon é o visual inicial e o Aurora fecha o catálogo como o mais caro',
        () {
      final ProgressState s = ProgressState();
      expect(ProgressState.defaultSkinId, 'neon');
      expect(s.ownedSkins, <String>{'neon'});
      expect(s.equippedSkin, 'neon');
      expect(pieceSkinCatalog.first.id, 'neon');
      expect(pieceSkinCatalog.last.id, 'aurora');
      final int maxPrice = pieceSkinCatalog
          .map((PieceSkin s) => s.price)
          .reduce((int a, int b) => a > b ? a : b);
      expect(pieceSkinById('aurora').price, maxPrice);
      for (int i = 1; i < pieceSkinCatalog.length; i++) {
        expect(pieceSkinCatalog[i].price,
            greaterThanOrEqualTo(pieceSkinCatalog[i - 1].price),
            reason: 'a loja exibe do mais barato ao mais caro');
      }
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
      expect(old.coins, -40,
          reason: 'saldo negativo é dívida de estorno e precisa sobreviver');
      expect(old.ownedSkins, <String>{'aurora', 'neon'},
          reason: 'save de antes da troca: quem já jogava fica com o Aurora');
      expect(old.equippedSkin, ProgressState.defaultSkinId);
    });
  });

  group('migração Aurora -> Neon (v1.13.0)', () {
    ProgressState load(Map<String, dynamic> json) => ProgressState.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>);

    test('quem só tinha o Aurora passa a ver o Neon e mantém o Aurora', () {
      final ProgressState s = load(<String, dynamic>{
        'coins': 40,
        'ownedSkins': <String>['aurora'],
        'equippedSkin': 'aurora',
      });
      expect(s.equippedSkin, 'neon');
      expect(s.ownedSkins, <String>{'aurora', 'neon'});
      expect(s.coins, 40);
    });

    test('quem comprou o Neon recebe as 120 moedas de volta', () {
      final ProgressState s = load(<String, dynamic>{
        'coins': 5,
        'ownedSkins': <String>['aurora', 'neon'],
        'equippedSkin': 'neon',
      });
      expect(s.coins, 5 + ProgressState.legacyNeonPrice);
      expect(s.equippedSkin, 'neon');
      expect(s.ownedSkins, <String>{'aurora', 'neon'});
    });

    test('quem escolheu outro visual continua com ele', () {
      final ProgressState s = load(<String, dynamic>{
        'ownedSkins': <String>['aurora', 'gold'],
        'equippedSkin': 'gold',
      });
      expect(s.equippedSkin, 'gold');
    });

    test('todo mundo com o Aurora em uso passa para o Neon e segue dono dele',
        () {
      final ProgressState chose = load(<String, dynamic>{
        'ownedSkins': <String>['aurora', 'gold'],
        'equippedSkin': 'aurora',
      });
      expect(chose.equippedSkin, 'neon');
      expect(chose.ownedSkins, containsAll(<String>['aurora', 'gold']));
      // Save da v1.13.0 interna (catálogo 2) com o Aurora em uso também troca.
      final ProgressState v2 = load(<String, dynamic>{
        'ownedSkins': <String>['neon', 'aurora'],
        'equippedSkin': 'aurora',
        'catalogVersion': 2,
        'coins': 7,
      });
      expect(v2.equippedSkin, 'neon');
      expect(v2.coins, 7, reason: 'o reembolso do Neon não se repete');
    });

    test('depois da migração o jogador pode voltar a usar o Aurora', () {
      final ProgressState first = load(<String, dynamic>{
        'ownedSkins': <String>['aurora'],
        'equippedSkin': 'aurora',
      });
      first.equippedSkin = 'aurora';
      final ProgressState again = load(first.toJson());
      expect(again.equippedSkin, 'aurora',
          reason: 'a troca forçada roda uma vez; depois a escolha é dele');
    });

    test('a migração roda uma vez só: salvar e reabrir não devolve de novo',
        () {
      final ProgressState first = load(<String, dynamic>{
        'coins': 0,
        'ownedSkins': <String>['aurora', 'neon'],
        'equippedSkin': 'neon',
      });
      final ProgressState again = load(first.toJson());
      expect(again.coins, ProgressState.legacyNeonPrice);
      final ProgressState third = load(again.toJson());
      expect(third.coins, ProgressState.legacyNeonPrice);
    });

    test('jogador novo (save já na versão nova) não ganha o Aurora', () {
      final ProgressState fresh = load(ProgressState().toJson());
      expect(fresh.ownedSkins, <String>{'neon'});
      expect(fresh.equippedSkin, 'neon');
    });
  });

  group('entrega confirmada pelo servidor', () {
    test('credita uma vez por token, mesmo reentregue', () {
      final ProgressState s = ProgressState(coins: 10);
      final StoreGrant g = engine.applyServerGrant(s,
          purchaseToken: 'tok-a', coins: 1000, removeAds: false);
      expect(g.coins, 1000);
      expect(s.coins, 1010);
      final StoreGrant again = engine.applyServerGrant(s,
          purchaseToken: 'tok-a', coins: 1000, removeAds: false);
      expect(again.duplicate, isTrue);
      expect(s.coins, 1010);
      engine.applyServerGrant(s,
          purchaseToken: 'tok-b', coins: 1000, removeAds: false);
      expect(s.coins, 2010, reason: 'compra nova do mesmo pacote paga de novo');
    });

    test('token vazio e moeda negativa não creditam', () {
      final ProgressState s = ProgressState();
      engine.applyServerGrant(s,
          purchaseToken: '', coins: 300, removeAds: true);
      engine.applyServerGrant(s,
          purchaseToken: 'x', coins: -50, removeAds: false);
      expect(s.coins, 0);
      expect(s.adsRemoved, isFalse);
    });

    test('"sem anúncios" liga o direito e sobrevive ao save', () {
      final ProgressState s = ProgressState();
      final StoreGrant g = engine.applyServerGrant(s,
          purchaseToken: 't', coins: 0, removeAds: true);
      expect(g.removedAds, isTrue);
      expect(g.duplicate, isFalse);
      expect(s.adsRemoved, isTrue);
      final ProgressState back = ProgressState.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back.adsRemoved, isTrue);
    });

    test('o registro de tokens tem teto e sobrevive ao save', () {
      final ProgressState s = ProgressState();
      for (int i = 0; i < ProgressState.processedPurchasesCap + 5; i++) {
        engine.applyServerGrant(s,
            purchaseToken: 't$i', coins: 300, removeAds: false);
      }
      expect(s.processedPurchases.length, ProgressState.processedPurchasesCap);
      expect(s.processedPurchases.first, 't5');
      final ProgressState back = ProgressState.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      final int before = back.coins;
      engine.applyServerGrant(back,
          purchaseToken: 't50', coins: 300, removeAds: false);
      expect(back.coins, before);
    });
  });

  group('estorno', () {
    test('com saldo, só desconta', () {
      final ProgressState s = ProgressState(coins: 1500);
      final RevocationEffect e = engine.applyRevocation(s,
          redemptionId: '1', coins: 1000, removeAds: false);
      expect(e.applied, isTrue);
      expect(s.coins, 500);
      expect(e.lostSkins, isEmpty);
    });

    test('gastou tudo: visuais voltam para a loja, do mais caro, até cobrir',
        () {
      final ProgressState s = ProgressState(
          coins: 100,
          ownedSkins: <String>{'neon', 'fireIce', 'candy', 'gold'},
          equippedSkin: 'candy');
      // 100 - 1000 = -900: sai o ouro (500) -> -400, sai a bala (350) -> -50,
      // sai fogo e gelo (250) -> 200.
      final RevocationEffect e = engine.applyRevocation(s,
          redemptionId: '2', coins: 1000, removeAds: false);
      expect(e.lostSkins, <String>['gold', 'candy', 'fireIce']);
      expect(s.coins, 200);
      expect(s.ownedSkins, <String>{'neon'});
      expect(s.equippedSkin, 'neon');
    });

    test('nem os visuais cobrem: saldo fica negativo e sobrevive ao save', () {
      final ProgressState s = ProgressState(coins: 0);
      engine.applyRevocation(s,
          redemptionId: '3', coins: 3000, removeAds: false);
      expect(s.coins, -3000);
      final ProgressState back = ProgressState.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back.coins, -3000, reason: 'a dívida não some ao reabrir');
      expect(
          engine.buySkin(back, 'fireIce'), SkinPurchaseResult.notEnoughCoins);
    });

    test('o mesmo estorno vale uma vez, inclusive depois do save', () {
      final ProgressState s = ProgressState(coins: 2000);
      engine.applyRevocation(s,
          redemptionId: '4', coins: 1000, removeAds: false);
      final ProgressState back = ProgressState.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      final RevocationEffect again = engine.applyRevocation(back,
          redemptionId: '4', coins: 1000, removeAds: false);
      expect(again.applied, isFalse);
      expect(back.coins, 1000);
    });

    test('"sem anúncios" estornado: anúncios voltam', () {
      final ProgressState s = ProgressState(adsRemoved: true);
      final RevocationEffect e = engine.applyRevocation(s,
          redemptionId: '5', coins: 0, removeAds: true);
      expect(e.lostAdsRemoval, isTrue);
      expect(s.adsRemoved, isFalse);
    });
  });
}

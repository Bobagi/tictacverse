import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/models/board_theme.dart';
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
      expect(old.coins, 0, reason: 'saldo nunca nasce negativo');
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

  group('o que a Play diz que o jogador possui', () {
    test('cada produto libera exatamente o que promete', () {
      final ProgressState s = ProgressState();
      engine.applyPlayOwnership(s, <String>{'remove_ads'});
      expect(s.adsRemoved, isTrue);
      expect(s.hasSkin('aurora'), isFalse);
      engine.applyPlayOwnership(s, <String>{'starter_pack'});
      expect(s.adsRemoved, isTrue);
      expect(s.hasSkin('aurora'), isTrue);
      expect(s.hasSkin('galaxy'), isFalse);
      engine.applyPlayOwnership(s, <String>{'collection'});
      expect(s.hasSkin('galaxy'), isTrue);
      expect(s.hasTheme('royal'), isTrue);
    });

    test('item liberado pela Play se usa sem moedas e não é comprado de novo',
        () {
      final ProgressState s = ProgressState(coins: 5000);
      engine.applyPlayOwnership(s, <String>{'starter_pack'});
      expect(engine.buySkin(s, 'aurora'), SkinPurchaseResult.alreadyOwned);
      expect(s.coins, 5000, reason: 'não cobra moedas por algo já pago');
      expect(engine.equipSkin(s, 'aurora'), isTrue);
    });

    test('reembolso: some da lista, some o direito, e o visual em uso volta',
        () {
      final ProgressState s = ProgressState();
      engine.applyPlayOwnership(s, <String>{'collection'});
      engine.equipSkin(s, 'galaxy');
      engine.equipTheme(s, 'royal');
      expect(engine.applyPlayOwnership(s, <String>{}), isTrue);
      expect(s.hasSkin('galaxy'), isFalse);
      expect(s.equippedSkin, ProgressState.defaultSkinId);
      expect(s.equippedTheme, defaultBoardThemeId);
      expect(s.adsRemoved, isFalse);
    });

    test('o que foi comprado com moedas NÃO some com reembolso de outra coisa',
        () {
      final ProgressState s = ProgressState(coins: 800);
      expect(engine.buySkin(s, 'galaxy'), SkinPurchaseResult.purchased);
      engine.applyPlayOwnership(s, <String>{'collection'});
      engine.applyPlayOwnership(s, <String>{});
      expect(s.hasSkin('galaxy'), isTrue);
      expect(s.equippedSkin, 'galaxy');
    });

    test('mesma lista de novo não conta como mudança (não regrava à toa)', () {
      final ProgressState s = ProgressState();
      expect(engine.applyPlayOwnership(s, <String>{'remove_ads'}), isTrue);
      expect(engine.applyPlayOwnership(s, <String>{'remove_ads'}), isFalse);
    });

    test('a lista confirmada sobrevive ao save (jogo offline)', () {
      final ProgressState s = ProgressState();
      engine.applyPlayOwnership(s, <String>{'starter_pack'});
      final ProgressState back = ProgressState.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back.adsRemoved, isTrue);
      expect(back.hasSkin('aurora'), isTrue);
    });
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tictacverse/controllers/rewarded_ad_controller.dart';
import 'package:tictacverse/l10n/app_localizations.dart';
import 'package:tictacverse/models/progress_state.dart';
import 'package:tictacverse/models/store_product.dart';
import 'package:tictacverse/services/economy_engine.dart';
import 'package:tictacverse/services/purchase_service.dart';
import 'package:tictacverse/services/purchase_verifier.dart';
import 'package:tictacverse/services/storage_service.dart';
import 'package:tictacverse/ui/widgets/daily_bonus_sheet.dart';
import 'package:tictacverse/ui/widgets/shop_sheet.dart';

class FakeRewarded implements RewardedAdGateway {
  FakeRewarded({this.earns = true, this.ready = true});

  bool earns;
  bool ready;
  int shows = 0;

  @override
  bool get isReady => ready;

  @override
  void loadRewardedAd() {}

  @override
  Future<bool> showForReward() async {
    shows++;
    return earns;
  }
}

class FakePurchaseBackend implements PurchaseBackend {
  final StreamController<List<PurchaseDetails>> controller =
      StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  int buys = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> ids) async => ids
      .map((String id) => ProductDetails(
          id: id,
          title: id,
          description: id,
          price: r'R$ 4,99',
          rawPrice: 4.99,
          currencyCode: 'BRL'))
      .toList();

  /// O que a Play diz que o jogador possui.
  final List<PurchaseDetails> owned = <PurchaseDetails>[];

  @override
  Future<bool> buy(ProductDetails product) async {
    buys++;
    return true;
  }

  @override
  Future<List<PurchaseDetails>?> queryOwned() async =>
      List<PurchaseDetails>.of(owned);

  @override
  Future<void> complete(PurchaseDetails purchase) async {}

  @override
  String? signatureOf(PurchaseDetails purchase) => null;
}

PurchaseDetails purchase(String productId, PurchaseStatus status) =>
    PurchaseDetails(
      purchaseID: 'GPA.1',
      productID: productId,
      verificationData: PurchaseVerificationData(
          localVerificationData: '{}',
          serverVerificationData: 'tok-ui',
          source: 'google_play'),
      transactionDate: '0',
      status: status,
    );

Widget host(String language, Size size, double scale,
    void Function(BuildContext, AppLocalizations) open) {
  return MaterialApp(
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data:
          MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Builder(
      builder: (BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => open(context, AppLocalizations.of(context)!),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
}

/// O ParticleField e o Pulse animam sem fim; o pumpAndSettle nunca resolveria.
Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => StorageService.instance.progress = ProgressState());

  group('loja', () {
    testWidgets('moedas por anúncio só entram com a recompensa confirmada',
        (WidgetTester tester) async {
      final FakeRewarded ad = FakeRewarded(earns: false);
      await tester.pumpWidget(host(
          'en',
          const Size(412, 915),
          1,
          (BuildContext c, AppLocalizations l) =>
              showShopSheet(c, l, rewarded: ad)));
      await tester.tap(find.text('abrir'));
      await settle(tester);

      final Finder cta = find.byKey(const ValueKey<String>('shop-ad-coins'));
      await tester.ensureVisible(cta);
      await tester.tap(cta);
      await settle(tester);
      expect(ad.shows, 1);
      expect(StorageService.instance.progress.coins, 0,
          reason: 'fechou o anúncio antes do fim: não ganha nada');

      ad.earns = true;
      await tester.ensureVisible(cta);
      await tester.tap(cta);
      await settle(tester);
      expect(
          StorageService.instance.progress.coins, EconomyEngine.adCoinsReward);
    });

    testWidgets(
        'sem anúncio carregado o convite não aparece, e surge quando carrega',
        (WidgetTester tester) async {
      final FakeRewarded ad = FakeRewarded(ready: false);
      await tester.pumpWidget(host(
          'en',
          const Size(412, 915),
          1,
          (BuildContext c, AppLocalizations l) =>
              showShopSheet(c, l, rewarded: ad)));
      await tester.tap(find.text('abrir'));
      await settle(tester);
      final Finder cta = find.byKey(const ValueKey<String>('shop-ad-coins'));
      expect(cta, findsNothing, reason: 'prometer sem ter o que mostrar');
      ad.ready = true;
      await settle(tester);
      expect(cta, findsOneWidget);
    });

    testWidgets('tocar num visual caro sem saldo não debita',
        (WidgetTester tester) async {
      StorageService.instance.progress = ProgressState(coins: 10);
      await tester.pumpWidget(host('pt', const Size(412, 915), 1,
          (BuildContext c, AppLocalizations l) => showShopSheet(c, l)));
      await tester.tap(find.text('abrir'));
      await settle(tester);
      await tester.tap(find.text('Galáxia'));
      await settle(tester);
      expect(StorageService.instance.progress.coins, 10);
      expect(StorageService.instance.progress.ownedSkins.contains('galaxy'),
          isFalse);
    });

    testWidgets('com saldo, comprar debita e passa a mostrar "Em uso"',
        (WidgetTester tester) async {
      StorageService.instance.progress = ProgressState(coins: 260);
      await tester.pumpWidget(host('pt', const Size(412, 915), 1,
          (BuildContext c, AppLocalizations l) => showShopSheet(c, l)));
      await tester.tap(find.text('abrir'));
      await settle(tester);
      await tester.tap(find.text('Fogo e gelo'));
      await settle(tester);
      expect(StorageService.instance.progress.coins, 10);
      expect(StorageService.instance.progress.equippedSkin, 'fireIce');
      expect(find.text('Em uso'), findsOneWidget);
    });
  });

  group('loja: aba Premium (compras na Play)', () {
    late FakePurchaseBackend play;
    late PurchaseService store;

    setUp(() async {
      play = FakePurchaseBackend();
      store = PurchaseService(backend: play, verifier: PurchaseVerifier(''));
      await store.initialize();
    });

    Future<void> openCoins(WidgetTester tester,
        {String lang = 'pt',
        Size size = const Size(412, 915),
        double scale = 1}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(
          lang,
          size,
          scale,
          (BuildContext c, AppLocalizations l) => showShopSheet(c, l,
              initialTab: ShopTab.premium, purchases: store)));
      await tester.tap(find.text('abrir'));
      await settle(tester);
    }

    testWidgets('mostra os 3 produtos com o preço da Play, sem moedas à venda',
        (WidgetTester tester) async {
      await openCoins(tester);
      for (final StoreProduct p in storeCatalog) {
        final Finder f = find.byKey(ValueKey<String>('store-buy-${p.id}'));
        await tester.ensureVisible(f);
        expect(f, findsOneWidget, reason: p.id);
      }
      expect(find.byKey(const ValueKey<String>('store-buy-coins_300')),
          findsNothing);
    });

    testWidgets('toque duplo no preço abre UMA compra',
        (WidgetTester tester) async {
      await openCoins(tester);
      final Finder buy =
          find.byKey(const ValueKey<String>('store-buy-collection'));
      await tester.ensureVisible(buy);
      await settle(tester);
      expect(buy.hitTestable(), findsOneWidget);
      await tester.tap(buy);
      await tester.pump();
      await tester.tap(buy, warnIfMissed: false);
      await settle(tester);
      expect(play.buys, 1);
    });

    testWidgets('comprou a coleção: tudo liberado e a tela comemora',
        (WidgetTester tester) async {
      await openCoins(tester);
      final Finder buy =
          find.byKey(const ValueKey<String>('store-buy-collection'));
      await tester.ensureVisible(buy);
      await settle(tester);
      await tester.tap(buy);
      await settle(tester);
      final PurchaseDetails p =
          purchase('collection', PurchaseStatus.purchased);
      play.owned.add(p);
      await store.handlePurchases(<PurchaseDetails>[p]);
      await settle(tester);
      expect(StorageService.instance.progress.hasSkin('galaxy'), isTrue);
      expect(find.text('Liberado! Aproveite.'), findsOneWidget);
      expect(find.text('Tudo liberado. Obrigado!'), findsOneWidget);
    });

    testWidgets('boas-vindas oferece sem anúncios + Aurora',
        (WidgetTester tester) async {
      await openCoins(tester);
      expect(find.byKey(const ValueKey<String>('store-starter-card')),
          findsOneWidget);
      expect(
          find.text(
              'Sem anúncios para sempre + o visual Aurora, o mais caprichado do jogo.'),
          findsOneWidget);
    });

    testWidgets('comprar tema na aba Tabuleiros debita e equipa',
        (WidgetTester tester) async {
      StorageService.instance.progress = ProgressState(coins: 210);
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(
          'pt',
          const Size(412, 915),
          1,
          (BuildContext c, AppLocalizations l) => showShopSheet(c, l,
              initialTab: ShopTab.boards, purchases: store)));
      await tester.tap(find.text('abrir'));
      await settle(tester);
      await tester.tap(find.text('Pôr do sol'));
      await settle(tester);
      expect(StorageService.instance.progress.coins, 10);
      expect(StorageService.instance.progress.equippedTheme, 'sunset');
    });

    testWidgets('quem já tirou os anúncios não vê botão de pagar de novo',
        (WidgetTester tester) async {
      StorageService.instance.progress =
          ProgressState(playOwned: <String>{'remove_ads'});
      await openCoins(tester);
      expect(find.byKey(const ValueKey<String>('store-buy-remove_ads')),
          findsNothing);
      expect(find.byKey(const ValueKey<String>('store-starter-card')),
          findsNothing,
          reason: 'boas-vindas traria de novo o mesmo "sem anúncios"');
      expect(find.text('Anúncios removidos. Obrigado!'), findsOneWidget);
    });

    testWidgets('Play fora do ar: avisa em vez de mostrar botão morto',
        (WidgetTester tester) async {
      play = FakePurchaseBackend()..available = false;
      store = PurchaseService(backend: play, verifier: PurchaseVerifier(''));
      await store.initialize();
      await openCoins(tester);
      expect(find.byKey(const ValueKey<String>('store-unavailable')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('store-buy-collection')),
          findsNothing);
    });

    testWidgets('visual trancado leva ao Premium dizendo quanto falta',
        (WidgetTester tester) async {
      StorageService.instance.progress = ProgressState(coins: 10);
      await tester.pumpWidget(host(
          'pt',
          const Size(412, 915),
          1,
          (BuildContext c, AppLocalizations l) =>
              showShopSheet(c, l, purchases: store)));
      await tester.tap(find.text('abrir'));
      await settle(tester);
      await tester.ensureVisible(find.text('Galáxia'));
      await settle(tester);
      await tester.tap(find.text('Galáxia'));
      await settle(tester);
      expect(StorageService.instance.progress.coins, 10);
      expect(
          find.text(
              'Faltam 790 moedas. Jogue para ganhar ou leve tudo na Coleção completa.'),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('store-buy-collection')),
          findsOneWidget);
    });

    testWidgets(
        'toque duplo no visual trancado não abre compra na aba que surge',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      StorageService.instance.progress = ProgressState(coins: 10);
      await tester.pumpWidget(host(
          'pt',
          const Size(412, 915),
          1,
          (BuildContext c, AppLocalizations l) =>
              showShopSheet(c, l, purchases: store)));
      await tester.tap(find.text('abrir'));
      await settle(tester);
      await tester.tap(find.text('Galáxia'));
      await tester.pump(const Duration(milliseconds: 120));
      final Finder price =
          find.byKey(const ValueKey<String>('store-buy-starter_pack'));
      expect(price.hitTestable(), findsOneWidget,
          reason: 'o toque tem de cair no preço, senão o teste passa à toa');
      await tester.tap(price);
      await tester.pump(const Duration(milliseconds: 120));
      expect(play.buys, 0, reason: 'o segundo toque do dedo caiu no preço');
      await settle(tester);
      await tester.tap(price);
      await settle(tester);
      expect(play.buys, 1, reason: 'depois da trava, compra normal');
    });

    for (final String lang in <String>['pt', 'en', 'es', 'hi', 'bn', 'ne']) {
      testWidgets('aba Premium sem estouro de layout em 320x568 ($lang, 1,3x)',
          (WidgetTester tester) async {
        await openCoins(tester,
            lang: lang, size: const Size(320, 568), scale: 1.3);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey<String>('shop-tab-skins')));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey<String>('shop-tab-boards')));
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(
            find.byKey(const ValueKey<String>('theme-ocean')), findsOneWidget);
      });
    }
  });

  group('bônus diário', () {
    testWidgets('resgata uma vez e o dobro só vem com o anúncio assistido',
        (WidgetTester tester) async {
      final FakeRewarded ad = FakeRewarded(earns: false);
      await tester.pumpWidget(host(
          'en',
          const Size(412, 915),
          1,
          (BuildContext c, AppLocalizations l) =>
              showDailyBonusSheet(c, l, rewarded: ad)));
      await tester.tap(find.text('abrir'));
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey<String>('daily-claim')));
      await settle(tester);
      expect(StorageService.instance.progress.coins, 20);
      expect(find.byKey(const ValueKey<String>('daily-claim')), findsNothing,
          reason: 'resgatado: o botão some para não pagar duas vezes');

      final Finder dbl = find.byKey(const ValueKey<String>('daily-double'));
      await tester.tap(dbl);
      await settle(tester);
      expect(StorageService.instance.progress.coins, 20);

      ad.earns = true;
      await tester.tap(dbl);
      await settle(tester);
      expect(StorageService.instance.progress.coins, 40);
      expect(dbl, findsNothing, reason: 'dobrou uma vez, a oferta sai');
    });
  });

  // Matriz idioma x tela: hi/bn/ne têm texto mais longo que o inglês.
  const List<(String, Size, double)> screens = <(String, Size, double)>[
    ('320x568', Size(320, 568), 1.0),
    ('360x640 fonte 1.4x', Size(360, 640), 1.4),
    ('412x915', Size(412, 915), 1.0),
  ];
  for (final (String name, Size size, double scale) in screens) {
    for (final String lang in <String>['en', 'pt', 'es', 'hi', 'bn', 'ne']) {
      testWidgets('loja e bônus sem erro de layout em $name ($lang)',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        StorageService.instance.progress = ProgressState(coins: 260);

        await tester.pumpWidget(host(
            lang,
            size,
            scale,
            (BuildContext c, AppLocalizations l) =>
                showShopSheet(c, l, rewarded: FakeRewarded())));
        await tester.tap(find.text('abrir'));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(4, 4));
        await settle(tester);

        await tester.pumpWidget(host(
            lang,
            size,
            scale,
            (BuildContext c, AppLocalizations l) =>
                showDailyBonusSheet(c, l, rewarded: FakeRewarded())));
        await tester.tap(find.text('abrir'));
        await settle(tester);
        expect(tester.takeException(), isNull);
        final Finder claim = find.byKey(const ValueKey<String>('daily-claim'));
        await tester.ensureVisible(claim);
        expect(claim.hitTestable(), findsOneWidget);
        await tester.tap(claim);
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

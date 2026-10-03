import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/controllers/rewarded_ad_controller.dart';
import 'package:tictacverse/l10n/app_localizations.dart';
import 'package:tictacverse/models/progress_state.dart';
import 'package:tictacverse/services/economy_engine.dart';
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

Widget host(String language, Size size, double scale,
    void Function(BuildContext, AppLocalizations) open) {
  return MaterialApp(
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
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
      await tester.pumpWidget(host('en', const Size(412, 915), 1,
          (BuildContext c, AppLocalizations l) => showShopSheet(c, l, rewarded: ad)));
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
      expect(StorageService.instance.progress.coins,
          EconomyEngine.adCoinsReward);
    });

    testWidgets('sem anúncio carregado o convite não aparece, e surge quando carrega',
        (WidgetTester tester) async {
      final FakeRewarded ad = FakeRewarded(ready: false);
      await tester.pumpWidget(host('en', const Size(412, 915), 1,
          (BuildContext c, AppLocalizations l) => showShopSheet(c, l, rewarded: ad)));
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
      StorageService.instance.progress = ProgressState(coins: 130);
      await tester.pumpWidget(host('pt', const Size(412, 915), 1,
          (BuildContext c, AppLocalizations l) => showShopSheet(c, l)));
      await tester.tap(find.text('abrir'));
      await settle(tester);
      await tester.tap(find.text('Neon'));
      await settle(tester);
      expect(StorageService.instance.progress.coins, 10);
      expect(StorageService.instance.progress.equippedSkin, 'neon');
      expect(find.text('Em uso'), findsOneWidget);
    });
  });

  group('bônus diário', () {
    testWidgets('resgata uma vez e o dobro só vem com o anúncio assistido',
        (WidgetTester tester) async {
      final FakeRewarded ad = FakeRewarded(earns: false);
      await tester.pumpWidget(host('en', const Size(412, 915), 1,
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

        await tester.pumpWidget(host(lang, size, scale,
            (BuildContext c, AppLocalizations l) =>
                showShopSheet(c, l, rewarded: FakeRewarded())));
        await tester.tap(find.text('abrir'));
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(4, 4));
        await settle(tester);

        await tester.pumpWidget(host(lang, size, scale,
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

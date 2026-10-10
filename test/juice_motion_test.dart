import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/l10n/app_localizations.dart';
import 'package:tictacverse/ui/widgets/juice/motion.dart';
import 'package:tictacverse/ui/widgets/starter_offer_dialog.dart';

/// Conta quantas vezes o State do filho nasce: se o efeito trocar a forma da
/// árvore no meio da animação, o filho remonta e este número sobe.
class _Probe extends StatefulWidget {
  const _Probe();
  static int created = 0;
  @override
  State<_Probe> createState() {
    created++;
    return _ProbeState();
  }
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) => const SizedBox(width: 40, height: 40);
}

Future<void> settle(WidgetTester tester, {int frames = 20}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('efeitos não remontam o filho', () {
    final Map<String, Widget Function(Widget)> effects =
        <String, Widget Function(Widget)>{
      'Wobble': (Widget c) => Wobble(child: c),
      'Bob': (Widget c) => Bob(child: c),
      'Breathe': (Widget c) => Breathe(child: c),
      'Shine': (Widget c) => Shine(child: c),
      'BumpOnChange': (Widget c) => BumpOnChange(value: 1, child: c),
    };
    effects.forEach((String name, Widget Function(Widget) wrap) {
      testWidgets(name, (WidgetTester tester) async {
        _Probe.created = 0;
        await tester.pumpWidget(
            MaterialApp(home: Center(child: wrap(const _Probe()))));
        await settle(tester, frames: 40);
        expect(_Probe.created, 1);
      });
    });

    testWidgets('Wobble ligando e desligando mantém o filho',
        (WidgetTester tester) async {
      _Probe.created = 0;
      Widget app(bool on) => MaterialApp(
          home: Center(child: Wobble(active: on, child: const _Probe())));
      await tester.pumpWidget(app(false));
      await tester.pumpWidget(app(true));
      await settle(tester);
      await tester.pumpWidget(app(false));
      await settle(tester);
      expect(_Probe.created, 1);
    });

    testWidgets('BumpOnChange pula quando o valor muda e volta ao normal',
        (WidgetTester tester) async {
      Widget app(int v) => MaterialApp(
          home: Center(
              child: BumpOnChange(
                  value: v, child: const SizedBox(width: 10, height: 10))));
      await tester.pumpWidget(app(1));
      await tester.pumpWidget(app(2));
      await tester.pump(const Duration(milliseconds: 16));
      final Transform t = tester.widget<Transform>(find.byType(Transform).last);
      expect(t.transform.getMaxScaleOnAxis(), greaterThan(1.05));
      await settle(tester);
      final Transform after =
          tester.widget<Transform>(find.byType(Transform).last);
      expect(after.transform.getMaxScaleOnAxis(), closeTo(1, 0.001));
    });
  });

  group('oferta de boas-vindas', () {
    Future<bool?> open(WidgetTester tester, String lang,
        {Size size = const Size(320, 568), double scale = 1.3}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      bool? result;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              result = await showStarterOfferDialog(context,
                  localization: AppLocalizations.of(context)!,
                  price: r'R$ 9,99');
            },
            child: const Text('abrir'),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await settle(tester);
      return result;
    }

    for (final String lang in <String>['pt', 'en', 'es', 'hi', 'bn', 'ne']) {
      testWidgets('cabe em 320x568 com fonte 1,3x ($lang)',
          (WidgetTester tester) async {
        await open(tester, lang);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey<String>('starter-offer-badge')),
            findsOneWidget);
      });
    }

    testWidgets('"ver oferta" devolve true; "agora não" devolve false',
        (WidgetTester tester) async {
      bool? got;
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Future<void> pump() => tester.pumpWidget(MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('pt'),
            home: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () async {
                  got = await showStarterOfferDialog(context,
                      localization: AppLocalizations.of(context)!);
                },
                child: const Text('abrir'),
              ),
            ),
          ));
      await pump();
      await tester.tap(find.text('abrir'));
      await settle(tester);
      expect(find.text('Ver oferta'), findsOneWidget,
          reason: 'sem preço da Play, o botão não inventa número');
      await tester.tap(find.byKey(const ValueKey<String>('starter-offer-see')));
      await settle(tester);
      expect(got, isTrue);
      await tester.tap(find.text('abrir'));
      await settle(tester);
      await tester
          .tap(find.byKey(const ValueKey<String>('starter-offer-later')));
      await settle(tester);
      expect(got, isFalse);
    });

    testWidgets('com "reduzir animações" abre parado e sem erro',
        (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await open(tester, 'pt', size: const Size(412, 915), scale: 1);
      expect(tester.takeException(), isNull);
    });
  });
}

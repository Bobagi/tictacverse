import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/l10n/app_localizations.dart';
import 'package:tictacverse/ui/widgets/settings_sheet.dart';

/// Regressão da v1.11.0: o painel ganhou itens e o botão "Buscar atualizações",
/// que era o último, ficou cortado fora da tela (o sheet trava em 9/16 da
/// altura sem `isScrollControlled`). O jogador não conseguia mais atualizar.
void main() {
  Widget host(String language, double textScale) {
    return MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () =>
                  showSettingsSheet(context, AppLocalizations.of(context)!),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
  }

  const List<(String, Size, double)> screens = <(String, Size, double)>[
    ('320x568', Size(320, 568), 1.0),
    ('360x640', Size(360, 640), 1.0),
    ('360x640 fonte 1.4x', Size(360, 640), 1.4),
    ('320x568 fonte 1.4x', Size(320, 568), 1.4),
    ('412x915', Size(412, 915), 1.0),
  ];

  for (final (String name, Size size, double scale) in screens) {
    for (final String language in <String>['en', 'pt', 'es', 'hi', 'bn', 'ne']) {
      testWidgets('botão de atualizar visível e tocável em $name ($language)',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(language, scale));
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final Finder update = find.byIcon(Icons.system_update_rounded);
        expect(update, findsOneWidget);
        // Sem rolar nada: o item precisa estar na tela e receber toque.
        expect(update.hitTestable(), findsOneWidget,
            reason: 'o botão de atualizar não pode depender de rolagem');
        expect(tester.getRect(update).bottom, lessThanOrEqualTo(size.height));
      });
    }
  }

  testWidgets('o resto do painel (vibração) continua alcançável rolando',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host('pt', 1.4));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Vibração'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Vibração').hitTestable(), findsOneWidget);
  });
}

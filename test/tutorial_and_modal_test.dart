import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/l10n/app_localizations.dart';
import 'package:tictacverse/ui/widgets/game_over_modal.dart';
import 'package:tictacverse/ui/widgets/ultimate_tutorial.dart';

Widget host(String lang, Widget Function(BuildContext) open,
    {double scale = 1}) {
  return MaterialApp(
    locale: Locale(lang),
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
            onPressed: () => showDialog<void>(
                context: context, builder: (BuildContext c) => open(c)),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
}

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Toca no centro de uma casa (tabuleiro, casa) do tabuleiro 9x9 do tutorial.
Future<void> tapCell(WidgetTester tester, int board, int inner) async {
  final Finder area = find.byKey(const ValueKey<String>('tutorial-board'));
  await tester.ensureVisible(area);
  await settle(tester);
  final Rect r = tester.getRect(area);
  final double cell = r.width / 9;
  final int row = (board ~/ 3) * 3 + inner ~/ 3;
  final int col = (board % 3) * 3 + inner % 3;
  await tester
      .tapAt(r.topLeft + Offset((col + 0.5) * cell, (row + 0.5) * cell));
}

Future<void> tapNext(WidgetTester tester) async {
  final Finder next = find.byKey(const ValueKey<String>('tutorial-next'));
  await tester.ensureVisible(next);
  await settle(tester);
  await tester.tap(next);
}

void main() {
  group('tutorial do Super Jogo da Velha', () {
    Future<void> open(WidgetTester tester, {String lang = 'pt'}) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(lang, (BuildContext c) {
        return UltimateTutorial(localization: AppLocalizations.of(c)!);
      }));
      await tester.tap(find.text('abrir'));
      await settle(tester);
    }

    testWidgets('o jogador faz a jogada e vê a regra acontecer',
        (WidgetTester tester) async {
      await open(tester);
      expect(find.text('1/5'), findsOneWidget);
      await tapNext(tester);
      await settle(tester);
      expect(find.text('2/5'), findsOneWidget);

      // Toque fora da casa indicada: nada acontece.
      await tapCell(tester, 0, 0);
      await settle(tester);
      expect(find.text('2/5'), findsOneWidget);

      await tapCell(tester, 4, 2);
      await settle(tester);
      expect(find.text('3/5'), findsOneWidget);
      await tapNext(tester);
      await settle(tester);
      expect(find.text('4/5'), findsOneWidget);

      await tapCell(tester, 4, 0);
      await settle(tester);
      expect(find.text('5/5'), findsOneWidget);
      await tapNext(tester);
      await settle(tester);
      expect(find.byType(UltimateTutorial), findsNothing);
    });

    testWidgets('pular fecha na hora', (WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('tutorial-skip')));
      await settle(tester);
      expect(find.byType(UltimateTutorial), findsNothing);
    });

    for (final String lang in <String>['pt', 'en', 'es', 'hi', 'bn', 'ne']) {
      testWidgets('cabe em 360x640 sem estouro ($lang)',
          (WidgetTester tester) async {
        await open(tester, lang: lang);
        for (int i = 0; i < 2; i++) {
          expect(tester.takeException(), isNull);
        }
        await tapNext(tester);
        await settle(tester);
        await tapCell(tester, 4, 2);
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('fim de partida', () {
    Widget modal({Future<void> Function()? onShare, String? banner}) =>
        GameOverModal(
          title: 'Vitória!',
          subtitle: 'x',
          onPlayAgain: () {},
          onBackToMenu: () {},
          banner: banner,
          onShare: onShare,
        );

    testWidgets('compartilhar só aparece quando há o que comemorar',
        (WidgetTester tester) async {
      int shared = 0;
      await tester.pumpWidget(host(
          'pt',
          (_) => modal(onShare: () async {
                shared++;
              })));
      await tester.tap(find.text('abrir'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('game-over-share')));
      expect(shared, 1);
    });

    testWidgets('sem vitória, sem botão de compartilhar',
        (WidgetTester tester) async {
      await tester.pumpWidget(host('pt', (_) => modal()));
      await tester.tap(find.text('abrir'));
      await settle(tester);
      expect(
          find.byKey(const ValueKey<String>('game-over-share')), findsNothing);
    });

    for (final String lang in <String>['pt', 'en', 'es', 'hi', 'bn', 'ne']) {
      testWidgets('faixa do desafio e compartilhar cabem em 320x568 ($lang)',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(host(
            lang,
            (BuildContext c) => modal(
                onShare: () async {},
                banner: AppLocalizations.of(c)!.challengeLate(30)),
            scale: 1.3));
        await tester.tap(find.text('abrir'));
        await settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey<String>('game-over-banner')),
            findsOneWidget);
      });
    }
  });
}

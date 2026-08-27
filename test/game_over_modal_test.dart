import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/l10n/app_localizations.dart';
import 'package:tictacverse/models/achievement.dart';
import 'package:tictacverse/services/progression_engine.dart';
import 'package:tictacverse/ui/widgets/game_over_modal.dart';

/// Resultado de partida sem conquista, para os asserts olharem só o XP.
ProgressionResult matchResult({
  int xpGained = 35,
  int levelBefore = 1,
  int levelAfter = 1,
}) {
  return ProgressionResult(
    xpGained: xpGained,
    levelBefore: levelBefore,
    levelAfter: levelAfter,
    newlyUnlocked: const <AchievementDefinition>[],
  );
}

Widget host({
  ProgressionResult? progression,
  Future<ProgressionResult?> Function()? onWatchAdForDoubleXp,
  String languageCode = 'en',
}) {
  return MaterialApp(
    locale: Locale(languageCode),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: GameOverModal(
        title: 'Winner',
        subtitle: 'X',
        onPlayAgain: () {},
        onBackToMenu: () {},
        progression: progression,
        onWatchAdForDoubleXp: onWatchAdForDoubleXp,
      ),
    ),
  );
}

void main() {
  Finder offerButton() => find.byType(OutlinedButton);

  group('oferta de dobrar o XP', () {
    testWidgets('sem callback a oferta não aparece', (WidgetTester tester) async {
      await tester.pumpWidget(host(progression: matchResult()));
      await tester.pumpAndSettle();

      expect(offerButton(), findsNothing);
      expect(find.text('+35 XP'), findsOneWidget);
    });

    testWidgets('com callback a oferta aparece', (WidgetTester tester) async {
      await tester.pumpWidget(host(
        progression: matchResult(),
        onWatchAdForDoubleXp: () async => null,
      ));
      await tester.pumpAndSettle();

      expect(offerButton(), findsOneWidget);
      expect(find.text('Watch an ad, double your XP'), findsOneWidget);
    });

    testWidgets('partida sem XP não recebe oferta', (WidgetTester tester) async {
      await tester.pumpWidget(host(
        progression: matchResult(xpGained: 0),
        onWatchAdForDoubleXp: () async => matchResult(),
      ));
      await tester.pumpAndSettle();

      expect(offerButton(), findsNothing);
    });

    testWidgets('anúncio não assistido NÃO credita XP', (WidgetTester tester) async {
      int calls = 0;
      await tester.pumpWidget(host(
        progression: matchResult(),
        onWatchAdForDoubleXp: () async {
          calls += 1;
          return null; // jogador fechou antes do fim
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(offerButton());
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.text('+35 XP'), findsOneWidget,
          reason: 'o XP não pode mudar sem o anúncio ter sido assistido');
      expect(find.text("The ad didn't load. Try again next match."),
          findsOneWidget);
      expect(offerButton(), findsNothing,
          reason: 'sem anúncio para exibir, o convite sai de cena');
    });

    testWidgets('anúncio assistido dobra o XP exibido e encerra a oferta',
        (WidgetTester tester) async {
      await tester.pumpWidget(host(
        progression: matchResult(),
        onWatchAdForDoubleXp: () async =>
            matchResult(xpGained: 35, levelBefore: 1, levelAfter: 2),
      ));
      await tester.pumpAndSettle();

      await tester.tap(offerButton());
      await tester.pumpAndSettle();

      expect(find.text('+70 XP'), findsOneWidget);
      expect(find.text('Level 2 reached!'), findsOneWidget,
          reason: 'a subida de nível vinda do bônus tem de aparecer');
      expect(find.text('XP doubled!'), findsOneWidget);
      expect(offerButton(), findsNothing);
    });

    testWidgets('toque duplo enquanto o anúncio abre credita UMA vez só',
        (WidgetTester tester) async {
      int calls = 0;
      final Completer<ProgressionResult?> pending =
          Completer<ProgressionResult?>();
      await tester.pumpWidget(host(
        progression: matchResult(),
        onWatchAdForDoubleXp: () {
          calls += 1;
          return pending.future;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(offerButton(), warnIfMissed: false);
      await tester.pump();
      // Segundo toque com o anúncio ainda no ar.
      await tester.tap(offerButton(), warnIfMissed: false);
      await tester.pump();

      expect(calls, 1, reason: 'dois toques não podem virar dois anúncios');

      pending.complete(matchResult());
      await tester.pumpAndSettle();

      expect(find.text('+70 XP'), findsOneWidget);
      expect(find.text('+105 XP'), findsNothing,
          reason: 'crédito duplo dobraria de novo');
    });
  });

  group('cabe nas telas pequenas (o modal cresceu com a oferta)', () {
    // 360x640 é o viewport onde a lista de modos ainda cortava; 320x568 é o
    // menor Android que a ficha ainda atende. Overflow de layout vira exceção
    // no teste, então basta renderizar e afirmar que tudo está lá.
    for (final (String name, Size size) in <(String, Size)>[
      ('360x640', Size(360, 640)),
      ('320x568', Size(320, 568)),
    ]) {
      testWidgets('sem overflow em $name com oferta, nível e conquista',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(
          progression: matchResult(levelBefore: 4, levelAfter: 5),
          onWatchAdForDoubleXp: () async => matchResult(),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(offerButton(), findsOneWidget);
        expect(find.text('Play Again'), findsOneWidget);
        expect(find.text('Back to Menu'), findsOneWidget);
      });
    }

    testWidgets('a oferta não encosta na linha de ações (alvo de toque separado)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(
        progression: matchResult(),
        onWatchAdForDoubleXp: () async => matchResult(),
      ));
      await tester.pumpAndSettle();

      final Rect offer = tester.getRect(offerButton());
      final Rect playAgain = tester.getRect(find.text('Play Again'));

      // Clique acidental em anúncio foi o que derrubou a conta do AdMob em
      // 2026-07: o convite tem de ficar visivelmente longe do botão primário.
      expect(playAgain.top - offer.bottom, greaterThanOrEqualTo(16.0),
          reason: 'folga insuficiente entre a oferta e "jogar de novo"');
    });
  });

  group('idiomas de textos longos (hi/bn/ne são o público real do app)', () {
    for (final String language in <String>['pt', 'es', 'hi', 'bn', 'ne']) {
      testWidgets('sem overflow em $language na menor tela (320x568)',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(
          languageCode: language,
          progression: matchResult(levelBefore: 4, levelAfter: 5),
          onWatchAdForDoubleXp: () async => matchResult(),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(offerButton(), findsOneWidget);
      });
    }
  });
}

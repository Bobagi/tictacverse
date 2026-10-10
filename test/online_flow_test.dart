import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictacverse/l10n/app_localizations.dart';
import 'package:tictacverse/models/online_match.dart';
import 'package:tictacverse/services/metrics_service.dart';
import 'package:tictacverse/services/online/fake_online_api.dart';
import 'package:tictacverse/services/online/online_service.dart';
import 'package:tictacverse/services/storage_service.dart';
import 'package:tictacverse/ui/screens/online_lobby_screen.dart';
import 'package:tictacverse/ui/screens/online_match_screen.dart';
import 'package:tictacverse/ui/widgets/ultimate_macro_board.dart';

/// Fluxo do desafio online contra o servidor de mentira: criar convite, o
/// amigo entrar, jogar, receber a jogada dele e desistir. E a matriz idioma x
/// tela das duas telas novas (hindi, bengali e nepali têm texto mais longo).

/// As telas têm efeito contínuo (respiração, brilho): pumpAndSettle nunca
/// terminaria, então avança o relógio em passos.
Future<void> frames(WidgetTester tester, {int count = 10}) async {
  for (int i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget host(Widget home, {String language = 'pt', double textScale = 1}) {
  return MaterialApp(
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}

void main() {
  late FakeOnlineApi fake;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageService.instance.load();
    fake = FakeOnlineApi(autoFriend: false);
    OnlineService.instance.api = fake;
    OnlineService.instance.profile.value = null;
  });

  /// Sai da tela e deixa os relógios do long poll falso vencerem.
  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  testWidgets('criar convite, amigo entra, jogada vai e volta, desistir',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        host(OnlineLobbyScreen(metricsService: MetricsService())));
    await frames(tester);
    expect(find.text('Nenhuma partida ainda. Crie um convite e mande para um amigo.'),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('online-create')));
    await frames(tester);
    expect(find.byType(OnlineMatchScreen), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('online-code')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('online-share')), findsOneWidget);
    expect(find.byType(UltimateMacroBoard), findsNothing,
        reason: 'sem amigo, mostra o convite e não o tabuleiro');

    final OnlineMatch created = (await fake.matches(FakeOnlineApi.token)).single;
    fake.friendJoins(created.id);
    await frames(tester, count: 15);
    expect(find.byType(UltimateMacroBoard), findsOneWidget);
    expect(find.text('Sua vez!'), findsOneWidget);

    // Toque no centro: mini-tabuleiro 4, casa 4.
    await tester.tapAt(tester.getCenter(find.byType(UltimateMacroBoard)));
    await frames(tester);
    OnlineMatch now = (await fake.matches(FakeOnlineApi.token)).single;
    expect(now.moves, <(int, int)>[(4, 4)]);
    expect(find.text('Vez do amigo'), findsOneWidget);

    // Toque fora da vez não manda nada.
    await tester.tapAt(tester.getTopLeft(find.byType(UltimateMacroBoard)) +
        const Offset(20, 20));
    await frames(tester);
    expect((await fake.matches(FakeOnlineApi.token)).single.moves.length, 1);

    fake.friendMoves(created.id);
    await frames(tester, count: 15);
    expect(find.text('Sua vez!'), findsOneWidget,
        reason: 'a jogada do amigo chega sozinha pelo long poll');

    await tester.tap(find.byKey(const ValueKey<String>('online-resign')));
    await frames(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Desistir'));
    await frames(tester, count: 15);
    now = (await fake.matches(FakeOnlineApi.token)).single;
    expect(now.status, OnlineStatus.finished);
    expect(find.text('Seu amigo venceu'), findsOneWidget);
    expect(find.text('Revanche'), findsWidgets);
    expect(find.text('Você desistiu.'), findsOneWidget);

    await leave(tester);
  });

  testWidgets('código inválido avisa e não chama o servidor',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        host(OnlineLobbyScreen(metricsService: MetricsService())));
    await frames(tester);
    await tester.enterText(
        find.byKey(const ValueKey<String>('online-code-field')), 'K0P2QX');
    await tester.tap(find.byKey(const ValueKey<String>('online-join')));
    await frames(tester);
    expect(find.text('Código inválido. Confira as 6 letras.'), findsOneWidget);
    expect(find.byType(OnlineMatchScreen), findsNothing);
    await leave(tester);
  });

  testWidgets('link de convite abre direto a partida', (WidgetTester tester) async {
    await tester.pumpWidget(host(OnlineLobbyScreen(
        metricsService: MetricsService(), joinCode: 'K7P2QX')));
    await frames(tester);
    expect(find.byType(OnlineMatchScreen), findsOneWidget);
    expect(find.byType(UltimateMacroBoard), findsOneWidget);
    await leave(tester);
  });

  testWidgets('convite não encontrado vira aviso, não tela quebrada',
      (WidgetTester tester) async {
    await tester.pumpWidget(host(OnlineLobbyScreen(
        metricsService: MetricsService(), joinCode: 'ZZZZZZ')));
    await frames(tester);
    expect(find.byType(OnlineMatchScreen), findsNothing);
    expect(find.text('Não achamos esse convite. Confira o código.'),
        findsOneWidget);
    await leave(tester);
  });

  const List<(String, Size, double)> screens = <(String, Size, double)>[
    ('320x568', Size(320, 568), 1.0),
    ('360x640 fonte 1.3x', Size(360, 640), 1.3),
  ];
  for (final (String name, Size size, double scale) in screens) {
    for (final String language in <String>['pt', 'en', 'es', 'hi', 'bn', 'ne']) {
      testWidgets('lobby, convite e partida cabem em $name ($language)',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        // Uma partida em cada estado na lista.
        final OnlineMatch waiting = await fake.create(FakeOnlineApi.token);
        final OnlineMatch joined = await fake.join(FakeOnlineApi.token, 'K7P2QX');
        await fake.create(FakeOnlineApi.token);
        fake.friendJoins((await fake.create(FakeOnlineApi.token)).id);

        await tester.pumpWidget(host(
            OnlineLobbyScreen(metricsService: MetricsService()),
            language: language,
            textScale: scale));
        await frames(tester);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(host(
            OnlineMatchScreen(initial: waiting, metricsService: MetricsService()),
            language: language,
            textScale: scale));
        await frames(tester);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey<String>('online-share')).hitTestable(),
            findsOneWidget,
            reason: 'mandar o convite é a ação da tela');

        await tester.pumpWidget(host(
            OnlineMatchScreen(initial: joined, metricsService: MetricsService()),
            language: language,
            textScale: scale));
        await frames(tester);
        expect(tester.takeException(), isNull);
        await leave(tester);
      });
    }
  }
}

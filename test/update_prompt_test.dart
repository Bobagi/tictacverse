import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/l10n/app_localizations.dart';
import 'package:tictacverse/services/update_prompt.dart';
import 'package:tictacverse/services/update_service.dart';
import 'package:tictacverse/ui/widgets/update_available_dialog.dart';

/// O jogador reclamou (2026-09-26): nao havia aviso de versao nova ao abrir o
/// jogo. Estes testes travam as regras do aviso e o dialogo em todos os idiomas.
void main() {
  UpdatePromptCoordinator coordinator(
    UpdateService updates, {
    bool mounted = true,
    List<bool>? topRoute,
    required List<String> log,
  }) {
    final List<bool> top = topRoute ?? <bool>[true];
    int call = 0;
    return UpdatePromptCoordinator(
      updates: updates,
      isMounted: () => mounted,
      isTopRoute: () => top[call++ < top.length ? call - 1 : top.length - 1],
      show: () async => log.add('mostrou'),
      retryDelay: Duration.zero,
    );
  }

  group('quando o aviso aparece', () {
    test('há versão nova: avisa', () async {
      final UpdateService updates = UpdateService.forTest()
        ..updateAvailable.value = true;
      final List<String> log = <String>[];
      expect(await coordinator(updates, log: log).run(), isTrue);
      expect(log, <String>['mostrou']);
    });

    test('sem versão nova: não incomoda', () async {
      final UpdateService updates = UpdateService.forTest();
      final List<String> log = <String>[];
      expect(await coordinator(updates, log: log).run(), isFalse);
      expect(log, isEmpty);
    });

    test('só uma vez por sessão (voltar à home não repete)', () async {
      final UpdateService updates = UpdateService.forTest()
        ..updateAvailable.value = true;
      final List<String> log = <String>[];
      await coordinator(updates, log: log).run();
      expect(await coordinator(updates, log: log).run(), isFalse);
      expect(log, <String>['mostrou']);
    });

    test('espera um diálogo já aberto sair da frente', () async {
      final UpdateService updates = UpdateService.forTest()
        ..updateAvailable.value = true;
      final List<String> log = <String>[];
      // Duas consultas com outro diálogo por cima, depois livre.
      final bool shown = await coordinator(updates,
              topRoute: <bool>[false, false, true], log: log)
          .run();
      expect(shown, isTrue);
      expect(log, <String>['mostrou']);
    });

    test('desiste se o diálogo nunca sai (não empilha dois avisos)', () async {
      final UpdateService updates = UpdateService.forTest()
        ..updateAvailable.value = true;
      final List<String> log = <String>[];
      expect(await coordinator(updates, topRoute: <bool>[false], log: log).run(),
          isFalse);
      expect(log, isEmpty);
      expect(updates.promptedThisSession, isFalse,
          reason: 'não avisou, então pode tentar de novo na próxima abertura');
    });

    test('tela que já saiu não mostra nada', () async {
      final UpdateService updates = UpdateService.forTest()
        ..updateAvailable.value = true;
      final List<String> log = <String>[];
      expect(await coordinator(updates, mounted: false, log: log).run(), isFalse);
      expect(log, isEmpty);
    });
  });

  group('diálogo', () {
    Widget host(String language, {required Future<UpdateCheckOutcome> Function() onUpdate}) {
      return MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showUpdateAvailableDialog(
                  context,
                  AppLocalizations.of(context)!,
                  onUpdate: onUpdate,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('"Atualizar" dispara a atualização UMA vez e fecha',
        (WidgetTester tester) async {
      int calls = 0;
      await tester.pumpWidget(host('pt', onUpdate: () async {
        calls++;
        return UpdateCheckOutcome.updateStarted;
      }));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Nova versão disponível'), findsOneWidget);

      await tester.tap(find.text('Atualizar'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Nova versão disponível'), findsNothing);
    });

    testWidgets('"Depois" fecha sem atualizar', (WidgetTester tester) async {
      int calls = 0;
      await tester.pumpWidget(host('en', onUpdate: () async {
        calls++;
        return UpdateCheckOutcome.updateStarted;
      }));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('New version available'), findsNothing);
    });

    for (final String language in <String>['en', 'pt', 'es', 'hi', 'bn', 'ne']) {
      testWidgets('cabe na menor tela em $language, com fonte grande',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MediaQuery(
          data: const MediaQueryData(size: Size(320, 568), textScaler: TextScaler.linear(1.4)),
          child: host(language, onUpdate: () async => UpdateCheckOutcome.failed),
        ));
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
      });
    }
  });
}

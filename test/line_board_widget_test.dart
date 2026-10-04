import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/controllers/game_controller.dart';
import 'package:tictacverse/l10n/app_localizations.dart';
import 'package:tictacverse/models/cpu_difficulty.dart';
import 'package:tictacverse/models/game_mode.dart';
import 'package:tictacverse/models/player_marker.dart';
import 'package:tictacverse/services/metrics_service.dart';
import 'package:tictacverse/ui/screens/game_screen.dart';
import 'package:tictacverse/ui/widgets/game_board.dart';
import 'package:tictacverse/ui/widgets/neon_win_line.dart';
import 'package:tictacverse/ui/widgets/piece_glyph.dart';

GameModeDefinition modeOf(GameModeType type) => createGameModes()
    .firstWhere((GameModeDefinition mode) => mode.type == type);

Widget localized(Widget home, {String language = 'en', double textScale = 1}) {
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

/// Casas do tabuleiro, na ordem dos índices.
Finder cells() => find.descendant(
      of: find.byType(GameBoard),
      matching: find.byType(GestureDetector),
    );

/// Roda [body] com a plataforma fora do Android: os ids de anúncio ficam
/// vazios e nenhum plugin de anúncio é chamado no teste.
Future<void> withoutAdPlugins(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  const List<String> languages = <String>['en', 'pt', 'es', 'hi', 'bn', 'ne'];

  for (final GameModeType mode in <GameModeType>[
    GameModeType.fourByFour,
    GameModeType.gomoku,
  ]) {
    for (final String language in languages) {
      testWidgets(
          '${mode.name}: tela de jogo em 320x568, fonte 1.3x ($language), '
          'sem estouro e o toque coloca a peça', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await withoutAdPlugins(() async {
          final GameController controller = GameController(
            modeDefinition: modeOf(mode),
            playAgainstCpu: false,
          );
          await tester.pumpWidget(localized(
            GameScreen(controller: controller, metricsService: MetricsService()),
            language: language,
            textScale: 1.3,
          ));
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);

          final int n = mode.boardSize;
          expect(cells(), findsNWidgets(n * n));

          // A dica da HUD fala o tamanho da linha deste modo.
          final AppLocalizations l = await AppLocalizations.delegate
              .load(Locale(language));
          expect(
            find.text(mode == GameModeType.gomoku
                ? l.winInstructionFive
                : l.winInstructionFour),
            findsOneWidget,
          );

          final int target = n * n - 1; // canto de baixo à direita
          await tester.tap(cells().at(target));
          await tester.pump(const Duration(milliseconds: 400));
          expect(controller.state.board[target], PlayerMarker.cross);
          expect(controller.state.currentPlayer, PlayerMarker.nought);
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(const SizedBox());
        });
      });
    }
  }

  testWidgets('Cinco em linha contra a CPU: a máquina responde depois da pausa',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await withoutAdPlugins(() async {
      final GameController controller = GameController(
        modeDefinition: modeOf(GameModeType.gomoku),
        playAgainstCpu: true,
        cpuDifficulty: CpuDifficulty.hard,
      );
      await tester.pumpWidget(localized(
        GameScreen(controller: controller, metricsService: MetricsService()),
      ));
      await tester.pump();
      await tester.tap(cells().at(44));
      await tester.pump();
      expect(controller.state.board.whereType<PlayerMarker>().length, 1);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(seconds: 1));
      expect(controller.state.board[44], PlayerMarker.cross);
      expect(
          controller.state.board
              .where((PlayerMarker? c) => c == PlayerMarker.nought)
              .length,
          1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('GameBoard NxN', () {
    Widget board(List<PlayerMarker?> cellsState, double side,
        {List<int>? winningLine}) {
      return localized(Scaffold(
        body: Center(
          child: SizedBox(
            width: side,
            height: side,
            child: GameBoard(
              board: cellsState,
              blockedCells: const <int>[],
              onCellSelected: (_) {},
              winningLine: winningLine,
              winningPlayer: winningLine == null ? null : PlayerMarker.cross,
            ),
          ),
        ),
      ));
    }

    testWidgets('10x10 num celular de 360px: peça legível (>= 22px)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final List<PlayerMarker?> cellsState =
          List<PlayerMarker?>.filled(100, null);
      cellsState[0] = PlayerMarker.cross;
      cellsState[55] = PlayerMarker.nought;
      // 360 menos o respiro de 12 de cada lado da tela de jogo.
      await tester.pumpWidget(board(cellsState, 336));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.byType(PieceGlyph), findsNWidgets(2));
      expect(tester.getSize(find.byType(PieceGlyph).first).width,
          greaterThanOrEqualTo(22));
      // As casas são de fato 10 por linha: a casa 9 fica na ponta direita e a
      // 10 abre a segunda linha embaixo da 0.
      final Rect c0 = tester.getRect(cells().at(0));
      final Rect c9 = tester.getRect(cells().at(9));
      final Rect c10 = tester.getRect(cells().at(10));
      expect(c9.top, c0.top);
      expect(c9.left, greaterThan(c0.left + 8 * c0.width));
      expect(c10.left, c0.left);
      expect(c10.top, greaterThan(c0.top));
    });

    testWidgets('3x3 continua igual: peça com 64% da casa',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final List<PlayerMarker?> cellsState =
          List<PlayerMarker?>.filled(9, null);
      cellsState[4] = PlayerMarker.cross;
      await tester.pumpWidget(board(cellsState, 324));
      await tester.pump(const Duration(seconds: 1));
      final double cell = tester.getSize(cells().at(4)).width;
      expect(cell, greaterThan(90));
      expect(tester.getSize(find.byType(PieceGlyph)).width,
          closeTo(cell * 0.64, 0.01));
      expect(cells(), findsNWidgets(9));
    });

    for (final (int side, List<int> line) in <(int, List<int>)>[
      (4, <int>[3, 6, 9, 12]),
      (10, <int>[71, 72, 73, 74, 75, 76]),
    ]) {
      testWidgets('linha da vitória desenha no ${side}x$side',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final List<PlayerMarker?> cellsState =
            List<PlayerMarker?>.filled(side * side, null);
        for (final int i in line) {
          cellsState[i] = PlayerMarker.cross;
        }
        await tester.pumpWidget(board(cellsState, 296, winningLine: line));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        final NeonWinLine winLine =
            tester.widget<NeonWinLine>(find.byType(NeonWinLine));
        expect(winLine.dimension, side);
        expect(winLine.winningLine, line);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}

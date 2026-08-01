import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictacverse/models/cpu_difficulty.dart';
import 'package:tictacverse/models/game_mode.dart';
import 'package:tictacverse/services/game_services_bridge.dart';
import 'package:tictacverse/services/play_games_ids.dart';
import 'package:tictacverse/services/progression_engine.dart';
import 'package:tictacverse/services/progression_service.dart';
import 'package:tictacverse/services/storage_service.dart';

/// A garantia que sustenta publicar com o Play Games ainda não configurado é
/// simples: enquanto não houver id mapeado, NADA da ponte pode tocar o canal
/// nativo. Estes testes falham se alguém remover um guard e o app passar a
/// chamar o SDK sem configuração (que é onde mora o crash no aparelho).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> nativeCalls = <MethodCall>[];

  setUp(() {
    nativeCalls.clear();
    GameServicesBridge.instance.disposeForTest();
    // Qualquer canal do plugin que for chamado fica registrado aqui.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('games_services'),
      (MethodCall call) async {
        nativeCalls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('games_services'), null);
    GameServicesBridge.instance.disposeForTest();
  });

  test('sem ids mapeados a integração se declara indisponível', () {
    expect(playGamesAchievementIds, isEmpty,
        reason: 'este teste descreve o estado "ainda não configurado"');
    expect(playGamesConfigured, isFalse);
    expect(GameServicesBridge.instance.isAvailable, isFalse);
    expect(GameServicesBridge.instance.isSignedIn, isFalse);
  });

  test('initialize não chama o nativo nem lança quando indisponível', () async {
    await GameServicesBridge.instance.initialize();
    expect(nativeCalls, isEmpty);
    expect(GameServicesBridge.instance.player.value, isNull);
  });

  test('espelhar, pontuar e abrir a UI viram no-op silencioso', () async {
    await GameServicesBridge.instance
        .mirrorUnlocked(<String>['first_win', 'wins_10']);
    await GameServicesBridge.instance.submitLevel(7);
    final bool opened = await GameServicesBridge.instance.showAchievementsUi();

    expect(opened, isFalse, reason: 'a UI nativa não existe sem configuração');
    expect(nativeCalls, isEmpty);
  });

  test('com ids mapeados mas sem login, ainda não fala com o nativo', () async {
    // Este é o cenário que prova o guard de login. No teste acima os ids estão
    // vazios, então o `continue` do laço já barraria tudo e o guard poderia ser
    // removido sem ninguém notar.
    final GameServicesBridge bridge = GameServicesBridge.instance;
    bridge.achievementIds = <String, String>{'first_win': 'CgkI_fake_ach'};
    bridge.leaderboardId = 'CgkI_fake_lb';

    expect(bridge.isAvailable, isTrue, reason: 'configurado, mas deslogado');
    expect(bridge.isSignedIn, isFalse);

    await bridge.mirrorUnlocked(<String>['first_win']);
    await bridge.submitLevel(7);
    final bool opened = await bridge.showAchievementsUi();

    expect(opened, isFalse);
    expect(nativeCalls, isEmpty,
        reason: 'sem jogador autenticado nada pode subir');
  });

  test('o fim de partida real não toca no nativo com a ponte desligada',
      () async {
    // Caminho de verdade (ProgressionService, não só o engine): é ele que
    // chama o espelho. Sem configuração tem de morrer no guard, não no canal.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageService.instance.load();

    final ProgressionResult result = ProgressionService.instance.registerMatch(
      const MatchOutcome(
        mode: GameModeType.ultimate2,
        vsCpu: true,
        difficulty: CpuDifficulty.hard,
        humanWon: true,
        isDraw: false,
      ),
    );

    expect(result.xpGained, greaterThan(0), reason: 'a partida foi computada');
    expect(nativeCalls, isEmpty, reason: 'mas nada subiu para o Play Games');
  });
}

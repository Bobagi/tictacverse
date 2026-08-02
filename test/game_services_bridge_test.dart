import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictacverse/models/achievement.dart';
import 'package:tictacverse/models/cpu_difficulty.dart';
import 'package:tictacverse/models/game_mode.dart';
import 'package:tictacverse/services/game_services_bridge.dart';
import 'package:tictacverse/services/play_games_ids.dart';
import 'package:tictacverse/services/progression_engine.dart';
import 'package:tictacverse/services/progression_service.dart';
import 'package:tictacverse/services/storage_service.dart';

/// O risco desta integração não é o caminho feliz: é o app tocar o SDK nativo
/// numa situação em que não devia (jogador não autenticado, conquista sem id
/// mapeado), porque é lá que mora crash em aparelho real, que não dá para
/// reproduzir aqui. Estes testes travam justamente os guards.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> nativeCalls = <MethodCall>[];

  setUp(() {
    nativeCalls.clear();
    GameServicesBridge.instance.disposeForTest();
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

  group('mapa de ids do Play Games', () {
    test('toda conquista do catálogo tem um id do Play Games', () {
      final Iterable<String> catalogIds =
          createAchievements().map((AchievementDefinition a) => a.id);
      for (final String id in catalogIds) {
        expect(playGamesAchievementIds, contains(id),
            reason: 'a conquista "$id" não seria espelhada. Rode '
                'tool/play_games_setup.py para regerar o mapa.');
      }
    });

    test('não há id do Play Games órfão nem repetido', () {
      final Set<String> catalogIds = createAchievements()
          .map((AchievementDefinition a) => a.id)
          .toSet();
      expect(playGamesAchievementIds.keys.toSet().difference(catalogIds),
          isEmpty,
          reason: 'id mapeado que não existe mais no catálogo');
      expect(playGamesAchievementIds.values.toSet(),
          hasLength(playGamesAchievementIds.length),
          reason: 'duas conquistas apontando para o mesmo id do Play Games');
    });

    test('a integração se declara configurada', () {
      expect(playGamesConfigured, isTrue);
    });
  });

  group('guards: nada vai para o nativo antes da hora', () {
    test('sem jogador autenticado, nada sobe', () async {
      final GameServicesBridge bridge = GameServicesBridge.instance;
      expect(bridge.isSignedIn, isFalse);

      await bridge.mirrorUnlocked(<String>['first_win', 'wins_10']);
      await bridge.submitLevel(7);
      final bool opened = await bridge.showAchievementsUi();

      expect(opened, isFalse);
      expect(nativeCalls, isEmpty,
          reason: 'espelhar/pontuar/abrir exigem login');
    });

    test('sem ids mapeados, a ponte se desliga inteira', () async {
      final GameServicesBridge bridge = GameServicesBridge.instance;
      bridge.achievementIds = <String, String>{};

      expect(bridge.isAvailable, isFalse);
      await bridge.mirrorUnlocked(<String>['first_win']);
      await bridge.submitLevel(3);

      expect(nativeCalls, isEmpty);
    });

    test('placar sem id não envia pontuação', () async {
      // Injeta o id vazio em vez de depender da configuração atual: assim o
      // teste continua exercitando o guard mesmo depois de o placar existir.
      final GameServicesBridge bridge = GameServicesBridge.instance;
      bridge.leaderboardId = '';
      await bridge.submitLevel(12);
      expect(nativeCalls, isEmpty);
    });

    test('o placar de nível está configurado', () {
      expect(playGamesLevelLeaderboardId, isNotEmpty,
          reason: 'submitLevel vira no-op sem o id do placar');
    });

    test('o fim de partida real não estoura sem login', () async {
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

      expect(result.xpGained, greaterThan(0),
          reason: 'a progressão local acontece de qualquer jeito');
      expect(nativeCalls, isEmpty,
          reason: 'e nada tenta subir enquanto não há jogador');
    });
  });
}

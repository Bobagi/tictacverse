import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/controllers/modes/chaos_rules_engine.dart';
import 'package:tictacverse/models/chaos_event.dart';
import 'package:tictacverse/models/game_result.dart';
import 'package:tictacverse/models/game_state.dart';
import 'package:tictacverse/models/player_marker.dart';

/// O banner do Caos mentia: o evento de uma jogada ficava preso na HUD até o
/// fim da partida porque `copyWith` não sabia limpar o campo (item 3 do
/// backlog de 15/07). Estes testes travam a correção.
void main() {
  GameState base() => GameState(
        board: List<PlayerMarker?>.filled(9, null),
        currentPlayer: PlayerMarker.cross,
        result: GameResult(resolution: GameResolution.ongoing),
        activeChaosEvent: ChaosEvent(type: ChaosEffectType.swapSymbols),
      );

  group('GameState.copyWith', () {
    test('omitir activeChaosEvent mantém o evento atual', () {
      final GameState next = base().copyWith(currentPlayer: PlayerMarker.nought);
      expect(next.activeChaosEvent, isNotNull);
      expect(next.activeChaosEvent!.type, ChaosEffectType.swapSymbols);
    });

    test('passar null explícito LIMPA o evento', () {
      final GameState next = base().copyWith(activeChaosEvent: null);
      expect(next.activeChaosEvent, isNull);
    });

    test('passar outro evento substitui', () {
      final GameState next = base().copyWith(
        activeChaosEvent: ChaosEvent(type: ChaosEffectType.blockCell, targetIndex: 4),
      );
      expect(next.activeChaosEvent!.type, ChaosEffectType.blockCell);
      expect(next.activeChaosEvent!.targetIndex, 4);
    });
  });

  group('ChaosRulesEngine', () {
    test('o evento dura uma jogada: a jogada seguinte sem evento limpa a HUD', () {
      // Seed fixa: o teste é determinístico independente de qual evento sai.
      final ChaosRulesEngine engine = ChaosRulesEngine(randomSeed: 7);
      GameState state = engine.start();
      // Jogadas em cantos opostos evitam vitória precoce.
      state = engine.handlePlayerMove(state, 0); // turnsUntilChaos 2 -> 1
      expect(state.activeChaosEvent, isNull);
      state = engine.handlePlayerMove(state, 8); // -> 0: evento dispara
      expect(state.activeChaosEvent, isNotNull,
          reason: 'o segundo lance dispara o primeiro evento do Caos');
      // Depois do evento, o contador volta a 3: as próximas 2 jogadas NÃO
      // têm evento e a HUD tem de ficar limpa.
      final int next = <int>[2, 6, 1, 3, 5, 7, 4]
          .firstWhere((int i) => state.isCellAvailable(i));
      state = engine.handlePlayerMove(state, next);
      expect(state.activeChaosEvent, isNull,
          reason: 'evento antigo continuou na HUD (copyWith não limpou)');
    });
  });
}

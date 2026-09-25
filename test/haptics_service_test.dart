import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictacverse/services/haptics_service.dart';
import 'package:tictacverse/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ligado: cada pedido chega ao motor', () async {
    final List<HapticCue> received = <HapticCue>[];
    final HapticsService haptics = HapticsService.forTest(
      sink: (HapticCue cue) async => received.add(cue),
    );
    haptics.play(HapticCue.place);
    haptics.play(HapticCue.win);
    await Future<void>.delayed(Duration.zero);
    expect(received, <HapticCue>[HapticCue.place, HapticCue.win]);
  });

  test('desligado pelo jogador: nada vibra', () async {
    final List<HapticCue> received = <HapticCue>[];
    final HapticsService haptics = HapticsService.forTest(
      sink: (HapticCue cue) async => received.add(cue),
      enabled: false,
    );
    haptics.play(HapticCue.win);
    await Future<void>.delayed(Duration.zero);
    expect(received, isEmpty);
  });

  test('motor que lança não derruba o jogo', () async {
    final HapticsService haptics = HapticsService.forTest(
      sink: (HapticCue cue) async => throw StateError('sem motor'),
    );
    expect(() => haptics.play(HapticCue.tap), returnsNormally);
    await Future<void>.delayed(Duration.zero);
  });

  test('a preferência persiste e volta no próximo boot', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageService.instance.load();
    expect(StorageService.instance.hapticsEnabled, isTrue,
        reason: 'ligado por padrão: faz parte do juice');

    final HapticsService haptics = HapticsService.forTest(
      sink: (HapticCue cue) async {},
    );
    haptics.setEnabled(false);
    await Future<void>.delayed(Duration.zero);
    expect(StorageService.instance.hapticsEnabled, isFalse);
    expect(haptics.isEnabled, isFalse);
  });
}

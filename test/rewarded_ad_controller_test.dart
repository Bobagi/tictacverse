import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/controllers/rewarded_ad_controller.dart';

void main() {
  // Fora do Android o AdUnitIdProvider devolve id vazio, então o controller
  // nunca chega ao plugin: dá para exercitar os guards de verdade, sem mock.
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('RewardedAdController: nunca prende nem premia sem anúncio', () {
    test('sem anúncio carregado, showForReward resolve false (não trava)',
        () async {
      final RewardedAdController controller = RewardedAdController();

      expect(controller.isReady, isFalse);
      await expectLater(controller.showForReward(), completion(isFalse));

      controller.dispose();
    });

    test('depois do dispose continua resolvendo false, sem recarregar',
        () async {
      final RewardedAdController controller = RewardedAdController();
      controller.dispose();

      expect(controller.isReady, isFalse);
      await expectLater(controller.showForReward(), completion(isFalse));
      // Um segundo dispose não pode estourar (a tela pode chamar de novo).
      controller.dispose();
    });
  });
}

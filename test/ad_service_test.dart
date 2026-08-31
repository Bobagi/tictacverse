import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/services/ad_service.dart';

/// Cadência dos anúncios de fim de partida. O que estes testes protegem é
/// dinheiro nos dois sentidos: anúncio de menos não rende, anúncio demais
/// espanta o jogador e chama atenção da política do AdMob.
void main() {
  group('intersticial', () {
    test('sai a cada 3 partidas, não antes', () {
      final AdService service = AdService.forTest();
      expect(
        <bool>[for (int i = 0; i < 9; i++) service.shouldShowInterstitialOnMatchEnd()],
        <bool>[false, false, true, false, false, true, false, false, true],
      );
    });
  });

  group('convite de anúncio premiado', () {
    test('sai a cada 4 partidas, não em todo fim de partida', () {
      final AdService service = AdService.forTest();
      expect(
        <bool>[for (int i = 0; i < 12; i++) service.shouldOfferRewardedOnMatchEnd()],
        <bool>[
          false, false, false, true, // 4
          false, false, false, true, // 8
          false, false, false, true, // 12
        ],
      );
    });

    test('conta separado do intersticial', () {
      final AdService service = AdService.forTest();
      // Três partidas só contando intersticial não podem adiantar o premiado.
      for (int i = 0; i < 3; i++) {
        service.shouldShowInterstitialOnMatchEnd();
      }
      expect(service.shouldOfferRewardedOnMatchEnd(), isFalse);
    });
  });

  group('instância', () {
    test('é única, para o contador sobreviver à troca de tela', () {
      expect(identical(AdService.instance, AdService.instance), isTrue);
    });

    test('forTest devolve instâncias independentes', () {
      final AdService a = AdService.forTest();
      final AdService b = AdService.forTest();
      for (int i = 0; i < 3; i++) {
        a.shouldOfferRewardedOnMatchEnd();
      }
      expect(a.shouldOfferRewardedOnMatchEnd(), isTrue);
      expect(b.shouldOfferRewardedOnMatchEnd(), isFalse);
    });
  });

  test('resetTracking zera as duas contagens', () {
    final AdService service = AdService.forTest();
    service.shouldShowInterstitialOnMatchEnd();
    service.shouldShowInterstitialOnMatchEnd();
    service.shouldOfferRewardedOnMatchEnd();
    service.shouldOfferRewardedOnMatchEnd();
    service.shouldOfferRewardedOnMatchEnd();
    service.resetTracking();
    expect(service.shouldShowInterstitialOnMatchEnd(), isFalse);
    expect(service.shouldOfferRewardedOnMatchEnd(), isFalse);
  });
}

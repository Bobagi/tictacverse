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
      final List<bool> got = <bool>[];
      for (int i = 0; i < 12; i++) {
        final bool due = service.shouldOfferRewardedOnMatchEnd();
        got.add(due);
        if (due) {
          service.markRewardedOffered();
        }
      }
      expect(got, <bool>[
        false, false, false, true, // 4
        false, false, false, true, // 8
        false, false, false, true, // 12
      ]);
    });

    test('vez que não virou convite fica para a próxima partida', () {
      final AdService service = AdService.forTest();
      for (int i = 0; i < 3; i++) {
        service.shouldOfferRewardedOnMatchEnd();
      }
      expect(service.shouldOfferRewardedOnMatchEnd(), isTrue); // 4ª, barrada
      expect(service.shouldOfferRewardedOnMatchEnd(), isTrue); // 5ª, ainda vale
      service.markRewardedOffered();
      expect(service.shouldOfferRewardedOnMatchEnd(), isFalse);
    });

    test('a contagem sobrevive a fechar e abrir o app', () {
      int stored = 0;
      AdService open() => AdService.forTest(
            loadCounter: () => stored,
            saveCounter: (int v) => stored = v,
          );
      final AdService first = open();
      first.shouldOfferRewardedOnMatchEnd();
      first.shouldOfferRewardedOnMatchEnd();
      // Fechou o app depois de 2 partidas; abriu de novo.
      final AdService second = open();
      expect(second.shouldOfferRewardedOnMatchEnd(), isFalse); // 3ª
      expect(second.shouldOfferRewardedOnMatchEnd(), isTrue); // 4ª
      second.markRewardedOffered();
      expect(stored, 0);
    });

    test('contagem pendente não cresce sem limite', () {
      int stored = 0;
      final AdService service = AdService.forTest(
        loadCounter: () => stored,
        saveCounter: (int v) => stored = v,
      );
      for (int i = 0; i < 50; i++) {
        service.shouldOfferRewardedOnMatchEnd();
      }
      expect(stored, AdService.rewardedOfferInterval);
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

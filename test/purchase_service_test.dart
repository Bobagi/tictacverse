import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictacverse/models/progress_state.dart';
import 'package:tictacverse/models/store_product.dart';
import 'package:tictacverse/services/ads_configuration.dart';
import 'package:tictacverse/services/purchase_service.dart';
import 'package:tictacverse/services/storage_service.dart';
import 'package:tictacverse/services/verse_api.dart';

const String install = '1b4e28ba-2fa1-4d3b-a3f5-ef19b5a7633b';

/// Play falsa: registra a ordem das chamadas e o saldo no momento do consumo.
class FakePurchaseBackend implements PurchaseBackend {
  final StreamController<List<PurchaseDetails>> controller =
      StreamController<List<PurchaseDetails>>.broadcast();
  final List<String> calls = <String>[];
  int coinsWhenConsumed = -1;
  bool available = true;
  bool consumeOk = true;
  int buys = 0;
  String? lastAccountId;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> ids) async =>
      ids.map(product).toList();

  @override
  Future<bool> buy(ProductDetails product,
      {required bool consumable, required String accountId}) async {
    buys++;
    lastAccountId = accountId;
    calls.add('buy:${product.id}:${consumable ? 'consumable' : 'once'}');
    return true;
  }

  @override
  Future<void> restore() async => calls.add('restore');

  @override
  Future<bool> consume(PurchaseDetails purchase) async {
    coinsWhenConsumed = StorageService.instance.progress.coins;
    calls.add('consume:${purchase.productID}');
    return consumeOk;
  }

  @override
  Future<void> complete(PurchaseDetails purchase) async =>
      calls.add('complete:${purchase.productID}');
}

/// Servidor falso: por padrão confirma o que o catálogo diz; [verdicts]
/// sobrescreve por token. Reentrega a mesma resposta para o mesmo token,
/// como o servidor de verdade faz para a mesma instalação.
class FakeApi implements VerseApi {
  final Map<String, VerifyResult> verdicts = <String, VerifyResult>{};
  final List<Revocation> revoked = <Revocation>[];
  bool online = true;
  int verifyCalls = 0;
  int revocationCalls = 0;

  @override
  Future<VerifyResult> verifyPurchase({
    required String installId,
    required String productId,
    required String purchaseToken,
  }) async {
    verifyCalls++;
    if (!online) {
      return VerifyResult.retryLater;
    }
    final VerifyResult? forced = verdicts[purchaseToken];
    if (forced != null) {
      return forced;
    }
    final StoreProduct p = storeProductById(productId)!;
    return VerifyResult(VerifyStatus.granted,
        coins: p.coins,
        removeAds: p.removeAds,
        redemptionId: 'r-$purchaseToken');
  }

  @override
  Future<List<Revocation>?> revocations(String installId) async {
    revocationCalls++;
    return online ? List<Revocation>.of(revoked) : null;
  }

  @override
  Future<bool> ping({
    required String installId,
    required String appVersion,
    required String locale,
  }) async =>
      online;
}

ProductDetails product(String id) => ProductDetails(
      id: id,
      title: id,
      description: id,
      price: r'R$ 4,99',
      rawPrice: 4.99,
      currencyCode: 'BRL',
    );

PurchaseDetails purchase(
  String productId,
  PurchaseStatus status, {
  String token = 'tok-1',
  bool pendingComplete = true,
}) =>
    PurchaseDetails(
      purchaseID: 'GPA.$token',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '{}',
        serverVerificationData: token,
        source: 'google_play',
      ),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = pendingComplete;

void main() {
  late FakePurchaseBackend play;
  late FakeApi api;
  late PurchaseService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageService.instance.load();
    StorageService.instance.progress = ProgressState();
    play = FakePurchaseBackend();
    api = FakeApi();
    service =
        PurchaseService(backend: play, api: api, installId: () => install);
    await service.initialize();
  });

  tearDown(() => service.dispose());

  test('abre a loja com os preços da Play, confere estornos e pede pendentes',
      () async {
    expect(service.availability.value, StoreAvailability.ready);
    expect(service.productFor('coins_300')?.price, r'R$ 4,99');
    expect(play.calls, contains('restore'));
    expect(api.revocationCalls, 1);
  });

  test('Play indisponível deixa a loja fechada, sem quebrar', () async {
    final FakePurchaseBackend off = FakePurchaseBackend()..available = false;
    final PurchaseService s =
        PurchaseService(backend: off, api: api, installId: () => install);
    await s.initialize();
    expect(s.availability.value, StoreAvailability.unavailable);
    expect(await s.buy('coins_300'), isFalse);
    expect(off.buys, 0);
  });

  test('a compra leva o id da instalação para a Play (amarra ao servidor)',
      () async {
    await service.buy('coins_300');
    expect(play.lastAccountId, install);
  });

  test('pacote: servidor confirma, app credita e grava ANTES de consumir',
      () async {
    expect(await service.buy('coins_1000'), isTrue);
    expect(play.calls.last, 'buy:coins_1000:consumable');
    await service.handlePurchases(
        <PurchaseDetails>[purchase('coins_1000', PurchaseStatus.purchased)]);
    expect(api.verifyCalls, 1);
    expect(StorageService.instance.progress.coins, 1000);
    expect(play.coinsWhenConsumed, 1000,
        reason: 'consumir antes de creditar perde a compra se o app morrer');
    expect(play.calls.last, 'consume:coins_1000');
    expect(service.buying.value, isNull);
    expect(service.lastOutcome.value?.kind, PurchaseOutcomeKind.coins);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('progress.v1'), contains('"coins":1000'),
        reason: 'o crédito precisa estar no disco');
  });

  test('servidor fora do ar: não credita, não consome, e entrega na volta',
      () async {
    api.online = false;
    await service.buy('coins_300');
    await service.handlePurchases(
        <PurchaseDetails>[purchase('coins_300', PurchaseStatus.purchased)]);
    expect(StorageService.instance.progress.coins, 0);
    expect(play.calls, isNot(contains('consume:coins_300')),
        reason: 'consumir sem confirmação = Play acha que entregamos');
    expect(service.lastOutcome.value?.kind, PurchaseOutcomeKind.verifying);
    expect(service.hasPendingVerification, isTrue);
    expect(service.buying.value, isNull, reason: 'não pode travar a loja');

    api.online = true;
    await service.retryPendingVerifications();
    expect(StorageService.instance.progress.coins, 300);
    expect(play.calls.last, 'consume:coins_300');
    expect(service.hasPendingVerification, isFalse);
  });

  test('servidor diz inválido (token falso, outra instalação): nada entra',
      () async {
    api.verdicts['forjado'] = const VerifyResult(VerifyStatus.invalid);
    await service.handlePurchases(<PurchaseDetails>[
      purchase('coins_3000', PurchaseStatus.purchased, token: 'forjado')
    ]);
    expect(StorageService.instance.progress.coins, 0);
    expect(play.calls.where((String c) => c.startsWith('consume')), isEmpty);
    expect(play.calls.where((String c) => c.startsWith('complete')), isEmpty);
  });

  test('compra estornada antes de entregar: servidor diz revogada, nada entra',
      () async {
    api.verdicts['estornada'] = const VerifyResult(VerifyStatus.revoked);
    await service.handlePurchases(<PurchaseDetails>[
      purchase('remove_ads', PurchaseStatus.restored, token: 'estornada')
    ]);
    expect(StorageService.instance.progress.adsRemoved, isFalse);
  });

  test('o servidor reentregando a mesma compra não paga em dobro', () async {
    play.consumeOk = false;
    await service.handlePurchases(
        <PurchaseDetails>[purchase('coins_300', PurchaseStatus.purchased)]);
    await service.handlePurchases(
        <PurchaseDetails>[purchase('coins_300', PurchaseStatus.restored)]);
    expect(api.verifyCalls, 2);
    expect(StorageService.instance.progress.coins, 300);
    expect(play.calls.where((String c) => c == 'consume:coins_300').length, 2,
        reason: 'segue tentando consumir até a Play aceitar');
  });

  test('pagamento pendente não vai ao servidor nem credita', () async {
    await service.buy('coins_300');
    await service.handlePurchases(<PurchaseDetails>[
      purchase('coins_300', PurchaseStatus.pending, pendingComplete: false)
    ]);
    expect(api.verifyCalls, 0);
    expect(StorageService.instance.progress.coins, 0);
    expect(service.lastOutcome.value?.kind, PurchaseOutcomeKind.pending);
    expect(service.buying.value, isNull);

    await service.handlePurchases(
        <PurchaseDetails>[purchase('coins_300', PurchaseStatus.purchased)]);
    expect(StorageService.instance.progress.coins, 300);
  });

  test('cancelada ou com erro: nada creditado, loja destrava', () async {
    await service.buy('coins_300');
    await service.handlePurchases(
        <PurchaseDetails>[purchase('coins_300', PurchaseStatus.canceled)]);
    expect(StorageService.instance.progress.coins, 0);
    expect(service.buying.value, isNull);
    expect(service.lastOutcome.value?.kind, PurchaseOutcomeKind.canceled);

    await service.buy('coins_300');
    await service.handlePurchases(
        <PurchaseDetails>[purchase('coins_300', PurchaseStatus.error)]);
    expect(StorageService.instance.progress.coins, 0);
    expect(service.lastOutcome.value?.kind, PurchaseOutcomeKind.failed);
  });

  test('toque duplo abre uma compra só', () async {
    await service.buy('coins_300');
    expect(await service.buy('coins_3000'), isFalse);
    expect(play.buys, 1);
  });

  test('"sem anúncios": confirma (não consome) e desliga os passivos',
      () async {
    expect(AdsConfiguration.passiveAdsEnabled, AdsConfiguration.adsEnabled);
    await service.buy('remove_ads');
    expect(play.calls.last, 'buy:remove_ads:once');
    await service.handlePurchases(
        <PurchaseDetails>[purchase('remove_ads', PurchaseStatus.purchased)]);
    expect(StorageService.instance.progress.adsRemoved, isTrue);
    expect(play.calls.last, 'complete:remove_ads');
    expect(play.calls, isNot(contains('consume:remove_ads')));
    expect(AdsConfiguration.passiveAdsEnabled, isFalse);
    expect(service.lastOutcome.value?.kind, PurchaseOutcomeKind.adsRemoved);
    expect(await service.buy('remove_ads'), isFalse,
        reason: 'não deixa pagar duas vezes pelo mesmo direito');
    expect(await service.buy('starter_pack'), isFalse,
        reason: 'o pacote de boas-vindas também traz "sem anúncios"');
  });

  test('pacote de boas-vindas entrega moedas e "sem anúncios" uma vez só',
      () async {
    await service.handlePurchases(<PurchaseDetails>[
      purchase('starter_pack', PurchaseStatus.purchased, token: 'sp')
    ]);
    expect(StorageService.instance.progress.coins, 1000);
    expect(StorageService.instance.progress.adsRemoved, isTrue);
    expect(play.calls.last, 'complete:starter_pack');
    // Restore a cada abertura: o mesmo token não paga de novo.
    await service.handlePurchases(<PurchaseDetails>[
      purchase('starter_pack', PurchaseStatus.restored,
          token: 'sp', pendingComplete: false)
    ]);
    expect(StorageService.instance.progress.coins, 1000);
  });

  test('reinstalou: o servidor devolve só o direito, sem moedas', () async {
    api.verdicts['velho'] = const VerifyResult(VerifyStatus.granted,
        coins: 0, removeAds: true, redemptionId: '7');
    await service.handlePurchases(<PurchaseDetails>[
      purchase('starter_pack', PurchaseStatus.restored,
          token: 'velho', pendingComplete: false)
    ]);
    expect(StorageService.instance.progress.adsRemoved, isTrue);
    expect(StorageService.instance.progress.coins, 0);
  });

  test('estorno de moedas: tira o saldo e devolve visuais se já gastou',
      () async {
    StorageService.instance.progress = ProgressState(
        coins: 200,
        ownedSkins: <String>{'neon', 'galaxy', 'fireIce'},
        equippedSkin: 'galaxy');
    api.revoked.add(const Revocation(
        redemptionId: '12',
        productId: 'coins_1000',
        coins: 1000,
        removeAds: false));
    await service.syncRevocations();
    final ProgressState s = StorageService.instance.progress;
    // 200 - 1000 = -800; a galáxia (800) volta para a loja e cobre a dívida.
    expect(s.ownedSkins, isNot(contains('galaxy')));
    expect(s.ownedSkins, contains('fireIce'));
    expect(s.equippedSkin, 'neon');
    expect(s.coins, 0);
    // Rodar de novo (toda abertura do app) não desconta outra vez.
    await service.syncRevocations();
    expect(StorageService.instance.progress.coins, 0);
  });

  test('estorno do "sem anúncios": anúncios voltam e o restore confere',
      () async {
    await service.handlePurchases(
        <PurchaseDetails>[purchase('remove_ads', PurchaseStatus.purchased)]);
    expect(StorageService.instance.progress.adsRemoved, isTrue);
    play.calls.clear();
    api.revoked.add(const Revocation(
        redemptionId: '3', productId: 'remove_ads', coins: 0, removeAds: true));
    await service.syncRevocations();
    expect(StorageService.instance.progress.adsRemoved, isFalse);
    expect(play.calls, contains('restore'),
        reason: 'se houver outra compra válida, ela devolve o direito');
  });

  test('servidor sem rede na sincronização de estornos não mexe em nada',
      () async {
    StorageService.instance.progress = ProgressState(coins: 50);
    api.online = false;
    await service.syncRevocations();
    expect(StorageService.instance.progress.coins, 50);
  });

  test('produto desconhecido é só finalizado, sem crédito', () async {
    await service.handlePurchases(
        <PurchaseDetails>[purchase('hack_9999', PurchaseStatus.purchased)]);
    expect(StorageService.instance.progress.coins, 0);
    expect(api.verifyCalls, 0);
    expect(play.calls.last, 'complete:hack_9999');
  });

  test('loja de mentira nunca liga em build de release nativo', () {
    expect(
        PurchaseService.useDemoStore(
            requested: true, isWeb: false, isRelease: true),
        isFalse);
    expect(
        PurchaseService.useDemoStore(
            requested: false, isWeb: true, isRelease: false),
        isFalse);
    expect(
        PurchaseService.useDemoStore(
            requested: true, isWeb: true, isRelease: true),
        isTrue);
    expect(
        PurchaseService.useDemoStore(
            requested: true, isWeb: false, isRelease: false),
        isTrue);
  });

  test('resposta estranha do servidor nunca vira entrega', () {
    expect(HttpVerseApi.parseVerify(<String, dynamic>{'status': 'ok'}).status,
        VerifyStatus.retry);
    final VerifyResult weird = HttpVerseApi.parseVerify(<String, dynamic>{
      'status': 'granted',
      'coins': 99999999,
      'removeAds': 'yes',
    });
    expect(weird.coins, 0, reason: 'valor fora do teto não credita');
    expect(weird.removeAds, isFalse, reason: 'só true literal liga o direito');
  });
}

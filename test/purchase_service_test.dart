import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictacverse/models/progress_state.dart';
import 'package:tictacverse/services/ads_configuration.dart';
import 'package:tictacverse/services/purchase_service.dart';
import 'package:tictacverse/services/storage_service.dart';

/// Play falsa: registra a ordem das chamadas e o saldo no momento do consumo.
class FakePurchaseBackend implements PurchaseBackend {
  final StreamController<List<PurchaseDetails>> controller =
      StreamController<List<PurchaseDetails>>.broadcast();
  final List<String> calls = <String>[];
  int coinsWhenConsumed = -1;
  bool available = true;
  bool consumeOk = true;
  int buys = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> ids) async =>
      ids.map(product).toList();

  @override
  Future<bool> buy(ProductDetails product, {required bool consumable}) async {
    buys++;
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
  late PurchaseService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageService.instance.load();
    StorageService.instance.progress = ProgressState();
    play = FakePurchaseBackend();
    service = PurchaseService(backend: play);
    await service.initialize();
  });

  tearDown(() => service.dispose());

  test('abre a loja com os preços da Play e já pede as compras pendentes',
      () async {
    expect(service.availability.value, StoreAvailability.ready);
    expect(service.productFor('coins_300')?.price, r'R$ 4,99');
    expect(play.calls, contains('restore'));
  });

  test('Play indisponível deixa a loja fechada, sem quebrar', () async {
    final FakePurchaseBackend off = FakePurchaseBackend()..available = false;
    final PurchaseService s = PurchaseService(backend: off);
    await s.initialize();
    expect(s.availability.value, StoreAvailability.unavailable);
    expect(await s.buy('coins_300'), isFalse);
    expect(off.buys, 0);
  });

  test('pacote: credita e grava ANTES de consumir na Play', () async {
    expect(await service.buy('coins_1000'), isTrue);
    expect(play.calls.last, 'buy:coins_1000:consumable');
    await service.handlePurchases(
        <PurchaseDetails>[purchase('coins_1000', PurchaseStatus.purchased)]);
    expect(StorageService.instance.progress.coins, 1000);
    expect(play.coinsWhenConsumed, 1000,
        reason: 'consumir antes de creditar perde a compra se o app morrer');
    expect(play.calls.last, 'consume:coins_1000');
    expect(service.buying.value, isNull);
    expect(service.lastOutcome.value?.kind, PurchaseOutcomeKind.coins);
    expect(service.lastOutcome.value?.coins, 1000);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('progress.v1'), contains('"coins":1000'),
        reason: 'o crédito precisa estar no disco');
  });

  test('a Play reentregando a mesma compra não paga em dobro', () async {
    play.consumeOk = false;
    await service.handlePurchases(
        <PurchaseDetails>[purchase('coins_300', PurchaseStatus.purchased)]);
    await service.handlePurchases(
        <PurchaseDetails>[purchase('coins_300', PurchaseStatus.restored)]);
    expect(StorageService.instance.progress.coins, 300);
    expect(play.calls.where((String c) => c == 'consume:coins_300').length, 2,
        reason: 'segue tentando consumir até a Play aceitar');
  });

  test('pagamento pendente não credita; credita quando a Play confirma',
      () async {
    await service.buy('coins_300');
    await service.handlePurchases(<PurchaseDetails>[
      purchase('coins_300', PurchaseStatus.pending, pendingComplete: false)
    ]);
    expect(StorageService.instance.progress.coins, 0);
    expect(service.lastOutcome.value?.kind, PurchaseOutcomeKind.pending);
    expect(play.calls, isNot(contains('consume:coins_300')));
    expect(service.buying.value, isNull, reason: 'não pode travar a loja');

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
  });

  test('reinstalou: o restore devolve o "sem anúncios" em silêncio', () async {
    await service.handlePurchases(<PurchaseDetails>[
      purchase('remove_ads', PurchaseStatus.restored, pendingComplete: false)
    ]);
    expect(StorageService.instance.progress.adsRemoved, isTrue);
    expect(play.calls, isNot(contains('complete:remove_ads')),
        reason: 'já confirmada antes');
  });

  test('produto desconhecido é só finalizado, sem crédito', () async {
    await service.handlePurchases(
        <PurchaseDetails>[purchase('hack_9999', PurchaseStatus.purchased)]);
    expect(StorageService.instance.progress.coins, 0);
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
}

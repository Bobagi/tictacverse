import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictacverse/models/board_theme.dart';
import 'package:tictacverse/models/piece_skin.dart';
import 'package:tictacverse/models/progress_state.dart';
import 'package:tictacverse/services/ads_configuration.dart';
import 'package:tictacverse/services/economy_service.dart';
import 'package:tictacverse/services/purchase_service.dart';
import 'package:tictacverse/services/purchase_verifier.dart';
import 'package:tictacverse/services/storage_service.dart';

/// Par de chaves de TESTE (gerado com openssl só para isto): a assinatura
/// abaixo é a de [signedJson] com a chave privada correspondente.
const String testPublicKey =
    'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxxmbugiMHy6rgU4yV51RXc2x9k0dQGpXEyoNS+MPunqVvlnlm4dpM0sg6VQ8v3AZoSCfGNEBbRd8+FUi7lZpKGa0Jd9E29rPamDdea7Bzg8wzYON1cuEYmZcLFRsxouWEJnijlHRQ/1XetKXfLbqcs0ATQ759JNaH6333UgsRsu7yALDCoFFJf+V2GzdY/Dlp6Z5VtsqdLnFUQrwi8Sc2LyN0d5xqpyt9qc8634Ndieck1YGhZGtNOnMZ0o36SVTiVWgfMRFSYMtIzrfeck35DNsUeeUNzGfuwb/PvwLU1AWpSet9D3ytNVQ0EQg4CqtwohH8mvL6BFM8D+FFZHL6wIDAQAB';
const String signedJson =
    r'{"orderId":"GPA.1","packageName":"com.bobagi.tictacverse","productId":"collection","purchaseState":0,"purchaseToken":"tok"}';
const String goodSignature =
    'EieyOrAwprlicIoEj87wVd0tVghlcBuIb66H9P8IUhe1YLVGOPHdCwWrHEr75PzmFHuznDbkm92xMUEF31M53zmQ1aCgJafi4+eefPgRm9fkH8NcE0SPcP4Gv2XqBiMO36OVCnb/dGAiafmYAflPX0xEXD0/ZkJKGgIfIhAgWdwlctZXBYFWP9qzF0w8m4xlN5g22bIbRhOp4Q0jmred1bYpSva5IJksiXiewtFjG0XjKQz1nZOAeNaN/a2qAqUPc0j1ms7QypxD2keNtTjw46dk4f28+p28QZTKXh8TMmLSNaAp4iDGz4vBs24dFy2aXWr9HQsIcv3IJZA4cUUT9Q==';

/// Play falsa: [owned] é o que a Play diz que o jogador possui agora.
class FakePlay implements PurchaseBackend {
  final StreamController<List<PurchaseDetails>> controller =
      StreamController<List<PurchaseDetails>>.broadcast();
  final List<String> calls = <String>[];
  List<PurchaseDetails>? owned = <PurchaseDetails>[];
  bool available = true;
  int buys = 0;
  final Map<String, String> signatures = <String, String>{};

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> ids) async =>
      ids.map(product).toList();

  @override
  Future<bool> buy(ProductDetails product) async {
    buys++;
    calls.add('buy:${product.id}');
    return true;
  }

  @override
  Future<List<PurchaseDetails>?> queryOwned() async {
    calls.add('query');
    return owned == null ? null : List<PurchaseDetails>.of(owned!);
  }

  @override
  Future<void> complete(PurchaseDetails purchase) async =>
      calls.add('complete:${purchase.productID}');

  @override
  String? signatureOf(PurchaseDetails purchase) =>
      signatures[purchase.productID];
}

ProductDetails product(String id) => ProductDetails(
    id: id,
    title: id,
    description: id,
    price: r'R$ 4,99',
    rawPrice: 4.99,
    currencyCode: 'BRL');

PurchaseDetails purchase(String id, PurchaseStatus status,
        {bool pendingComplete = true, String json = '{}'}) =>
    PurchaseDetails(
      purchaseID: 'GPA.$id',
      productID: id,
      verificationData: PurchaseVerificationData(
          localVerificationData: json,
          serverVerificationData: 'tok-$id',
          source: 'google_play'),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = pendingComplete;

ProgressState get state => StorageService.instance.progress;

void main() {
  late FakePlay play;
  late PurchaseService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageService.instance.load();
    StorageService.instance.progress = ProgressState();
    play = FakePlay();
    service = PurchaseService(backend: play, verifier: PurchaseVerifier(''));
    await service.initialize();
  });

  tearDown(() => service.dispose());

  test('abre a loja com os preços da Play e pergunta o que o jogador possui',
      () async {
    expect(service.availability.value, StoreAvailability.ready);
    expect(service.productFor('collection')?.price, r'R$ 4,99');
    expect(play.calls, contains('query'));
  });

  test('reinstalou: a Play devolve o que ele possui e o direito volta',
      () async {
    play.owned = <PurchaseDetails>[
      purchase('remove_ads', PurchaseStatus.purchased, pendingComplete: false)
    ];
    await service.refreshOwnership();
    expect(state.adsRemoved, isTrue);
    expect(AdsConfiguration.passiveAdsEnabled, isFalse);
  });

  test('REEMBOLSO: sumiu da lista da Play, o direito some na abertura',
      () async {
    play.owned = <PurchaseDetails>[
      purchase('starter_pack', PurchaseStatus.purchased, pendingComplete: false)
    ];
    await service.refreshOwnership();
    EconomyService.instance.equip(pieceSkinById('aurora'));
    expect(state.adsRemoved, isTrue);
    expect(state.equippedSkin, 'aurora');

    play.owned = <PurchaseDetails>[]; // a pessoa pediu reembolso
    await service.refreshOwnership();
    expect(state.adsRemoved, isFalse);
    expect(state.hasSkin('aurora'), isFalse);
    expect(state.equippedSkin, ProgressState.defaultSkinId,
        reason: 'visual em uso que deixou de ser dele volta para o inicial');
  });

  test('sem resposta da Play (sem rede), vale o último estado confirmado',
      () async {
    play.owned = <PurchaseDetails>[
      purchase('collection', PurchaseStatus.purchased, pendingComplete: false)
    ];
    await service.refreshOwnership();
    play.owned = null;
    await service.refreshOwnership();
    expect(state.playOwned, contains('collection'));
    final ProgressState back = ProgressState.fromJson(state.toJson());
    expect(back.hasTheme('royal'), isTrue, reason: 'sobrevive ao save');
  });

  test('coleção completa libera todos os visuais e temas, e tira anúncios',
      () async {
    play.owned = <PurchaseDetails>[
      purchase('collection', PurchaseStatus.purchased, pendingComplete: false)
    ];
    await service.refreshOwnership();
    for (final PieceSkin s in pieceSkinCatalog) {
      expect(state.hasSkin(s.id), isTrue, reason: s.id);
    }
    for (final BoardTheme t in boardThemeCatalog) {
      expect(state.hasTheme(t.id), isTrue, reason: t.id);
    }
    expect(state.adsRemoved, isTrue);
    expect(state.coins, 0, reason: 'nenhuma compra dá moeda');
  });

  test('compra nova: confirma na Play e libera; outcome avisa a tela',
      () async {
    expect(await service.buy('starter_pack'), isTrue);
    play.owned = <PurchaseDetails>[
      purchase('starter_pack', PurchaseStatus.purchased)
    ];
    await service.handlePurchases(
        <PurchaseDetails>[purchase('starter_pack', PurchaseStatus.purchased)]);
    expect(play.calls, contains('complete:starter_pack'));
    expect(state.hasSkin('aurora'), isTrue);
    expect(state.adsRemoved, isTrue);
    expect(service.buying.value, isNull);
    expect(service.lastOutcome.value?.kind, PurchaseOutcomeKind.unlocked);
    expect(await service.buy('starter_pack'), isFalse,
        reason: 'não deixa pagar de novo pelo que já possui');
  });

  test('compra nova com a lista da Play atrasada ainda libera', () async {
    await service.buy('remove_ads');
    play.owned = <PurchaseDetails>[]; // cache da Play ainda sem a compra
    await service.handlePurchases(
        <PurchaseDetails>[purchase('remove_ads', PurchaseStatus.purchased)]);
    expect(state.adsRemoved, isTrue);
  });

  test('pendente não libera; cancelada e erro destravam sem liberar', () async {
    await service.buy('collection');
    await service.handlePurchases(<PurchaseDetails>[
      purchase('collection', PurchaseStatus.pending, pendingComplete: false)
    ]);
    expect(state.playOwned, isEmpty);
    expect(service.lastOutcome.value?.kind, PurchaseOutcomeKind.pending);
    expect(service.buying.value, isNull);

    await service.buy('collection');
    await service.handlePurchases(
        <PurchaseDetails>[purchase('collection', PurchaseStatus.canceled)]);
    expect(state.playOwned, isEmpty);
    expect(service.lastOutcome.value?.kind, PurchaseOutcomeKind.canceled);
  });

  test('toque duplo abre uma compra só', () async {
    await service.buy('remove_ads');
    expect(await service.buy('collection'), isFalse);
    expect(play.buys, 1);
  });

  test('produto que o app não vende não libera nada', () async {
    play.owned = <PurchaseDetails>[
      purchase('coins_3000', PurchaseStatus.purchased, pendingComplete: false)
    ];
    await service.refreshOwnership();
    expect(state.coins, 0);
    expect(state.adsRemoved, isFalse);
  });

  group('assinatura da Play', () {
    late PurchaseVerifier verifier;
    setUp(() => verifier = PurchaseVerifier(testPublicKey));

    test('chave de teste é lida', () => expect(verifier.enabled, isTrue));

    test('assinatura verdadeira passa', () {
      expect(verifier.verify(signedJson, goodSignature), isTrue);
    });

    test('dado adulterado ou assinatura ausente/falsa não passa', () {
      expect(
          verifier.verify(
              signedJson.replaceAll('collection', 'remove_ads'), goodSignature),
          isFalse);
      expect(verifier.verify(signedJson, null), isFalse);
      expect(verifier.verify(signedJson, 'AAAA'), isFalse);
    });

    test('compra forjada (sem assinatura válida) não libera nada', () async {
      final PurchaseService strict =
          PurchaseService(backend: play, verifier: verifier);
      await strict.initialize();
      play.owned = <PurchaseDetails>[
        purchase('collection', PurchaseStatus.purchased,
            pendingComplete: false, json: signedJson)
      ];
      play.signatures['collection'] = 'forjada';
      await strict.refreshOwnership();
      expect(state.playOwned, isEmpty);

      play.signatures['collection'] = goodSignature;
      await strict.refreshOwnership();
      expect(state.playOwned, contains('collection'));
      strict.dispose();
    });

    test('a chave de licenciamento do app está configurada e é lida', () {
      expect(PurchaseVerifier(playLicenseKey).enabled, isTrue,
          reason: 'sem ela, compra forjada passaria');
    });

    test('chave vazia desliga a verificação (até o dono configurar)', () {
      expect(PurchaseVerifier('').enabled, isFalse);
      expect(PurchaseVerifier('').verify('{}', null), isTrue);
    });
  });

  test('loja de mentira nunca liga em build de release nativo', () {
    expect(
        PurchaseService.useDemoStore(
            requested: true, isWeb: false, isRelease: true),
        isFalse);
    expect(
        PurchaseService.useDemoStore(
            requested: true, isWeb: true, isRelease: true),
        isTrue);
  });
}

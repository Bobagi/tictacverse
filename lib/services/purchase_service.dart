import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../models/store_product.dart';
import 'economy_engine.dart';
import 'economy_service.dart';

/// Estado da loja de compras.
enum StoreAvailability { loading, ready, unavailable }

/// O que aconteceu com a última compra, para a tela dar o retorno certo.
enum PurchaseOutcomeKind { coins, adsRemoved, pending, canceled, failed }

class PurchaseOutcome {
  const PurchaseOutcome(this.kind, {this.coins = 0});

  final PurchaseOutcomeKind kind;
  final int coins;
}

/// Fronteira com o plugin da Play. Existe para o fluxo de crédito ser testado
/// sem plugin (ver `test/purchase_service_test.dart`).
abstract class PurchaseBackend {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<List<ProductDetails>> queryProducts(Set<String> ids);
  Future<bool> buy(ProductDetails product, {required bool consumable});
  Future<void> restore();

  /// Consome um pacote de moedas (libera a recompra e conta como confirmação).
  Future<bool> consume(PurchaseDetails purchase);

  /// Confirma a compra na Play. Sem isso em 3 dias a Play devolve o dinheiro.
  Future<void> complete(PurchaseDetails purchase);
}

class PlayPurchaseBackend implements PurchaseBackend {
  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> ids) async {
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);
    return response.productDetails;
  }

  @override
  Future<bool> buy(ProductDetails product, {required bool consumable}) {
    final PurchaseParam param = PurchaseParam(productDetails: product);
    // autoConsume DESLIGADO: o plugin consumiria antes de o app creditar, e um
    // app fechado nesse meio perderia as moedas. O consumo é manual, depois
    // do crédito gravado.
    return consumable
        ? _iap.buyConsumable(purchaseParam: param, autoConsume: false)
        : _iap.buyNonConsumable(purchaseParam: param);
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Future<bool> consume(PurchaseDetails purchase) async {
    final InAppPurchaseAndroidPlatformAddition android =
        _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final BillingResultWrapper result = await android.consumePurchase(purchase);
    return result.responseCode == BillingResponse.ok;
  }

  @override
  Future<void> complete(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}

/// Compras dentro do app pela Play: pacotes de moedas e "sem anúncios".
///
/// Sem servidor: o direito fica no `ProgressState` (aparelho) e a Play é quem
/// cobra. A regra de crédito é a do [EconomyEngine.applyStorePurchase]
/// (idempotente por token); aqui só fica o vai e vem com o plugin.
class PurchaseService {
  PurchaseService({PurchaseBackend? backend, EconomyService? economy})
      : _backendOverride = backend,
        _economy = economy ?? EconomyService.instance;

  static final PurchaseService instance = PurchaseService();

  /// QA: `--dart-define=FAKE_STORE=true` troca a Play por uma loja de mentira
  /// com preços fixos (para revisar a tela na web). Nunca em build de loja.
  static const bool _fakeStore = bool.fromEnvironment('FAKE_STORE');

  /// A loja de mentira só liga na web ou em build de debug. Um APK/AAB de
  /// release compilado por engano com `FAKE_STORE=true` continua cobrando
  /// pela Play: a flag sozinha não pode dar moeda de graça a ninguém.
  @visibleForTesting
  static bool useDemoStore({
    required bool requested,
    required bool isWeb,
    required bool isRelease,
  }) =>
      requested && (isWeb || !isRelease);

  final PurchaseBackend? _backendOverride;
  PurchaseBackend? _backend;
  final EconomyService _economy;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final ValueNotifier<StoreAvailability> availability =
      ValueNotifier<StoreAvailability>(StoreAvailability.loading);

  /// Último resultado, para a loja mostrar a mensagem. Uma compra pode
  /// concluir com a loja fechada (pagamento pendente que cai depois), por isso
  /// não é um retorno de `buy`.
  final ValueNotifier<PurchaseOutcome?> lastOutcome =
      ValueNotifier<PurchaseOutcome?>(null);

  /// Compra aberta na Play: trava o toque duplo até o resultado chegar.
  final ValueNotifier<String?> buying = ValueNotifier<String?>(null);

  final Map<String, ProductDetails> _products = <String, ProductDetails>{};

  ProductDetails? productFor(String id) => _products[id];

  /// Liga a escuta das compras e carrega os preços. Chame cedo no `main`: a
  /// Play entrega na abertura compras que ficaram pela metade (app fechado no
  /// meio, pagamento em dinheiro que caiu depois) e elas precisam ser
  /// creditadas e finalizadas.
  Future<void> initialize() async {
    if (_subscription != null) {
      return;
    }
    final PurchaseBackend? backend = _backendOverride ??
        (useDemoStore(
          requested: _fakeStore,
          isWeb: kIsWeb,
          isRelease: kReleaseMode,
        )
            ? _DemoPurchaseBackend()
            : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                ? PlayPurchaseBackend()
                : null);
    if (backend == null) {
      availability.value = StoreAvailability.unavailable;
      return;
    }
    _backend = backend;
    _subscription = backend.purchaseStream.listen(
      _onPurchases,
      onError: (Object _) {
        buying.value = null;
      },
    );
    try {
      if (!await backend.isAvailable()) {
        availability.value = StoreAvailability.unavailable;
        return;
      }
      final List<ProductDetails> found = await backend.queryProducts(
          <String>{for (final StoreProduct p in storeCatalog) p.id});
      _products
        ..clear()
        ..addEntries(found.map(
            (ProductDetails d) => MapEntry<String, ProductDetails>(d.id, d)));
      availability.value = _products.isEmpty
          ? StoreAvailability.unavailable
          : StoreAvailability.ready;
      // Devolve o "sem anúncios" a quem reinstalou e recolhe pacote de moedas
      // pago e não consumido.
      await backend.restore();
    } catch (_) {
      availability.value = StoreAvailability.unavailable;
    }
  }

  /// Abre a compra na Play. Devolve `false` se nem chegou a abrir.
  Future<bool> buy(String productId) async {
    final PurchaseBackend? backend = _backend;
    final ProductDetails? details = _products[productId];
    final StoreProduct? product = storeProductById(productId);
    if (backend == null ||
        details == null ||
        product == null ||
        buying.value != null) {
      return false;
    }
    if (product.kind == StoreProductKind.removeAds && _economy.adsRemoved) {
      return false;
    }
    buying.value = productId;
    lastOutcome.value = null;
    try {
      final bool started =
          await backend.buy(details, consumable: product.isConsumable);
      if (!started) {
        buying.value = null;
      }
      return started;
    } catch (_) {
      buying.value = null;
      lastOutcome.value = const PurchaseOutcome(PurchaseOutcomeKind.failed);
      return false;
    }
  }

  Future<void> restore() async {
    try {
      await _backend?.restore();
    } catch (_) {
      // Sem conexão com a Play: nada a restaurar agora.
    }
  }

  @visibleForTesting
  Future<void> handlePurchases(List<PurchaseDetails> purchases) =>
      _onPurchases(purchases);

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      await _handle(purchase);
    }
  }

  Future<void> _handle(PurchaseDetails purchase) async {
    final PurchaseBackend? backend = _backend;
    if (backend == null) {
      return;
    }
    final bool isCurrentBuy = buying.value == purchase.productID;
    switch (purchase.status) {
      case PurchaseStatus.pending:
        if (isCurrentBuy) {
          buying.value = null;
          lastOutcome.value =
              const PurchaseOutcome(PurchaseOutcomeKind.pending);
        }
        return;
      case PurchaseStatus.canceled:
      case PurchaseStatus.error:
        if (purchase.pendingCompletePurchase) {
          await _safe(() => backend.complete(purchase));
        }
        if (isCurrentBuy) {
          buying.value = null;
          lastOutcome.value = PurchaseOutcome(
              purchase.status == PurchaseStatus.canceled
                  ? PurchaseOutcomeKind.canceled
                  : PurchaseOutcomeKind.failed);
        }
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _deliver(backend, purchase, isCurrentBuy);
    }
  }

  Future<void> _deliver(
    PurchaseBackend backend,
    PurchaseDetails purchase,
    bool isCurrentBuy,
  ) async {
    final StoreProduct? product = storeProductById(purchase.productID);
    if (product == null) {
      // Produto que este app não conhece: só finaliza para não ficar preso.
      if (purchase.pendingCompletePurchase) {
        await _safe(() => backend.complete(purchase));
      }
      return;
    }
    // 1) credita e grava; 2) só então consome/confirma na Play. Na ordem
    // inversa, um app fechado no meio perderia o que o jogador pagou.
    final StoreGrant grant = await _economy.applyStorePurchase(
        purchase.productID, purchase.verificationData.serverVerificationData);
    if (product.isConsumable) {
      // Consumir também confirma; falhou, a Play reentrega e o token barra o
      // crédito em dobro.
      await _safe(() => backend.consume(purchase));
    } else if (purchase.pendingCompletePurchase) {
      await _safe(() => backend.complete(purchase));
    }
    final bool paidNow =
        grant.coins > 0 || (grant.removedAds && !grant.duplicate);
    if (isCurrentBuy || paidNow) {
      buying.value = null;
    }
    if (grant.coins > 0) {
      lastOutcome.value =
          PurchaseOutcome(PurchaseOutcomeKind.coins, coins: grant.coins);
    } else if (grant.removedAds && (!grant.duplicate || isCurrentBuy)) {
      lastOutcome.value = const PurchaseOutcome(PurchaseOutcomeKind.adsRemoved);
    }
  }

  static Future<void> _safe(Future<Object?> Function() call) async {
    try {
      await call();
    } catch (_) {
      // A Play reentrega o que não foi finalizado; tentar de novo é dela.
    }
  }

  @visibleForTesting
  void debugSetProducts(List<ProductDetails> products,
      {PurchaseBackend? backend}) {
    _backend = backend ?? _backend;
    _products
      ..clear()
      ..addEntries(products.map(
          (ProductDetails d) => MapEntry<String, ProductDetails>(d.id, d)));
    availability.value = products.isEmpty
        ? StoreAvailability.unavailable
        : StoreAvailability.ready;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Loja de mentira do `FAKE_STORE`: preços fixos e compra que conclui na hora.
class _DemoPurchaseBackend implements PurchaseBackend {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();
  int _serial = 0;

  static const Map<String, String> _prices = <String, String>{
    'remove_ads': r'R$ 4,99',
    'coins_300': r'R$ 4,99',
    'coins_1000': r'R$ 11,99',
    'coins_3000': r'R$ 24,99',
  };

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> ids) async =>
      <ProductDetails>[
        for (final String id in ids)
          ProductDetails(
              id: id,
              title: id,
              description: id,
              price: _prices[id] ?? '-',
              rawPrice: 0,
              currencyCode: 'BRL'),
      ];

  @override
  Future<bool> buy(ProductDetails product, {required bool consumable}) async {
    _serial++;
    Timer(const Duration(milliseconds: 600), () {
      _controller.add(<PurchaseDetails>[
        PurchaseDetails(
          purchaseID: 'demo-$_serial',
          productID: product.id,
          verificationData: PurchaseVerificationData(
              localVerificationData: '{}',
              serverVerificationData:
                  'demo-${DateTime.now().microsecondsSinceEpoch}',
              source: 'demo'),
          transactionDate: '0',
          status: PurchaseStatus.purchased,
        ),
      ]);
    });
    return true;
  }

  @override
  Future<void> restore() async {}

  @override
  Future<bool> consume(PurchaseDetails purchase) async => true;

  @override
  Future<void> complete(PurchaseDetails purchase) async {}
}

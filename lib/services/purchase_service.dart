import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../models/store_product.dart';
import 'economy_service.dart';
import 'purchase_verifier.dart';

/// Estado da loja de compras.
enum StoreAvailability { loading, ready, unavailable }

/// O que aconteceu com a última compra, para a tela dar o retorno certo.
enum PurchaseOutcomeKind { unlocked, pending, canceled, failed }

class PurchaseOutcome {
  const PurchaseOutcome(this.kind, {this.productId});

  final PurchaseOutcomeKind kind;
  final String? productId;
}

/// Fronteira com o plugin da Play. Existe para o fluxo ser testado sem
/// plugin (ver `test/purchase_service_test.dart`).
abstract class PurchaseBackend {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<List<ProductDetails>> queryProducts(Set<String> ids);
  Future<bool> buy(ProductDetails product);

  /// O que o jogador POSSUI agora segundo a Play (compra reembolsada não
  /// vem). `null` = não deu para perguntar (sem rede, Play fora): nesse caso
  /// o jogo segue com o último estado confirmado.
  Future<List<PurchaseDetails>?> queryOwned();

  /// Confirma a compra na Play. Sem isso em 3 dias a Play devolve o dinheiro.
  Future<void> complete(PurchaseDetails purchase);

  /// Assinatura que a Play pôs na compra (para [PurchaseVerifier]).
  String? signatureOf(PurchaseDetails purchase);
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
  Future<bool> buy(ProductDetails product) => _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product));

  @override
  Future<List<PurchaseDetails>?> queryOwned() async {
    final InAppPurchaseAndroidPlatformAddition android =
        _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final QueryPurchaseDetailsResponse res = await android.queryPastPurchases();
    if (res.error != null) {
      return null;
    }
    return res.pastPurchases;
  }

  @override
  Future<void> complete(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);

  @override
  String? signatureOf(PurchaseDetails purchase) =>
      purchase is GooglePlayPurchaseDetails
          ? purchase.billingClientPurchase.signature
          : null;
}

/// Compras dentro do app, SEM servidor próprio.
///
/// Todos os produtos são de compra única (ver [StoreProduct]). A cada
/// abertura, e depois de cada compra, o app pergunta à Play o que o jogador
/// possui e grava só essa lista; o que ela libera é calculado
/// (`ProgressState.entitlements`). Compra reembolsada some da lista da Play
/// e o direito some junto na consulta seguinte. Sem rede, vale o último
/// estado confirmado.
///
/// Cada compra tem a assinatura conferida com a chave pública do app
/// ([PurchaseVerifier]) antes de liberar qualquer coisa.
class PurchaseService {
  PurchaseService({
    PurchaseBackend? backend,
    EconomyService? economy,
    PurchaseVerifier? verifier,
  })  : _backendOverride = backend,
        _economy = economy ?? EconomyService.instance,
        // A loja de mentira (QA na web) não assina nada; só ela dispensa a
        // conferência. A Play de verdade sempre passa pela chave.
        _verifier = verifier ?? PurchaseVerifier(_demo ? '' : playLicenseKey);

  static final PurchaseService instance = PurchaseService();

  /// QA: `--dart-define=FAKE_STORE=true` troca a Play por uma loja de mentira
  /// com preços fixos (para revisar a tela na web). Nunca em build de loja.
  static const bool _fakeStore = bool.fromEnvironment('FAKE_STORE');

  /// A loja de mentira só liga na web ou em build de debug. Um APK/AAB de
  /// release compilado por engano com `FAKE_STORE=true` continua cobrando
  /// pela Play: a flag sozinha não libera nada a ninguém.
  @visibleForTesting
  static bool useDemoStore({
    required bool requested,
    required bool isWeb,
    required bool isRelease,
  }) =>
      requested && (isWeb || !isRelease);

  static bool get _demo => useDemoStore(
        requested: _fakeStore,
        isWeb: kIsWeb,
        isRelease: kReleaseMode,
      );

  final PurchaseBackend? _backendOverride;
  PurchaseBackend? _backend;
  final EconomyService _economy;
  final PurchaseVerifier _verifier;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _refreshing = false;

  final ValueNotifier<StoreAvailability> availability =
      ValueNotifier<StoreAvailability>(StoreAvailability.loading);

  /// Último resultado, para a loja mostrar a mensagem. Uma compra pode
  /// concluir com a loja fechada (pagamento pendente que cai depois).
  final ValueNotifier<PurchaseOutcome?> lastOutcome =
      ValueNotifier<PurchaseOutcome?>(null);

  /// Compra aberta na Play: trava o toque duplo até o resultado chegar.
  final ValueNotifier<String?> buying = ValueNotifier<String?>(null);

  final Map<String, ProductDetails> _products = <String, ProductDetails>{};

  ProductDetails? productFor(String id) => _products[id];

  /// Liga a escuta das compras, carrega os preços e pergunta à Play o que o
  /// jogador possui. Chame cedo no `main`.
  Future<void> initialize() async {
    if (_subscription != null) {
      return;
    }
    final PurchaseBackend? backend = _backendOverride ??
        (_demo
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
      await refreshOwnership();
    } catch (_) {
      availability.value = StoreAvailability.unavailable;
    }
  }

  /// Pergunta à Play o que o jogador possui e grava. Também confirma compra
  /// paga que ficou sem confirmação (app fechado no meio). Chamado na
  /// abertura, depois de cada compra e no "Restaurar compras".
  Future<void> refreshOwnership() async {
    final PurchaseBackend? backend = _backend;
    if (backend == null || _refreshing) {
      return;
    }
    _refreshing = true;
    try {
      final List<PurchaseDetails>? owned = await backend.queryOwned();
      if (owned == null) {
        // Sem resposta da Play: mantém o último estado confirmado.
        return;
      }
      final Set<String> ids = <String>{};
      for (final PurchaseDetails p in owned) {
        if (p.status != PurchaseStatus.purchased &&
            p.status != PurchaseStatus.restored) {
          continue;
        }
        if (!_isGenuine(backend, p)) {
          continue;
        }
        ids.add(p.productID);
        if (p.pendingCompletePurchase) {
          await _safe(() => backend.complete(p));
        }
      }
      await _economy.applyPlayOwnership(ids);
    } catch (_) {
      // Erro de plugin: o último estado confirmado continua valendo.
    } finally {
      _refreshing = false;
    }
  }

  /// Abre a compra na Play. Devolve `false` se nem chegou a abrir.
  Future<bool> buy(String productId) async {
    final PurchaseBackend? backend = _backend;
    final ProductDetails? details = _products[productId];
    if (backend == null ||
        details == null ||
        storeProductById(productId) == null ||
        buying.value != null ||
        isOwned(productId)) {
      return false;
    }
    buying.value = productId;
    lastOutcome.value = null;
    try {
      final bool started = await backend.buy(details);
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

  /// Já possui este produto (não deixa pagar duas vezes).
  bool isOwned(String productId) => _economy.playOwned.contains(productId);

  Future<void> restore() => refreshOwnership();

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
        break;
    }
    if (storeProductById(purchase.productID) == null ||
        !_isGenuine(backend, purchase)) {
      // Produto que este app não vende ou assinatura que não confere: não
      // libera nada e não confirma (compra forjada a Play nem conhece).
      if (isCurrentBuy) {
        buying.value = null;
        lastOutcome.value = const PurchaseOutcome(PurchaseOutcomeKind.failed);
      }
      return;
    }
    // Confirma na Play e pergunta de novo o que o jogador possui: a lista da
    // Play continua sendo a única fonte do que fica liberado.
    if (purchase.pendingCompletePurchase) {
      await _safe(() => backend.complete(purchase));
    }
    final bool already = isOwned(purchase.productID);
    await refreshOwnership();
    if (!isOwned(purchase.productID)) {
      // A consulta ainda não trouxe a compra recém-feita (cache da Play
      // atrasado): libera com a compra que chegou assinada agora; a próxima
      // consulta corrige se ela não valer.
      await _economy.applyPlayOwnership(
          <String>{..._economy.playOwned, purchase.productID});
    }
    if (isCurrentBuy) {
      buying.value = null;
    }
    if (isCurrentBuy || !already) {
      lastOutcome.value = PurchaseOutcome(PurchaseOutcomeKind.unlocked,
          productId: purchase.productID);
    }
  }

  bool _isGenuine(PurchaseBackend backend, PurchaseDetails p) => _verifier
      .verify(p.verificationData.localVerificationData, backend.signatureOf(p));

  static Future<void> _safe(Future<Object?> Function() call) async {
    try {
      await call();
    } catch (_) {
      // A Play reentrega o que não foi confirmado; tentar de novo é dela.
    }
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
  final List<PurchaseDetails> _owned = <PurchaseDetails>[];
  int _serial = 0;

  static const Map<String, double> _prices = <String, double>{
    'starter_pack': 9.99,
    'remove_ads': 4.99,
    'collection': 24.99,
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
              price:
                  'R\$ ${(_prices[id] ?? 0).toStringAsFixed(2).replaceAll('.', ',')}',
              rawPrice: _prices[id] ?? 0,
              currencyCode: 'BRL'),
      ];

  @override
  Future<bool> buy(ProductDetails product) async {
    _serial++;
    Timer(const Duration(milliseconds: 600), () {
      final PurchaseDetails p = PurchaseDetails(
        purchaseID: 'demo-$_serial',
        productID: product.id,
        verificationData: PurchaseVerificationData(
            localVerificationData: '{}',
            serverVerificationData: 'demo-$_serial',
            source: 'demo'),
        transactionDate: '0',
        status: PurchaseStatus.purchased,
      );
      _owned.add(p);
      _controller.add(<PurchaseDetails>[p]);
    });
    return true;
  }

  @override
  Future<List<PurchaseDetails>?> queryOwned() async =>
      List<PurchaseDetails>.of(_owned);

  @override
  Future<void> complete(PurchaseDetails purchase) async {}

  @override
  String? signatureOf(PurchaseDetails purchase) => null;
}

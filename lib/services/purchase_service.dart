import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../models/store_product.dart';
import 'economy_engine.dart';
import 'economy_service.dart';
import 'storage_service.dart';
import 'verse_api.dart';

/// Estado da loja de compras.
enum StoreAvailability { loading, ready, unavailable }

/// O que aconteceu com a última compra, para a tela dar o retorno certo.
enum PurchaseOutcomeKind {
  coins,
  adsRemoved,
  pending,

  /// Pago na Play, esperando o servidor confirmar (sem rede, servidor fora).
  verifying,
  canceled,
  failed,
}

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

  /// [accountId] vai para a Play como `obfuscatedAccountId`: o servidor só
  /// aceita um pacote de moedas na instalação que o comprou.
  Future<bool> buy(ProductDetails product,
      {required bool consumable, required String accountId});
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
  Future<bool> buy(ProductDetails product,
      {required bool consumable, required String accountId}) {
    final PurchaseParam param =
        PurchaseParam(productDetails: product, applicationUserName: accountId);
    // autoConsume DESLIGADO: o plugin consumiria antes de o servidor
    // confirmar e o app creditar. O consumo é manual, depois do crédito.
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

/// Compras dentro do app pela Play: pacotes de moedas, "sem anúncios" e o
/// pacote de boas-vindas.
///
/// Toda compra é validada no servidor do jogo (`tictacverse-api`), que
/// consulta a Play: token falso, de outra instalação, já resgatado ou
/// estornado não entrega nada. Ordem que não se inverte: servidor confirma,
/// app credita e grava, e SÓ ENTÃO a compra é consumida/confirmada na Play.
/// Servidor fora do ar = a compra fica pendente e é tentada de novo (a Play
/// reentrega o que não foi finalizado).
class PurchaseService {
  PurchaseService({
    PurchaseBackend? backend,
    EconomyService? economy,
    VerseApi? api,
    String Function()? installId,
  })  : _backendOverride = backend,
        _economy = economy ?? EconomyService.instance,
        _apiOverride = api,
        _installId = installId ?? (() => StorageService.instance.installId);

  static final PurchaseService instance = PurchaseService();

  /// QA: `--dart-define=FAKE_STORE=true` troca a Play por uma loja de mentira
  /// com preços fixos (para revisar a tela na web). Nunca em build de loja.
  static const bool _fakeStore = bool.fromEnvironment('FAKE_STORE');

  /// A loja de mentira só liga na web ou em build de debug. Um APK/AAB de
  /// release compilado por engano com `FAKE_STORE=true` continua cobrando
  /// pela Play e validando no servidor: a flag sozinha não dá moeda a ninguém.
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

  /// Esperas entre as novas tentativas quando o servidor não respondeu.
  static const List<Duration> retryDelays = <Duration>[
    Duration(seconds: 20),
    Duration(minutes: 2),
    Duration(minutes: 10),
  ];

  final PurchaseBackend? _backendOverride;
  PurchaseBackend? _backend;
  final EconomyService _economy;
  final VerseApi? _apiOverride;
  late final VerseApi _api =
      _apiOverride ?? (_demo ? DemoVerseApi() : HttpVerseApi());
  final String Function() _installId;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Timer? _retryTimer;
  int _retryAttempt = 0;
  bool _syncingRevocations = false;

  /// Compras pagas que o servidor ainda não confirmou, por token.
  final Map<String, PurchaseDetails> _awaitingServer =
      <String, PurchaseDetails>{};

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

  bool get hasPendingVerification => _awaitingServer.isNotEmpty;

  /// Liga a escuta das compras, carrega os preços e sincroniza estornos.
  /// Chame cedo no `main`: a Play entrega na abertura compras que ficaram
  /// pela metade e elas precisam ser validadas e finalizadas.
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
      // Estornos primeiro: se o "sem anúncios" foi estornado e o jogador tem
      // outro válido, o restore logo em seguida devolve o direito.
      await syncRevocations();
      // Devolve o "sem anúncios" a quem reinstalou e recolhe compra paga e
      // não finalizada.
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
    if (!product.isConsumable && product.removeAds && _economy.adsRemoved) {
      // Já tem o direito: não deixa pagar de novo por ele.
      return false;
    }
    buying.value = productId;
    lastOutcome.value = null;
    try {
      final bool started = await backend.buy(details,
          consumable: product.isConsumable, accountId: _installId());
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

  /// Busca no servidor as compras desta instalação que foram estornadas e as
  /// desfaz aqui. Seguro chamar várias vezes (cada estorno vale uma vez).
  Future<void> syncRevocations() async {
    if (_syncingRevocations) {
      return;
    }
    _syncingRevocations = true;
    try {
      final List<Revocation>? list = await _api.revocations(_installId());
      if (list == null) {
        return;
      }
      bool lostAds = false;
      for (final Revocation r in list) {
        final RevocationEffect effect = await _economy.applyRevocation(
            redemptionId: r.redemptionId,
            coins: r.coins,
            removeAds: r.removeAds);
        lostAds = lostAds || effect.lostAdsRemoval;
      }
      if (lostAds) {
        // Se houver outra compra válida de "sem anúncios", ela volta aqui.
        await restore();
      }
    } finally {
      _syncingRevocations = false;
    }
  }

  @visibleForTesting
  Future<void> handlePurchases(List<PurchaseDetails> purchases) =>
      _onPurchases(purchases);

  /// Tenta de novo, agora, as compras pagas que o servidor não confirmou.
  @visibleForTesting
  Future<void> retryPendingVerifications() async {
    final List<PurchaseDetails> waiting = _awaitingServer.values.toList();
    for (final PurchaseDetails purchase in waiting) {
      await _handle(purchase);
    }
  }

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
    final String token = purchase.verificationData.serverVerificationData;
    if (product == null || token.isEmpty) {
      // Produto que este app não conhece: só finaliza para não ficar preso.
      if (purchase.pendingCompletePurchase) {
        await _safe(() => backend.complete(purchase));
      }
      if (isCurrentBuy) {
        buying.value = null;
      }
      return;
    }
    final VerifyResult verdict = await _api.verifyPurchase(
      installId: _installId(),
      productId: purchase.productID,
      purchaseToken: token,
    );
    switch (verdict.status) {
      case VerifyStatus.retry:
        // Pago na Play, servidor sem resposta: NÃO credita e NÃO finaliza.
        // A Play guarda a compra; tentamos de novo daqui a pouco e a cada
        // abertura do app.
        _awaitingServer[token] = purchase;
        _scheduleRetry();
        if (isCurrentBuy) {
          buying.value = null;
          lastOutcome.value =
              const PurchaseOutcome(PurchaseOutcomeKind.verifying);
        }
        return;
      case VerifyStatus.pending:
        _awaitingServer.remove(token);
        if (isCurrentBuy) {
          buying.value = null;
          lastOutcome.value =
              const PurchaseOutcome(PurchaseOutcomeKind.pending);
        }
        return;
      case VerifyStatus.invalid:
      case VerifyStatus.revoked:
        // Nada a entregar. Também não finaliza: compra que a Play diz não
        // valer não deve ser confirmada por nós.
        _awaitingServer.remove(token);
        if (isCurrentBuy) {
          buying.value = null;
          lastOutcome.value = const PurchaseOutcome(PurchaseOutcomeKind.failed);
        }
        return;
      case VerifyStatus.granted:
        break;
    }
    _awaitingServer.remove(token);
    // 1) credita e grava; 2) só então consome/confirma na Play. Na ordem
    // inversa, um app fechado no meio perderia o que o jogador pagou.
    final StoreGrant grant = await _economy.applyServerGrant(
      purchaseToken: token,
      coins: verdict.coins,
      removeAds: verdict.removeAds,
    );
    if (product.isConsumable) {
      // Consumir também confirma; falhou, a Play reentrega e o token barra o
      // crédito em dobro.
      await _safe(() => backend.consume(purchase));
    } else if (purchase.pendingCompletePurchase) {
      await _safe(() => backend.complete(purchase));
    }
    if (isCurrentBuy || !grant.duplicate) {
      buying.value = null;
    }
    if (grant.coins > 0) {
      lastOutcome.value =
          PurchaseOutcome(PurchaseOutcomeKind.coins, coins: grant.coins);
    } else if (grant.removedAds && (!grant.duplicate || isCurrentBuy)) {
      lastOutcome.value = const PurchaseOutcome(PurchaseOutcomeKind.adsRemoved);
    }
  }

  void _scheduleRetry() {
    if (_retryTimer?.isActive ?? false) {
      return;
    }
    final Duration wait =
        retryDelays[_retryAttempt.clamp(0, retryDelays.length - 1)];
    _retryAttempt++;
    _retryTimer = Timer(wait, () async {
      await retryPendingVerifications();
      if (_awaitingServer.isEmpty) {
        _retryAttempt = 0;
      } else if (_retryAttempt < retryDelays.length) {
        _scheduleRetry();
      }
      // Esgotou as tentativas desta sessão: a próxima abertura do app
      // (restore) entrega a compra de novo.
    });
  }

  static Future<void> _safe(Future<Object?> Function() call) async {
    try {
      await call();
    } catch (_) {
      // A Play reentrega o que não foi finalizado; tentar de novo é dela.
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Loja de mentira do `FAKE_STORE`: preços fixos e compra que conclui na hora.
class _DemoPurchaseBackend implements PurchaseBackend {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();
  int _serial = 0;

  static const Map<String, double> _prices = <String, double>{
    'starter_pack': 9.99,
    'remove_ads': 4.99,
    'coins_300': 4.99,
    'coins_1000': 12.99,
    'coins_3000': 25.99,
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
  Future<bool> buy(ProductDetails product,
      {required bool consumable, required String accountId}) async {
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

/// Servidor de mentira do `FAKE_STORE` (revisão de tela na web): confirma o
/// que o catálogo diz. Só existe no modo de QA.
class DemoVerseApi implements VerseApi {
  @override
  Future<VerifyResult> verifyPurchase({
    required String installId,
    required String productId,
    required String purchaseToken,
  }) async {
    final StoreProduct? p = storeProductById(productId);
    if (p == null) {
      return const VerifyResult(VerifyStatus.invalid);
    }
    return VerifyResult(VerifyStatus.granted,
        coins: p.coins, removeAds: p.removeAds, redemptionId: purchaseToken);
  }

  @override
  Future<List<Revocation>?> revocations(String installId) async =>
      const <Revocation>[];

  @override
  Future<bool> ping({
    required String installId,
    required String appVersion,
    required String locale,
  }) async =>
      true;
}

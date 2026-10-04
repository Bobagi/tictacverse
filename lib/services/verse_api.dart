import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Resposta do servidor ao validar uma compra.
enum VerifyStatus {
  /// Compra confirmada na Play. [VerifyResult.coins] e
  /// [VerifyResult.removeAds] dizem o que entregar.
  granted,

  /// A Play ainda não confirmou o pagamento (dinheiro, boleto): nada a entregar.
  pending,

  /// Token falso, cancelado, de outra instalação ou já resgatado: não entrega.
  invalid,

  /// A compra foi reembolsada ou estornada: não entrega.
  revoked,

  /// Servidor ou Play fora do ar: tente de novo depois, sem entregar e SEM
  /// finalizar a compra na Play.
  retry,
}

class VerifyResult {
  const VerifyResult(this.status,
      {this.coins = 0, this.removeAds = false, this.redemptionId});

  final VerifyStatus status;
  final int coins;
  final bool removeAds;
  final String? redemptionId;

  static const VerifyResult retryLater = VerifyResult(VerifyStatus.retry);
}

/// Compra estornada que esta instalação já tinha recebido: o app desfaz.
class Revocation {
  const Revocation({
    required this.redemptionId,
    required this.productId,
    required this.coins,
    required this.removeAds,
  });

  final String redemptionId;
  final String productId;
  final int coins;
  final bool removeAds;
}

/// Fronteira com o servidor do jogo (`tictacverse-api`). Os testes usam uma
/// implementação falsa; o app usa [HttpVerseApi].
abstract class VerseApi {
  Future<VerifyResult> verifyPurchase({
    required String installId,
    required String productId,
    required String purchaseToken,
  });

  /// `null` = não deu para consultar agora (sem rede); lista vazia = nada.
  Future<List<Revocation>?> revocations(String installId);

  /// Registra que esta instalação abriu o jogo hoje (retenção D1/D7).
  Future<bool> ping({
    required String installId,
    required String appVersion,
    required String locale,
  });
}

class HttpVerseApi implements VerseApi {
  HttpVerseApi({String? baseUrl, HttpClient? client})
      : _base = Uri.parse(baseUrl ?? defaultBaseUrl),
        _client = client ?? HttpClient()
          ..connectionTimeout = const Duration(seconds: 8);

  /// QA aponta para outro servidor com `--dart-define=API_BASE=...`.
  static const String defaultBaseUrl = String.fromEnvironment('API_BASE',
      defaultValue: 'https://tictacverse-api.bobagi.space');

  static const Duration _timeout = Duration(seconds: 12);

  final Uri _base;
  final HttpClient _client;

  @override
  Future<VerifyResult> verifyPurchase({
    required String installId,
    required String productId,
    required String purchaseToken,
  }) async {
    final (int, Object?)? res =
        await _send('POST', '/v1/purchases/verify', <String, Object?>{
      'installId': installId,
      'productId': productId,
      'purchaseToken': purchaseToken,
    });
    if (res == null || res.$1 >= 500 || res.$2 is! Map<String, dynamic>) {
      return VerifyResult.retryLater;
    }
    if (res.$1 != 200) {
      // 4xx: pedido recusado pelo servidor (formato ou limite). Tentar de
      // novo depois é mais seguro do que entregar ou perder a compra.
      return VerifyResult.retryLater;
    }
    return parseVerify(res.$2! as Map<String, dynamic>);
  }

  /// Leitura tolerante da resposta: campo estranho nunca vira entrega.
  static VerifyResult parseVerify(Map<String, dynamic> json) {
    final VerifyStatus status = switch (json['status']) {
      'granted' => VerifyStatus.granted,
      'pending' => VerifyStatus.pending,
      'invalid' => VerifyStatus.invalid,
      'revoked' => VerifyStatus.revoked,
      _ => VerifyStatus.retry,
    };
    if (status != VerifyStatus.granted) {
      return VerifyResult(status);
    }
    final Object? coins = json['coins'];
    final Object? id = json['redemptionId'];
    return VerifyResult(
      VerifyStatus.granted,
      coins: coins is int && coins > 0 && coins <= 100000 ? coins : 0,
      removeAds: json['removeAds'] == true,
      redemptionId: id is String || id is int ? '$id' : null,
    );
  }

  @override
  Future<List<Revocation>?> revocations(String installId) async {
    final (int, Object?)? res = await _send(
        'GET', '/v1/installs/${Uri.encodeComponent(installId)}/revocations');
    if (res == null || res.$1 != 200 || res.$2 is! Map<String, dynamic>) {
      return null;
    }
    final Object? list = (res.$2! as Map<String, dynamic>)['revocations'];
    if (list is! List) {
      return null;
    }
    return <Revocation>[
      for (final Object? raw in list)
        if (raw is Map<String, dynamic> &&
            (raw['redemptionId'] is String || raw['redemptionId'] is int))
          Revocation(
            redemptionId: '${raw['redemptionId']}',
            productId:
                raw['productId'] is String ? raw['productId'] as String : '',
            coins: raw['coins'] is int ? raw['coins'] as int : 0,
            removeAds: raw['removeAds'] == true,
          ),
    ];
  }

  @override
  Future<bool> ping({
    required String installId,
    required String appVersion,
    required String locale,
  }) async {
    final (int, Object?)? res =
        await _send('POST', '/v1/ping', <String, Object?>{
      'installId': installId,
      'appVersion': appVersion,
      'locale': locale,
    });
    return res != null && res.$1 >= 200 && res.$1 < 300;
  }

  /// Devolve (status, corpo JSON) ou `null` sem rede/tempo esgotado.
  Future<(int, Object?)?> _send(String method, String path,
      [Map<String, Object?>? body]) async {
    try {
      final HttpClientRequest req =
          await _client.openUrl(method, _base.resolve(path)).timeout(_timeout);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(body));
      }
      final HttpClientResponse resp = await req.close().timeout(_timeout);
      final String text =
          await resp.transform(utf8.decoder).join().timeout(_timeout);
      Object? decoded;
      if (text.isNotEmpty) {
        try {
          decoded = jsonDecode(text);
        } catch (_) {
          decoded = null;
        }
      }
      return (resp.statusCode, decoded);
    } catch (_) {
      return null;
    }
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/online_match.dart';

/// Erro do online já classificado: [code] é o do servidor (`not_your_turn`,
/// `stale`, `taken`, ...) ou `network` quando nem chegou lá. Se o servidor
/// mandou o estado atual da partida junto, ele vem em [match].
class OnlineApiException implements Exception {
  const OnlineApiException(this.status, this.code, {this.match});

  final int status;
  final String code;
  final OnlineMatch? match;

  bool get isNetwork => status == 0;

  @override
  String toString() => 'OnlineApiException($status, $code)';
}

class OnlineRegistration {
  const OnlineRegistration(this.token, this.profile);

  final String token;
  final OnlineProfile profile;
}

/// Conversa com o servidor das partidas. A implementação de verdade é
/// [HttpOnlineApi]; testes e o QA na web usam a falsa (fake_online_api.dart).
abstract class OnlineApi {
  Future<OnlineRegistration> register();
  Future<OnlineProfile> me(String token);
  Future<void> deleteMe(String token);
  Future<List<OnlineMatch>> matches(String token);
  Future<OnlineMatch> create(String token);
  Future<OnlineMatch> join(String token, String code);

  /// Com [since], espera (long poll, até ~25 s) uma versão maior que ela.
  Future<OnlineMatch> fetch(String token, String id, {int? since});
  Future<OnlineMatch> move(
      String token, String id, int board, int cell, int version);
  Future<OnlineMatch> resign(String token, String id);
  Future<OnlineMatch> rematch(String token, String id);
}

class HttpOnlineApi implements OnlineApi {
  HttpOnlineApi({http.Client? client, this.baseUrl = defaultBaseUrl})
      : _client = client ?? http.Client();

  static const String defaultBaseUrl = 'https://tictacverse.bobagi.space';

  final http.Client _client;
  final String baseUrl;

  static const Duration _timeout = Duration(seconds: 12);
  static const Duration _pollTimeout = Duration(seconds: 40);

  Future<Map<String, dynamic>?> _send(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
    Duration timeout = _timeout,
  }) async {
    final http.Request request =
        http.Request(method, Uri.parse('$baseUrl$path'));
    if (token != null) {
      request.headers['authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    late final http.Response response;
    try {
      response = await http.Response.fromStream(
          await _client.send(request).timeout(timeout));
    } on TimeoutException {
      throw const OnlineApiException(0, 'network');
    } catch (_) {
      throw const OnlineApiException(0, 'network');
    }
    Map<String, dynamic>? data;
    if (response.body.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(response.body);
        data = decoded is Map<String, dynamic> ? decoded : null;
      } on FormatException {
        data = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    OnlineMatch? match;
    try {
      match =
          data?['match'] == null ? null : OnlineMatch.fromJson(data!['match']);
    } on FormatException {
      match = null;
    }
    throw OnlineApiException(
      response.statusCode,
      data?['error'] is String
          ? data!['error'] as String
          : 'http_${response.statusCode}',
      match: match,
    );
  }

  OnlineMatch _match(Map<String, dynamic>? data) {
    try {
      return OnlineMatch.fromJson(data?['match']);
    } on FormatException {
      throw const OnlineApiException(0, 'bad_response');
    }
  }

  @override
  Future<OnlineRegistration> register() async {
    final Map<String, dynamic>? data =
        await _send('POST', '/v1/online/players', body: <String, Object?>{});
    final Object? token = data?['token'];
    if (token is! String) {
      throw const OnlineApiException(0, 'bad_response');
    }
    return OnlineRegistration(token, OnlineProfile.fromJson(data!['player']));
  }

  @override
  Future<OnlineProfile> me(String token) async {
    final Map<String, dynamic>? data =
        await _send('GET', '/v1/online/me', token: token);
    try {
      return OnlineProfile.fromJson(data?['player']);
    } on FormatException {
      throw const OnlineApiException(0, 'bad_response');
    }
  }

  @override
  Future<void> deleteMe(String token) =>
      _send('DELETE', '/v1/online/me', token: token);

  @override
  Future<List<OnlineMatch>> matches(String token) async {
    final Map<String, dynamic>? data =
        await _send('GET', '/v1/online/matches', token: token);
    final Object? list = data?['matches'];
    if (list is! List) {
      throw const OnlineApiException(0, 'bad_response');
    }
    final List<OnlineMatch> out = <OnlineMatch>[];
    for (final Object? m in list) {
      try {
        out.add(OnlineMatch.fromJson(m));
      } on FormatException {
        // Uma partida torta não esconde as outras.
      }
    }
    return out;
  }

  @override
  Future<OnlineMatch> create(String token) async =>
      _match(await _send('POST', '/v1/online/matches',
          token: token, body: <String, Object?>{}));

  @override
  Future<OnlineMatch> join(String token, String code) async =>
      _match(await _send('POST', '/v1/online/matches/join',
          token: token, body: <String, Object?>{'code': code}));

  @override
  Future<OnlineMatch> fetch(String token, String id, {int? since}) async =>
      _match(await _send(
        'GET',
        '/v1/online/matches/${Uri.encodeComponent(id)}'
            '${since == null ? '' : '?since=$since'}',
        token: token,
        timeout: since == null ? _timeout : _pollTimeout,
      ));

  @override
  Future<OnlineMatch> move(
          String token, String id, int board, int cell, int version) async =>
      _match(await _send(
        'POST',
        '/v1/online/matches/${Uri.encodeComponent(id)}/moves',
        token: token,
        body: <String, Object?>{
          'board': board,
          'cell': cell,
          'version': version
        },
      ));

  @override
  Future<OnlineMatch> resign(String token, String id) async =>
      _match(await _send(
          'POST', '/v1/online/matches/${Uri.encodeComponent(id)}/resign',
          token: token, body: <String, Object?>{}));

  @override
  Future<OnlineMatch> rematch(String token, String id) async =>
      _match(await _send(
          'POST', '/v1/online/matches/${Uri.encodeComponent(id)}/rematch',
          token: token, body: <String, Object?>{}));
}

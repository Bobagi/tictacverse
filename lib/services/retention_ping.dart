import 'package:package_info_plus/package_info_plus.dart';

import 'progression_engine.dart';
import 'storage_service.dart';
import 'verse_api.dart';

/// Avisa o servidor, uma vez por dia, que esta instalação abriu o jogo. É o
/// que dá a retenção D1/D7 (quantos voltam no dia seguinte e na semana
/// seguinte), que a Play Console não mostra para o app.
///
/// Vai só o id aleatório da instalação, a versão do app e o idioma. Nada de
/// nome, conta, aparelho ou localização; o servidor não guarda IP.
class RetentionPing {
  RetentionPing({VerseApi? api, DateTime Function()? clock})
      : _api = api ?? HttpVerseApi(),
        _clock = clock ?? DateTime.now;

  final VerseApi _api;
  final DateTime Function() _clock;

  Future<void> sendIfDue({required String locale, String? version}) async {
    final StorageService storage = StorageService.instance;
    final String today = ProgressionEngine.dayKey(_clock());
    if (storage.lastPingDay == today) {
      return;
    }
    String appVersion = version ?? '';
    if (appVersion.isEmpty) {
      try {
        final PackageInfo info = await PackageInfo.fromPlatform();
        appVersion = '${info.version}+${info.buildNumber}';
      } catch (_) {
        appVersion = 'unknown';
      }
    }
    final bool ok = await _api.ping(
      installId: storage.installId,
      appVersion: appVersion,
      locale: locale,
    );
    if (ok) {
      // Só marca o dia com o envio confirmado: sem rede, tenta na próxima
      // abertura.
      await storage.saveLastPingDay(today);
    }
  }
}

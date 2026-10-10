import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'online_service.dart';

/// Recebe os links de convite que o Android entrega (MainActivity.kt) e
/// deixa o código em [OnlineService.pendingCode]; a home abre a partida.
class DeepLinks {
  DeepLinks._();

  static const MethodChannel _channel = MethodChannel('tictacverse/links');

  static Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onLink') {
        _deliver(call.arguments as String?);
      }
    });
    try {
      _deliver(await _channel.invokeMethod<String>('getInitialLink'));
    } on PlatformException {
      // Sem canal (teste, outra plataforma): segue sem link.
    } on MissingPluginException {
      // idem
    }
  }

  static void _deliver(String? link) {
    final String? code = OnlineService.codeFromLink(link);
    if (code != null) {
      OnlineService.instance.pendingCode.value = code;
    }
  }
}

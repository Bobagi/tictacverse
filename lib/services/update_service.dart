import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateCheckOutcome { upToDate, updateStarted, openedStore, failed }

/// Checa atualizações pelo Play In-App Updates; se houver, dispara o fluxo
/// nativo de atualização. Fora do Play (web/sideload), abre a ficha na loja.
class UpdateService {
  UpdateService._();

  static final UpdateService instance = UpdateService._();

  /// true quando o Play informou que existe versão mais nova (badge vermelho
  /// no ícone de configurações e no botão de atualizações).
  final ValueNotifier<bool> updateAvailable = ValueNotifier<bool>(false);

  static final Uri _storeUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.bobagi.tictacverse');

  /// Checagem silenciosa no boot (Android). Nunca lança/trava o app.
  Future<void> silentCheck() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      updateAvailable.value =
          info.updateAvailability == UpdateAvailability.updateAvailable;
    } catch (_) {
      // Sem Play Store (sideload/dev): fica sem badge.
    }
  }

  Future<UpdateCheckOutcome> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return _openStore();
    }
    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
          updateAvailable.value = false;
          return UpdateCheckOutcome.updateStarted;
        }
        return _openStore();
      }
      updateAvailable.value = false;
      return UpdateCheckOutcome.upToDate;
    } catch (_) {
      // Build fora do Play (teste interno via link, sideload): manda pra loja.
      return _openStore();
    }
  }

  Future<UpdateCheckOutcome> _openStore() async {
    try {
      final bool opened =
          await launchUrl(_storeUri, mode: LaunchMode.externalApplication);
      return opened ? UpdateCheckOutcome.openedStore : UpdateCheckOutcome.failed;
    } catch (_) {
      return UpdateCheckOutcome.failed;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateCheckOutcome { upToDate, updateStarted, openedStore, failed }

/// Checa atualizações pelo Play In-App Updates; se houver, dispara o fluxo
/// nativo de atualização. Fora do Play (web/sideload), abre a ficha na loja.
class UpdateService {
  UpdateService._();

  /// Instância isolada para teste (o singleton guarda estado entre casos).
  @visibleForTesting
  UpdateService.forTest();

  static final UpdateService instance = UpdateService._();

  /// true quando o Play informou que existe versão mais nova (badge vermelho
  /// no ícone de configurações e no botão de atualizações).
  final ValueNotifier<bool> updateAvailable = ValueNotifier<bool>(false);

  /// QA: `--dart-define=FAKE_UPDATE=true` finge que existe versão nova (inclusive
  /// na web e fora da Play), para dar para ver o aviso de atualização sem
  /// precisar publicar uma versão maior. Nunca é definido em build de loja.
  static const bool _fakeUpdate = bool.fromEnvironment('FAKE_UPDATE');

  Future<void>? _startupCheck;

  /// A checagem de inicialização em andamento (ou concluída). A home espera
  /// por ela para decidir se mostra o aviso de nova versão.
  Future<void> get startupCheck => _startupCheck ?? Future<void>.value();

  /// O aviso de nova versão já apareceu nesta sessão? Uma vez por abertura do
  /// app: repetir a cada volta à home viraria um chato.
  bool promptedThisSession = false;

  static final Uri _storeUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.bobagi.tictacverse');

  /// Checagem silenciosa no boot (Android). Nunca lança/trava o app. Guarda o
  /// Future em [startupCheck] para a tela inicial poder esperar o resultado.
  Future<void> silentCheck() {
    return _startupCheck ??= _silentCheck();
  }

  Future<void> _silentCheck() async {
    if (_fakeUpdate) {
      updateAvailable.value = true;
      return;
    }
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
    if (_fakeUpdate) {
      return UpdateCheckOutcome.updateStarted;
    }
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

import 'update_service.dart';

/// Orquestra o aviso "há versão nova" ao abrir o jogo. Fica fora da tela para
/// as regras serem testáveis sem plugin de anúncio nem de áudio.
///
/// Regras:
/// - só avisa se a checagem de inicialização achou versão nova;
/// - no máximo UMA vez por sessão (voltar à home não repete);
/// - espera qualquer diálogo já aberto (sugestão de idioma) sair da frente, em
///   vez de empilhar dois avisos, e desiste se a tela foi embora ou o diálogo
///   não sai.
class UpdatePromptCoordinator {
  UpdatePromptCoordinator({
    required this.isMounted,
    required this.isTopRoute,
    required this.show,
    UpdateService? updates,
    this.retryDelay = const Duration(milliseconds: 500),
    this.maxRetries = 12,
  }) : _updates = updates ?? UpdateService.instance;

  final bool Function() isMounted;
  final bool Function() isTopRoute;
  final Future<void> Function() show;
  final Duration retryDelay;
  final int maxRetries;
  final UpdateService _updates;

  /// `true` quando o aviso foi exibido.
  Future<bool> run() async {
    await _updates.startupCheck;
    if (!isMounted() ||
        !_updates.updateAvailable.value ||
        _updates.promptedThisSession) {
      return false;
    }
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      if (!isMounted()) {
        return false;
      }
      if (isTopRoute()) {
        break;
      }
      await Future<void>.delayed(retryDelay);
    }
    if (!isMounted() || !isTopRoute()) {
      return false;
    }
    _updates.promptedThisSession = true;
    await show();
    return true;
  }
}

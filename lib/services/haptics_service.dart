import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'storage_service.dart';

/// Tipo de resposta tátil, do mais leve ao mais forte.
enum HapticCue {
  /// Toque em botão, seleção de opção.
  tap,

  /// Peça colocada no tabuleiro.
  place,

  /// Mini-tabuleiro conquistado, evento do Caos, conquista desbloqueada.
  capture,

  /// Vitória: dois pulsos fortes.
  win,

  /// Derrota: um pulso médio, seco.
  lose,

  /// Subiu de nível: pulso forte seguido de um leve.
  levelUp,
}

/// Vibração de resposta, centralizada para respeitar a preferência do jogador
/// e para os testes conseguirem observar o que foi pedido sem plugin.
///
/// Usa só `HapticFeedback` do Flutter (não precisa da permissão VIBRATE nem
/// entra na declaração de Data safety: nada sai do aparelho).
class HapticsService {
  HapticsService._() : _sink = _platformSink;

  /// Instância isolada para teste: o [sink] recebe cada pedido em vez de
  /// vibrar. O padrão é ligado, como no app.
  @visibleForTesting
  HapticsService.forTest({
    required Future<void> Function(HapticCue cue) sink,
    bool enabled = true,
  })  : _sink = sink,
        _enabled = ValueNotifier<bool>(enabled);

  static final HapticsService instance = HapticsService._();

  final Future<void> Function(HapticCue cue) _sink;
  ValueNotifier<bool> _enabled = ValueNotifier<bool>(true);

  ValueListenable<bool> get isEnabledListenable => _enabled;
  bool get isEnabled => _enabled.value;

  /// Aplica a preferência persistida (chamado no startup).
  void applyStoredSettings({required bool enabled}) {
    _enabled.value = enabled;
  }

  void setEnabled(bool value) {
    _enabled.value = value;
    StorageService.instance.saveHapticsEnabled(value);
  }

  /// Dispara a resposta tátil. Nunca lança: aparelho sem motor de vibração ou
  /// plataforma sem suporte (web) simplesmente não vibra.
  void play(HapticCue cue) {
    if (!_enabled.value) {
      return;
    }
    unawaited(_sink(cue).catchError((Object _) {}));
  }

  static Future<void> _platformSink(HapticCue cue) async {
    if (kIsWeb) {
      return;
    }
    switch (cue) {
      case HapticCue.tap:
        await HapticFeedback.selectionClick();
      case HapticCue.place:
        await HapticFeedback.lightImpact();
      case HapticCue.capture:
        await HapticFeedback.mediumImpact();
      case HapticCue.lose:
        await HapticFeedback.mediumImpact();
      case HapticCue.win:
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.heavyImpact();
      case HapticCue.levelUp:
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 90));
        await HapticFeedback.lightImpact();
        await Future<void>.delayed(const Duration(milliseconds: 90));
        await HapticFeedback.lightImpact();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../services/update_service.dart';

/// Aviso "há uma versão nova". Aparece ao abrir o jogo quando a Play informa
/// atualização disponível; "Atualizar" dispara o fluxo nativo (ou abre a loja)
/// e "Depois" só fecha, sem penalidade nem bloqueio.
Future<void> showUpdateAvailableDialog(
  BuildContext context,
  AppLocalizations localization, {
  Future<UpdateCheckOutcome> Function()? onUpdate,
}) {
  final Future<UpdateCheckOutcome> Function() update =
      onUpdate ?? UpdateService.instance.checkForUpdate;
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF241048),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.system_update_rounded,
            color: Colors.cyanAccent, size: 32),
        title: Text(localization.updateAvailableTitle,
            textAlign: TextAlign.center),
        content: Text(localization.updateAvailableBody,
            textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowAlignment: OverflowBarAlignment.center,
        actionsOverflowDirection: VerticalDirection.down,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              AudioService.instance.playUiClick();
              Navigator.of(dialogContext).pop();
            },
            child: Text(localization.updateLaterLabel),
          ),
          FilledButton(
            onPressed: () {
              AudioService.instance.playUiClick();
              HapticsService.instance.play(HapticCue.tap);
              Navigator.of(dialogContext).pop();
              update();
            },
            child: Text(localization.updateNowLabel),
          ),
        ],
      );
    },
  );
}

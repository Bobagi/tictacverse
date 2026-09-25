import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import '../../services/update_service.dart';
import 'modern_background.dart';

// (Badge do Material 3 usado para o indicador de nova versão.)

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key, required this.localization});

  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final AudioService audioService = AudioService.instance;
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  localization.settingsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    audioService.playUiClick();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              localization.audioLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: audioService.isMutedListenable,
              builder: (BuildContext context, bool isMuted, Widget? child) {
                return SwitchListTile.adaptive(
                  value: isMuted,
                  onChanged: (bool value) => audioService.setMuted(value),
                  activeThumbColor: Colors.cyanAccent,
                  title: Text(localization.muteLabel),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: audioService.isMutedListenable,
              builder: (BuildContext context, bool isMuted, Widget? child) {
                return ValueListenableBuilder<double>(
                  valueListenable: audioService.volumeListenable,
                  builder: (BuildContext context, double volume, Widget? _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          localization.volumeLabel,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        Slider(
                          value: volume,
                          onChanged: isMuted
                              ? null
                              : (double value) => audioService.setVolume(value),
                          min: 0,
                          max: 1,
                          divisions: 10,
                          activeColor: Colors.lightBlueAccent,
                          inactiveColor: Colors.white24,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: HapticsService.instance.isEnabledListenable,
              builder: (BuildContext context, bool enabled, Widget? child) {
                return SwitchListTile.adaptive(
                  value: enabled,
                  onChanged: (bool value) {
                    HapticsService.instance.setEnabled(value);
                    // Demonstra na hora o que o jogador acabou de ligar.
                    HapticsService.instance.play(HapticCue.capture);
                  },
                  activeThumbColor: Colors.cyanAccent,
                  title: Text(localization.hapticsLabel),
                  secondary: const Icon(Icons.vibration_rounded,
                      color: Colors.white70),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              localization.updatesLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _UpdateCheckButton(localization: localization),
          ],
        ),
      ),
    );
  }
}

class _UpdateCheckButton extends StatefulWidget {
  const _UpdateCheckButton({required this.localization});

  final AppLocalizations localization;

  @override
  State<_UpdateCheckButton> createState() => _UpdateCheckButtonState();
}

class _UpdateCheckButtonState extends State<_UpdateCheckButton> {
  bool _checking = false;

  /// Resultado da última checagem, mostrado INLINE abaixo do botão. Um
  /// SnackBar aqui usava o ScaffoldMessenger da tela de baixo e aparecia
  /// ATRÁS deste sheet (bug do backlog de 05/07).
  String? _message;
  bool _messageIsError = false;

  Future<void> _check() async {
    AudioService.instance.playUiClick();
    setState(() {
      _checking = true;
      _message = null;
    });
    final UpdateCheckOutcome outcome =
        await UpdateService.instance.checkForUpdate();
    if (!mounted) {
      return;
    }
    setState(() {
      _checking = false;
      _message = switch (outcome) {
        UpdateCheckOutcome.upToDate => widget.localization.upToDateMessage,
        UpdateCheckOutcome.failed => widget.localization.updateFailedMessage,
        _ => null,
      };
      _messageIsError = outcome == UpdateCheckOutcome.failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: UpdateService.instance.updateAvailable,
      builder: (BuildContext context, bool hasUpdate, Widget? _) {
        final String? message = _message;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildButton(hasUpdate),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              alignment: Alignment.topCenter,
              child: message == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _messageIsError
                                ? Icons.error_outline_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 18,
                            color: _messageIsError
                                ? VerseColors.danger
                                : Colors.greenAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButton(bool hasUpdate) {
    return FilledButton.tonalIcon(
      onPressed: _checking ? null : _check,
      icon: _checking
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Badge(
              isLabelVisible: hasUpdate,
              smallSize: 9,
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.system_update_rounded),
            ),
      label: Text(widget.localization.checkUpdatesLabel),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
      ),
    );
  }
}

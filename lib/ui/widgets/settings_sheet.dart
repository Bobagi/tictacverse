import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../services/audio_service.dart';
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
                  activeColor: Colors.cyanAccent,
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
                              : (double value) =>
                                  audioService.setVolume(value),
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

  Future<void> _check() async {
    setState(() {
      _checking = true;
    });
    final UpdateCheckOutcome outcome = await UpdateService.instance.checkForUpdate();
    if (!mounted) {
      return;
    }
    setState(() {
      _checking = false;
    });
    final String? message = switch (outcome) {
      UpdateCheckOutcome.upToDate => widget.localization.upToDateMessage,
      UpdateCheckOutcome.failed => widget.localization.updateFailedMessage,
      _ => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: UpdateService.instance.updateAvailable,
      builder: (BuildContext context, bool hasUpdate, Widget? _) {
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
      },
    );
  }
}

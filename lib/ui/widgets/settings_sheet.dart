import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../services/audio_service.dart';
import 'modern_background.dart';

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
          ],
        ),
      ),
    );
  }
}

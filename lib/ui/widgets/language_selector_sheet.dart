import 'package:flutter/material.dart';

import 'package:tictacverse/l10n/app_localizations.dart';
import '../../services/audio_service.dart';
import 'modern_background.dart';

class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({
    super.key,
    required this.localization,
    required this.selectedLocale,
    required this.onLocaleSelected,
  });

  final AppLocalizations localization;
  final Locale selectedLocale;
  final void Function(Locale locale) onLocaleSelected;

  @override
  Widget build(BuildContext context) {
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
                  localization.languageLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    AudioService.instance.playUiClick();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final (String code, String title, String flag)
                        in <(String, String, String)>[
                      ('en', localization.languageEnglish, '🇺🇸'),
                      ('pt', localization.languagePortuguese, '🇧🇷'),
                      ('es', localization.languageSpanish, '🇪🇸'),
                      ('hi', localization.languageHindi, '🇮🇳'),
                      ('bn', localization.languageBengali, '🇧🇩'),
                      ('ne', localization.languageNepali, '🇳🇵'),
                    ]) ...<Widget>[
                      _LanguageTile(
                        title: title,
                        locale: Locale(code),
                        isSelected: selectedLocale.languageCode == code,
                        onTap: () {
                          AudioService.instance.playUiClick();
                          onLocaleSelected(Locale(code));
                        },
                        leading:
                            Text(flag, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.locale,
    required this.isSelected,
    required this.onTap,
    required this.leading,
  });

  final String title;
  final Locale locale;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white24),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Row(
          children: <Widget>[
            leading,
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.cyanAccent,
              ),
          ],
        ),
      ),
    );
  }
}

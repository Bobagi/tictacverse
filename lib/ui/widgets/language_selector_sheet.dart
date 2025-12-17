import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    return Padding(
      padding: const EdgeInsets.all(16),
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(localization.languageLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _LanguageTile(
              title: localization.languageEnglish,
              locale: const Locale('en'),
              isSelected: selectedLocale.languageCode == 'en',
              onTap: () => onLocaleSelected(const Locale('en')),
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 8),
            _LanguageTile(
              title: localization.languagePortuguese,
              locale: const Locale('pt'),
              isSelected: selectedLocale.languageCode == 'pt',
              onTap: () => onLocaleSelected(const Locale('pt')),
              leading: const Text('🇧🇷', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 8),
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

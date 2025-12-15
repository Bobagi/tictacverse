import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';

class GameOverModal extends StatelessWidget {
  const GameOverModal({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPlayAgain,
    required this.onBackToMenu,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToMenu;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(onPressed: onPlayAgain, child: Text(localization.playAgain)),
              TextButton(onPressed: onBackToMenu, child: Text(localization.backToMenu)),
            ],
          ),
        ],
      ),
    );
  }
}

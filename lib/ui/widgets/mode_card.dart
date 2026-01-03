import 'package:flutter/material.dart';

import '../../services/audio_service.dart';
import 'modern_background.dart';

class ModeCard extends StatelessWidget {
  const ModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onStart,
    required this.buttonLabel,
  });

  final String title;
  final String subtitle;
  final VoidCallback onStart;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                AudioService.instance.playUiClick();
                onStart();
              },
              icon: const Icon(Icons.sports_esports_rounded),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                backgroundColor: const Color(0xFF1AD1FF),
                foregroundColor: const Color(0xFF041427),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

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
    this.accent = VerseColors.cross,
    this.icon = Icons.grid_3x3_rounded,
  });

  final String title;
  final String subtitle;
  final VoidCallback onStart;
  final String buttonLabel;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(18);
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: () {
          AudioService.instance.playUiClick();
          onStart();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              colors: <Color>[
                accent.withOpacity(0.14),
                VerseColors.surfaceDeep.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: accent.withOpacity(0.55), width: 1.4),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withOpacity(0.5)),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: VerseColors.mutedText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: accent.withOpacity(0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.play_arrow_rounded,
                        color: Color(0xFF160B29), size: 20),
                    const SizedBox(width: 2),
                    Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF160B29),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

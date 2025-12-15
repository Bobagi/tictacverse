import 'package:flutter/material.dart';

class ModeCard extends StatelessWidget {
  const ModeCard({super.key, required this.title, required this.subtitle, required this.onStart});

  final String title;
  final String subtitle;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
            ElevatedButton(onPressed: onStart, child: const Text('▶')),
          ],
        ),
      ),
    );
  }
}

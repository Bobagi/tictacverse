import 'package:flutter/material.dart';

import 'modern_background.dart';

/// Saldo de moedas em pílula. Com [onTap], vira botão (atalho para a loja).
class CoinBadge extends StatelessWidget {
  const CoinBadge(
      {super.key, required this.coins, this.onTap, this.semanticLabel});

  final int coins;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget pill = Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      decoration: BoxDecoration(
        color: VerseColors.coin.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VerseColors.coin.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.monetization_on_rounded,
              color: VerseColors.coin, size: 22),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
    if (onTap == null) {
      return Semantics(label: semanticLabel, child: pill);
    }
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          // Alvo de toque de 48px mesmo com a pílula mais baixa.
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: pill,
        ),
      ),
    );
  }
}

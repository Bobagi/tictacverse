import 'package:flutter/material.dart';

/// Entrada com escala + fade (overshoot de easeOutBack) — usada nas marcas
/// recém-colocadas no tabuleiro. Anima uma vez ao montar; com
/// `MediaQuery.disableAnimations` renderiza direto.
///
/// [beginScale] < 1 cresce até o lugar (peça entrando); > 1 desce como um
/// carimbo (dono do mini-tabuleiro no Ultimate).
class PopIn extends StatelessWidget {
  const PopIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 240),
    this.beginScale = 0.35,
  });

  final Widget child;
  final Duration duration;
  final double beginScale;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: (value * 1.8).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: beginScale + (1 - beginScale) * value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

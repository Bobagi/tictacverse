import 'package:flutter/material.dart';

/// Número que "sobe" até o valor final, chamando [onTick] a cada incremento
/// exibido (a tela usa isso para o tique sonoro do contador de XP).
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.onTick,
    this.textAlign,
    this.animateFirst = true,
  });

  final int value;
  final String Function(int value) format;
  final TextStyle? style;
  final Duration duration;
  final VoidCallback? onTick;
  final TextAlign? textAlign;

  /// `false` = aparece já no valor e só anima as MUDANÇAS (saldo no topo).
  final bool animateFirst;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> {
  late int _from = widget.animateFirst ? 0 : widget.value;
  late int _lastShown = _from;

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      // Continua de onde parou em vez de recomeçar do zero.
      _from = _lastShown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _lastShown = widget.value;
      return Text(widget.format(widget.value),
          style: widget.style, textAlign: widget.textAlign);
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(widget.value),
      tween:
          Tween<double>(begin: _from.toDouble(), end: widget.value.toDouble()),
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animated, Widget? _) {
        final int shown = animated.round();
        if (shown != _lastShown) {
          _lastShown = shown;
          widget.onTick?.call();
        }
        return Text(widget.format(shown),
            style: widget.style, textAlign: widget.textAlign);
      },
    );
  }
}

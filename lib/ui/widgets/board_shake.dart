import 'dart:math';

import 'package:flutter/material.dart';

/// Tremida de impacto com decaimento (usada quando alguém fecha uma linha).
/// Dispara sempre que [trigger] muda para um valor > 0; respeita
/// `MediaQuery.disableAnimations`.
class BoardShake extends StatefulWidget {
  const BoardShake({
    super.key,
    required this.trigger,
    required this.child,
  });

  /// Contador de disparos — incremente para tremer de novo.
  final int trigger;
  final Widget child;

  @override
  State<BoardShake> createState() => _BoardShakeState();
}

class _BoardShakeState extends State<BoardShake>
    with SingleTickerProviderStateMixin {
  static const double _amplitude = 7;
  static const double _oscillations = 5;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  @override
  void didUpdateWidget(BoardShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      final bool reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion) {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        if (t == 0 || t == 1) {
          return child!;
        }
        final double decay = (1 - t) * (1 - t);
        final double wave = sin(t * _oscillations * 2 * pi);
        final double dx = wave * _amplitude * decay;
        final double dy =
            sin(t * _oscillations * 2 * pi + pi / 3) * _amplitude * 0.35 * decay;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: wave * 0.006 * decay,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

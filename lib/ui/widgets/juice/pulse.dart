import 'package:flutter/material.dart';

/// Pulsação contínua de escala (e opcionalmente de brilho) - chama atenção
/// para o que importa agora: a vez do jogador, a sequência de vitórias.
class Pulse extends StatefulWidget {
  const Pulse({
    super.key,
    required this.child,
    this.active = true,
    this.minScale = 1.0,
    this.maxScale = 1.06,
    this.period = const Duration(milliseconds: 900),
  });

  final Widget child;
  final bool active;
  final double minScale;
  final double maxScale;
  final Duration period;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(Pulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _sync();
    }
  }

  void _sync() {
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.animateTo(0, duration: const Duration(milliseconds: 160));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeInOut.transform(_controller.value);
        return Transform.scale(
          scale: widget.minScale + (widget.maxScale - widget.minScale) * t,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

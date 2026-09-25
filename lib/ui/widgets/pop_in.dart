import 'package:flutter/material.dart';

/// Entrada com escala + fade (overshoot de easeOutBack) - usada nas marcas
/// recém-colocadas no tabuleiro e nos chips de recompensa. Anima uma vez ao
/// montar; com `MediaQuery.disableAnimations` renderiza direto.
///
/// [beginScale] < 1 cresce até o lugar (peça entrando); > 1 desce como um
/// carimbo (dono do mini-tabuleiro no Ultimate). [delay] segura o início,
/// para escalonar uma lista de chips (fica invisível até começar).
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 240),
    this.beginScale = 0.35,
    this.delay = Duration.zero,
    this.onStart,
  });

  final Widget child;
  final Duration duration;
  final double beginScale;
  final Duration delay;

  /// Chamado quando a animação de fato começa (depois do [delay]) - a tela usa
  /// para sincronizar um som com o chip aparecendo.
  final VoidCallback? onStart;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _start();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) {
          _start();
        }
      });
    }
  }

  void _start() {
    _started = true;
    widget.onStart?.call();
    _controller.forward();
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
        if (!_started) {
          return Opacity(opacity: 0, child: child);
        }
        final double value = Curves.easeOutBack.transform(_controller.value);
        return Opacity(
          opacity: (_controller.value * 1.8).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: widget.beginScale + (1 - widget.beginScale) * value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';

/// Efeitos contínuos de "juice" para chamar o olho sem pedir toque.
///
/// Regras de todos eles (as mesmas do resto da pasta):
/// - mesma forma de árvore parado e animando (só os valores mudam), senão o
///   filho remonta no meio da animação;
/// - com "reduzir animações" do sistema, viram o filho parado;
/// - um `AnimationController` próprio, descartado no `dispose`.
bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

mixin _LoopController<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController loop =
      AnimationController(vsync: this, duration: period);

  Duration get period;

  /// Se o efeito deve estar rodando agora (o Wobble desligado diz que não).
  bool get wantsToRun => true;

  /// Com "reduzir animações" o efeito fica parado de verdade: sem relógio
  /// rodando à toa (o teste pegou o controlador vivo depois do dispose).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncLoop();
  }

  void syncLoop() {
    if (wantsToRun && !_reduceMotion(context)) {
      if (!loop.isAnimating) {
        loop.repeat();
      }
    } else {
      loop.stop();
      loop.value = 0;
    }
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }
}

/// Balancinho: gira o filho de um lado para o outro em volta do centro (ou
/// de [alignment]), como presente que quer ser aberto.
class Wobble extends StatefulWidget {
  const Wobble({
    super.key,
    required this.child,
    this.angle = 0.12,
    this.period = const Duration(milliseconds: 1400),
    this.alignment = Alignment.center,
    this.active = true,
  });

  final Widget child;

  /// Parado = sem custo de quadro (o controlador para), mesma árvore.
  final bool active;

  /// Inclinação máxima em radianos para cada lado.
  final double angle;
  final Duration period;
  final Alignment alignment;

  @override
  State<Wobble> createState() => _WobbleState();
}

class _WobbleState extends State<Wobble>
    with SingleTickerProviderStateMixin, _LoopController<Wobble> {
  @override
  Duration get period => widget.period;

  @override
  bool get wantsToRun => widget.active;

  @override
  void didUpdateWidget(Wobble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      syncLoop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: loop,
      builder: (BuildContext context, Widget? child) => Transform.rotate(
        alignment: widget.alignment,
        angle: sin(loop.value * 2 * pi) * widget.angle,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Respiração: o filho cresce e volta bem devagar, como quem respira. É o
/// movimento de fundo dos ícones das telas (home, modos, cabeçalhos): a tela
/// nunca fica parada, mas nada pisca nem pede toque. [phase] (0 a 1)
/// desencontra ícones vizinhos para não respirarem em coro.
class Breathe extends StatefulWidget {
  const Breathe({
    super.key,
    required this.child,
    this.amount = 0.07,
    this.period = const Duration(milliseconds: 2800),
    this.phase = 0,
  });

  final Widget child;

  /// Quanto cresce no pico (0,07 = 7%).
  final double amount;
  final Duration period;
  final double phase;

  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe>
    with SingleTickerProviderStateMixin, _LoopController<Breathe> {
  @override
  Duration get period => widget.period;

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: loop,
      builder: (BuildContext context, Widget? child) {
        final double t = (loop.value + widget.phase) % 1;
        // Cosseno: entra e sai devagar nos extremos, sem tranco.
        final double inhale = 0.5 - 0.5 * cos(t * 2 * pi);
        return Transform.scale(
          scale: 1 + widget.amount * inhale,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Flutua para cima e para baixo. [phase] (0 a 1) desencontra vários juntos.
class Bob extends StatefulWidget {
  const Bob({
    super.key,
    required this.child,
    this.distance = 6,
    this.period = const Duration(milliseconds: 1800),
    this.phase = 0,
  });

  final Widget child;
  final double distance;
  final Duration period;
  final double phase;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob>
    with SingleTickerProviderStateMixin, _LoopController<Bob> {
  @override
  Duration get period => widget.period;

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: loop,
      builder: (BuildContext context, Widget? child) => Transform.translate(
        offset: Offset(
            0, sin((loop.value + widget.phase) * 2 * pi) * widget.distance),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Faixa de brilho que atravessa o filho em diagonal de tempos em tempos,
/// como reflexo em cartão premium. Não pega toque.
class Shine extends StatefulWidget {
  const Shine({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.period = const Duration(milliseconds: 2600),
    this.opacity = 0.35,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Ciclo inteiro: a passagem ocupa o primeiro terço, o resto é pausa.
  final Duration period;
  final double opacity;

  @override
  State<Shine> createState() => _ShineState();
}

class _ShineState extends State<Shine>
    with SingleTickerProviderStateMixin, _LoopController<Shine> {
  @override
  Duration get period => widget.period;

  @override
  Widget build(BuildContext context) {
    final bool still = _reduceMotion(context);
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: AnimatedBuilder(
                animation: loop,
                builder: (BuildContext context, _) => CustomPaint(
                  painter: _ShinePainter(
                    // Parado: faixa fora do cartão (nada aparece).
                    progress: still ? -1 : (loop.value * 3).clamp(0.0, 1.0),
                    opacity: widget.opacity,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShinePainter extends CustomPainter {
  _ShinePainter({required this.progress, required this.opacity});

  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) {
      return;
    }
    final double band = size.width * 0.35;
    final double x = -band + (size.width + 2 * band) * progress;
    final Rect rect = Rect.fromLTWH(x - band / 2, 0, band, size.height);
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.white.withOpacity(0),
          Colors.white.withOpacity(opacity),
          Colors.white.withOpacity(0),
        ],
      ).createShader(rect);
    canvas.save();
    // Inclina a faixa (diagonal).
    canvas.translate(size.width / 2, size.height / 2);
    canvas.skew(-0.4, 0);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRect(rect.inflate(size.height), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShinePainter old) =>
      old.progress != progress || old.opacity != opacity;
}

/// Raios de luz girando atrás de um prêmio (o "brilho de baú aberto").
class Sunburst extends StatefulWidget {
  const Sunburst({
    super.key,
    required this.size,
    this.color = const Color(0xFFFFD21A),
    this.rays = 12,
    this.period = const Duration(seconds: 9),
  });

  final double size;
  final Color color;
  final int rays;
  final Duration period;

  @override
  State<Sunburst> createState() => _SunburstState();
}

class _SunburstState extends State<Sunburst>
    with SingleTickerProviderStateMixin, _LoopController<Sunburst> {
  @override
  Duration get period => widget.period;

  @override
  Widget build(BuildContext context) {
    final bool still = _reduceMotion(context);
    return IgnorePointer(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: loop,
          builder: (BuildContext context, _) => CustomPaint(
            painter: _SunburstPainter(
              turn: still ? 0 : loop.value,
              color: widget.color,
              rays: widget.rays,
            ),
          ),
        ),
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  _SunburstPainter(
      {required this.turn, required this.color, required this.rays});

  final double turn;
  final Color color;
  final int rays;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2;
    final Paint glow = Paint()
      ..shader = RadialGradient(colors: <Color>[
        color.withOpacity(0.45),
        color.withOpacity(0),
      ]).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, glow);
    final Paint ray = Paint()
      ..shader = RadialGradient(colors: <Color>[
        color.withOpacity(0.55),
        color.withOpacity(0),
      ]).createShader(Rect.fromCircle(center: c, radius: r));
    final double step = 2 * pi / rays;
    for (int i = 0; i < rays; i++) {
      final double a = turn * 2 * pi + i * step;
      final Path p = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(
            c.dx + cos(a - step * 0.18) * r, c.dy + sin(a - step * 0.18) * r)
        ..lineTo(
            c.dx + cos(a + step * 0.18) * r, c.dy + sin(a + step * 0.18) * r)
        ..close();
      canvas.drawPath(p, ray);
    }
  }

  @override
  bool shouldRepaint(_SunburstPainter old) =>
      old.turn != turn || old.color != color || old.rays != rays;
}

/// "Pulinho" de escala quando [value] muda (saldo de moedas, contador): o
/// número que acabou de mudar chama a atenção. Mesma árvore sempre.
class BumpOnChange extends StatefulWidget {
  const BumpOnChange({
    super.key,
    required this.value,
    required this.child,
    this.scale = 1.25,
  });

  final Object value;
  final Widget child;
  final double scale;

  @override
  State<BumpOnChange> createState() => _BumpOnChangeState();
}

class _BumpOnChangeState extends State<BumpOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );

  @override
  void didUpdateWidget(BumpOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_reduceMotion(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        // Sobe rápido e volta com um quique (elasticOut).
        final double t = _c.value;
        final double s = t >= 1
            ? 1
            : 1 + (widget.scale - 1) * (1 - Curves.elasticOut.transform(t));
        return Transform.scale(scale: s, child: child);
      },
      child: widget.child,
    );
  }
}

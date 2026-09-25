import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Forma de uma partícula.
enum ParticleShape { circle, square, strip }

class Particle {
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.life,
    required this.shape,
    this.rotation = 0,
    this.spin = 0,
    this.gravity = 0,
    this.drag = 0.0,
  }) : maxLife = life;

  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  double life;
  final double maxLife;
  final ParticleShape shape;
  double rotation;
  final double spin;
  final double gravity;
  final double drag;

  double get progress => 1 - (life / maxLife).clamp(0.0, 1.0);
}

/// Dono das partículas. A tela cria um e o entrega ao [ParticleField]; depois
/// dispara [burst] e [confetti] de qualquer lugar. Sem partícula viva não há
/// ticker rodando, então o custo em repouso é zero.
class ParticleController extends ChangeNotifier {
  ParticleController({Random? random}) : _random = random ?? Random();

  final Random _random;
  final List<Particle> _particles = <Particle>[];
  bool _enabled = true;

  /// Tamanho do campo em pixels, informado pelo [ParticleField] a cada layout.
  Size viewport = const Size(320, 320);

  List<Particle> get particles => List<Particle>.unmodifiable(_particles);
  bool get hasParticles => _particles.isNotEmpty;

  /// Desligado sob `MediaQuery.disableAnimations`: as emissões viram no-op.
  set enabled(bool value) => _enabled = value;

  /// Explosão radial curta (peça colocada, mini-tabuleiro conquistado).
  void burst({
    required Offset center,
    required Color color,
    int count = 14,
    double speed = 1.0,
    double size = 4,
    Color? accent,
  }) {
    if (!_enabled) {
      return;
    }
    for (int i = 0; i < count; i++) {
      final double angle = _random.nextDouble() * 2 * pi;
      final double magnitude = (60 + _random.nextDouble() * 140) * speed;
      _particles.add(Particle(
        position: center,
        velocity: Offset(cos(angle), sin(angle)) * magnitude,
        color: (accent != null && _random.nextBool()) ? accent : color,
        size: size * (0.6 + _random.nextDouble() * 0.9),
        life: 0.35 + _random.nextDouble() * 0.35,
        shape: _random.nextInt(3) == 0
            ? ParticleShape.square
            : ParticleShape.circle,
        rotation: _random.nextDouble() * pi,
        spin: (_random.nextDouble() - 0.5) * 10,
        drag: 3.5,
      ));
    }
    notifyListeners();
  }

  /// Chuva de confete: dois canhões nos cantos de baixo atirando para cima e
  /// para dentro, com gravidade, giro e tiras coloridas. Use na vitória.
  void confetti({
    required List<Color> colors,
    int count = 90,
  }) {
    if (!_enabled || colors.isEmpty) {
      return;
    }
    final Size size = viewport;
    for (int i = 0; i < count; i++) {
      final bool fromLeft = i.isEven;
      final Offset origin = Offset(
        fromLeft ? size.width * 0.08 : size.width * 0.92,
        size.height * 0.95,
      );
      // Ângulo: para cima e inclinado para o centro.
      final double base = fromLeft ? -pi / 2 + 0.55 : -pi / 2 - 0.55;
      final double angle = base + (_random.nextDouble() - 0.5) * 0.9;
      final double magnitude = size.height * (0.9 + _random.nextDouble() * 0.9);
      final int shapeRoll = _random.nextInt(3);
      _particles.add(Particle(
        position: origin,
        velocity: Offset(cos(angle), sin(angle)) * magnitude,
        color: colors[_random.nextInt(colors.length)],
        size: 5 + _random.nextDouble() * 6,
        life: 1.6 + _random.nextDouble() * 1.0,
        shape: shapeRoll == 0
            ? ParticleShape.circle
            : (shapeRoll == 1 ? ParticleShape.square : ParticleShape.strip),
        rotation: _random.nextDouble() * pi,
        spin: (_random.nextDouble() - 0.5) * 14,
        gravity: size.height * 1.4,
        drag: 1.1,
      ));
    }
    notifyListeners();
  }

  /// Faíscas subindo de uma faixa horizontal (barra de XP, subida de nível).
  void sparkle({
    required Rect area,
    required Color color,
    int count = 18,
  }) {
    if (!_enabled) {
      return;
    }
    for (int i = 0; i < count; i++) {
      final Offset origin = Offset(
        area.left + _random.nextDouble() * area.width,
        area.top + _random.nextDouble() * area.height,
      );
      _particles.add(Particle(
        position: origin,
        velocity: Offset(
            (_random.nextDouble() - 0.5) * 40, -40 - _random.nextDouble() * 90),
        color: _random.nextInt(4) == 0 ? Colors.white : color,
        size: 2 + _random.nextDouble() * 3,
        life: 0.5 + _random.nextDouble() * 0.5,
        shape: ParticleShape.circle,
        drag: 1.5,
      ));
    }
    notifyListeners();
  }

  /// Avança a simulação em [dt] segundos. Chamado pelo ticker do campo.
  void step(double dt) {
    if (_particles.isEmpty) {
      return;
    }
    final double floor = viewport.height + 40;
    _particles.removeWhere((Particle p) {
      p.life -= dt;
      if (p.life <= 0 || p.position.dy > floor) {
        return true;
      }
      p.velocity = Offset(
        p.velocity.dx * (1 - p.drag * dt).clamp(0.0, 1.0),
        (p.velocity.dy + p.gravity * dt) *
            (1 - p.drag * dt * 0.5).clamp(0.0, 1.0),
      );
      p.position += p.velocity * dt;
      p.rotation += p.spin * dt;
      return false;
    });
    notifyListeners();
  }

  void clear() {
    _particles.clear();
    notifyListeners();
  }
}

/// Camada transparente que desenha as partículas de um [ParticleController].
/// Coloque em `Positioned.fill` (num Stack) por cima do conteúdo; ela ignora
/// toques. O ticker só roda enquanto houver partícula viva.
class ParticleField extends StatefulWidget {
  const ParticleField({super.key, required this.controller});

  final ParticleController controller;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(ParticleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _ticker.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.hasParticles) {
      if (!_ticker.isActive) {
        _lastElapsed = Duration.zero;
        _ticker.start();
      }
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onTick(Duration elapsed) {
    final double dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    widget.controller.step(dt);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    widget.controller.enabled = !reduceMotion;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.biggest.isFinite && !constraints.biggest.isEmpty) {
            widget.controller.viewport = constraints.biggest;
          }
          return CustomPaint(
            painter: _ParticlePainter(widget.controller.particles),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles);

  final List<Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (final Particle p in particles) {
      final double fade = p.progress < 0.7 ? 1 : (1 - p.progress) / 0.3;
      paint.color = p.color.withOpacity(fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);
      switch (p.shape) {
        case ParticleShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
        case ParticleShape.square:
          canvas.drawRect(
              Rect.fromCenter(
                  center: Offset.zero, width: p.size, height: p.size),
              paint);
        case ParticleShape.strip:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset.zero,
                  width: p.size * 0.5,
                  height: p.size * 1.8),
              const Radius.circular(1),
            ),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

import 'dart:math';

import 'package:flutter/material.dart';

/// Linha vencedora desenhada progressivamente com glow neon e partículas
/// saindo da ponta enquanto é revelada. Anima uma vez ao ser montada —
/// use uma Key derivada da linha para reanimar em vitórias novas.
class NeonWinLine extends StatefulWidget {
  const NeonWinLine({
    super.key,
    required this.winningLine,
    required this.color,
  });

  final List<int> winningLine;
  final Color color;

  @override
  State<NeonWinLine> createState() => _NeonWinLineState();
}

class _Particle {
  _Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.bornAt,
    required this.lifespan,
    required this.color,
  });

  Offset position;
  final Offset velocity;
  final double size;
  final double bornAt;
  final double lifespan;
  final Color color;
}

class _NeonWinLineState extends State<NeonWinLine>
    with SingleTickerProviderStateMixin {
  static const double _drawPhase = 0.45; // fração do tempo desenhando a linha

  late final AnimationController _controller;
  final List<_Particle> _particles = <_Particle>[];
  final Random _random = Random();
  double _lastSpawnT = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..addListener(_onTick);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _lineProgress => (_controller.value / _drawPhase).clamp(0.0, 1.0);

  void _onTick() {
    final double t = _controller.value;
    // Partículas nascem na ponta enquanto a linha é desenhada.
    if (t <= _drawPhase && t - _lastSpawnT > 0.012) {
      _lastSpawnT = t;
      final int burst = 2 + _random.nextInt(2);
      for (int i = 0; i < burst; i++) {
        final double angle = _random.nextDouble() * 2 * pi;
        final double speed = 18 + _random.nextDouble() * 70;
        _particles.add(_Particle(
          position: Offset.zero, // resolvida no painter (relativa à ponta)
          velocity: Offset(cos(angle), sin(angle)) * speed,
          size: 1.6 + _random.nextDouble() * 3.2,
          bornAt: t,
          lifespan: 0.18 + _random.nextDouble() * 0.30,
          color: _random.nextBool() ? widget.color : Colors.white,
        ));
      }
    }
    _particles.removeWhere(
        (_Particle p) => t - p.bornAt > p.lifespan || p.bornAt > t);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NeonWinLinePainter(
        winningLine: widget.winningLine,
        color: widget.color,
        lineProgress: _lineProgress,
        time: _controller.value,
        particles: _particles,
      ),
    );
  }
}

class _NeonWinLinePainter extends CustomPainter {
  _NeonWinLinePainter({
    required this.winningLine,
    required this.color,
    required this.lineProgress,
    required this.time,
    required this.particles,
  });

  final List<int> winningLine;
  final Color color;
  final double lineProgress;
  final double time;
  final List<_Particle> particles;

  Offset _cellCenter(int index, Size size) {
    final double cw = size.width / 3;
    final double ch = size.height / 3;
    return Offset((index % 3 + 0.5) * cw, (index ~/ 3 + 0.5) * ch);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (winningLine.length < 2 || lineProgress <= 0) {
      return;
    }
    final Offset start = _cellCenter(winningLine.first, size);
    final Offset end = _cellCenter(winningLine.last, size);
    // estica um pouco além dos centros das pontas
    final Offset dir = (end - start) / (end - start).distance;
    final double overshoot = size.shortestSide * 0.06;
    final Offset a = start - dir * overshoot;
    final Offset b = end + dir * overshoot;
    final Offset tip = Offset.lerp(a, b, lineProgress)!;

    // camadas de glow: larga e difusa → núcleo brilhante
    final Paint outerGlow = Paint()
      ..color = color.withOpacity(0.30)
      ..strokeWidth = size.shortestSide * 0.085
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final Paint innerGlow = Paint()
      ..color = color.withOpacity(0.75)
      ..strokeWidth = size.shortestSide * 0.038
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final Paint core = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..strokeWidth = size.shortestSide * 0.014
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(a, tip, outerGlow);
    canvas.drawLine(a, tip, innerGlow);
    canvas.drawLine(a, tip, core);

    // brilho na ponta enquanto desenha
    if (lineProgress < 1) {
      canvas.drawCircle(
        tip,
        size.shortestSide * 0.028,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // partículas (posição = ponta na hora do nascimento + deslocamento)
    for (final _Particle p in particles) {
      final double age = (time - p.bornAt).clamp(0.0, p.lifespan);
      final double lifeT = age / p.lifespan;
      final double birthProgress =
          ((p.bornAt / 0.45).clamp(0.0, 1.0)).toDouble();
      final Offset birthTip = Offset.lerp(a, b, birthProgress)!;
      final Offset pos = birthTip + p.velocity * age * 3.2;
      canvas.drawCircle(
        pos,
        p.size * (1 - lifeT),
        Paint()
          ..color = p.color.withOpacity((1 - lifeT) * 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(_NeonWinLinePainter oldDelegate) => true;
}

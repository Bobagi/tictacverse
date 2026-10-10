import 'dart:math';

import 'package:flutter/material.dart';

/// Linha da vitória: risco dourado e laranja, grosso, desenhado de ponta a
/// ponta com faíscas saindo da ponta; quando fecha, um clarão, faíscas ao
/// longo de toda a linha e anéis nas pontas, e depois o brilho pulsa com um
/// reflexo correndo por ela. Anima uma vez ao ser montada - use uma Key
/// derivada da linha para reanimar em vitórias novas.
///
/// Por que dourado: o tabuleiro é todo neon ciano, rosa e roxo, e a linha na
/// cor do vencedor se misturava com a grade (queixa do dono, 2026-10-09). O
/// amarelo e o laranja não aparecem em mais nada do tabuleiro.
class NeonWinLine extends StatefulWidget {
  const NeonWinLine({
    super.key,
    required this.winningLine,
    required this.color,
    this.dimension = 3,
  });

  /// Casas da linha em ordem: a primeira e a última são as pontas do risco.
  final List<int> winningLine;

  /// Cor de quem venceu: entra só como faísca de destaque, a linha é dourada.
  final Color color;

  /// Casas por lado do tabuleiro (3 no clássico, 4 no 4x4, 10 no Gomoku).
  final int dimension;

  static const Color gold = Color(0xFFFFD21A);
  static const Color orange = Color(0xFFFF8A00);
  static const Color hotCore = Color(0xFFFFF6CC);

  static const Duration duration = Duration(milliseconds: 2400);

  /// Fração do tempo gasta desenhando o risco.
  static const double drawPhase = 0.36;

  /// Quando o risco fecha: a tela usa isto para a tremida forte e a vibração
  /// caírem junto com o clarão.
  static Duration get impactDelay =>
      Duration(milliseconds: (duration.inMilliseconds * drawPhase).round());

  @override
  State<NeonWinLine> createState() => _NeonWinLineState();
}

class _Spark {
  _Spark({
    required this.along,
    required this.offset,
    required this.velocity,
    required this.size,
    required this.bornAt,
    required this.lifespan,
    required this.color,
  });

  /// Onde nasceu ao longo da linha (0 = início, 1 = fim).
  final double along;

  /// Deslocamento inicial perpendicular, em fração da espessura.
  final double offset;
  final Offset velocity;
  final double size;
  final double bornAt;
  final double lifespan;
  final Color color;
}

class _NeonWinLineState extends State<NeonWinLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Spark> _sparks = <_Spark>[];
  final Random _random = Random();
  double _lastSpawnT = 0;
  bool _impactDone = false;
  bool _still = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: NeonWinLine.duration,
    )..addListener(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_still) {
      // Reduzir animações: a linha já aparece inteira, sem faísca nem pulso.
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _sparkColor() {
    switch (_random.nextInt(5)) {
      case 0:
        return Colors.white;
      case 1:
        return widget.color;
      case 2:
        return NeonWinLine.orange;
      default:
        return NeonWinLine.gold;
    }
  }

  void _onTick() {
    if (_still) {
      return;
    }
    final double t = _controller.value;
    const double draw = NeonWinLine.drawPhase;
    // Faíscas na ponta enquanto o risco é desenhado.
    if (t <= draw && t - _lastSpawnT > 0.01) {
      _lastSpawnT = t;
      final double along = (t / draw).clamp(0.0, 1.0);
      for (int i = 0; i < 3; i++) {
        final double angle = _random.nextDouble() * 2 * pi;
        _sparks.add(_Spark(
          along: along,
          offset: 0,
          velocity:
              Offset(cos(angle), sin(angle)) * (20 + _random.nextDouble() * 80),
          size: 1.8 + _random.nextDouble() * 3.4,
          bornAt: t,
          lifespan: 0.14 + _random.nextDouble() * 0.22,
          color: _sparkColor(),
        ));
      }
    }
    // Impacto: chuva de faíscas ao longo da linha inteira.
    if (!_impactDone && t >= draw) {
      _impactDone = true;
      for (int i = 0; i < 70; i++) {
        final double angle = _random.nextDouble() * 2 * pi;
        _sparks.add(_Spark(
          along: _random.nextDouble(),
          offset: (_random.nextDouble() - 0.5) * 0.06,
          velocity: Offset(cos(angle), sin(angle)) *
              (40 + _random.nextDouble() * 150),
          size: 2 + _random.nextDouble() * 4.5,
          bornAt: t,
          lifespan: 0.2 + _random.nextDouble() * 0.35,
          color: _sparkColor(),
        ));
      }
    }
    _sparks
        .removeWhere((_Spark p) => t - p.bornAt > p.lifespan || p.bornAt > t);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NeonWinLinePainter(
        winningLine: widget.winningLine,
        dimension: widget.dimension,
        time: _controller.value,
        sparks: _sparks,
        still: _still,
      ),
    );
  }
}

class _NeonWinLinePainter extends CustomPainter {
  _NeonWinLinePainter({
    required this.winningLine,
    required this.dimension,
    required this.time,
    required this.sparks,
    required this.still,
  });

  final List<int> winningLine;
  final int dimension;
  final double time;
  final List<_Spark> sparks;
  final bool still;

  Offset _cellCenter(int index, Size size) {
    final double cw = size.width / dimension;
    final double ch = size.height / dimension;
    return Offset(
        (index % dimension + 0.5) * cw, (index ~/ dimension + 0.5) * ch);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double draw = NeonWinLine.drawPhase;
    final double progress = (time / draw).clamp(0.0, 1.0);
    if (winningLine.length < 2 || progress <= 0) {
      return;
    }
    final Offset start = _cellCenter(winningLine.first, size);
    final Offset end = _cellCenter(winningLine.last, size);
    final Offset dir = (end - start) / (end - start).distance;
    final Offset normal = Offset(-dir.dy, dir.dx);
    // Espessura e sobra acompanham a casa: no 10x10 o risco não pode cobrir
    // três fileiras.
    final double cellScale = 3 / dimension;
    final double thickness = size.shortestSide * sqrt(cellScale);
    final double overshoot = size.shortestSide * 0.07 * cellScale;
    final Offset a = start - dir * overshoot;
    final Offset b = end + dir * overshoot;
    final Offset tip = Offset.lerp(a, b, progress)!;

    // Depois de fechar: o brilho respira e um reflexo corre pela linha.
    final double after = time <= draw ? 0 : (time - draw) / (1 - draw);
    final double breath =
        still ? 0 : (after == 0 ? 0 : 0.5 + 0.5 * sin(after * 4 * pi));
    final double glow = 1 + 0.35 * breath;

    final Paint outer = Paint()
      ..color = NeonWinLine.orange.withValues(alpha: 0.42)
      ..strokeWidth = thickness * 0.15 * glow
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    final Paint mid = Paint()
      ..shader = LinearGradient(colors: const <Color>[
        NeonWinLine.orange,
        NeonWinLine.gold,
        NeonWinLine.orange,
      ]).createShader(Rect.fromPoints(a, b))
      ..strokeWidth = thickness * 0.075
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final Paint core = Paint()
      ..color = NeonWinLine.hotCore
      ..strokeWidth = thickness * 0.03
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(a, tip, outer);
    canvas.drawLine(a, tip, mid);
    canvas.drawLine(a, tip, core);

    if (progress < 1) {
      // Cometa na ponta enquanto desenha.
      canvas.drawCircle(
        tip,
        thickness * 0.05,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    } else if (!still) {
      // Reflexo que atravessa a linha duas vezes.
      final double shimmer = (after * 2) % 1;
      final Offset s = Offset.lerp(a, b, shimmer)!;
      canvas.drawLine(
        s - dir * thickness * 0.08,
        s + dir * thickness * 0.08,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85 * (1 - after))
          ..strokeWidth = thickness * 0.05
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Clarão e anéis do impacto, logo depois de fechar.
      final double impact = (after / 0.22).clamp(0.0, 1.0);
      if (impact < 1) {
        final Offset center = Offset.lerp(a, b, 0.5)!;
        canvas.drawCircle(
          center,
          size.shortestSide * (0.25 + 0.55 * impact),
          Paint()
            ..color = NeonWinLine.gold.withValues(alpha: 0.32 * (1 - impact))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
        );
        for (final Offset end in <Offset>[a, b]) {
          canvas.drawCircle(
            end,
            thickness * (0.04 + 0.22 * impact),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = thickness * 0.02 * (1 - impact) + 0.5
              ..color = NeonWinLine.gold.withValues(alpha: 1 - impact),
          );
        }
      }
    }

    for (final _Spark p in sparks) {
      final double age = (time - p.bornAt).clamp(0.0, p.lifespan);
      final double life = age / p.lifespan;
      final Offset birth =
          Offset.lerp(a, b, p.along)! + normal * (p.offset * thickness);
      final Offset pos = birth + p.velocity * age * 3.2;
      canvas.drawCircle(
        pos,
        p.size * (1 - life),
        Paint()
          ..color = p.color.withValues(alpha: (1 - life) * 0.95)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(_NeonWinLinePainter oldDelegate) => true;
}

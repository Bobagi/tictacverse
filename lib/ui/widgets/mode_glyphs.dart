import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/game_mode.dart';

/// Glifos neon desenhados à mão para os cards de modo — cada um retrata a
/// REGRA do modo na mesma linguagem visual do tabuleiro (glow da cor do modo
/// + núcleo branco-quente), em vez de um Material Icon genérico.
class ModeGlyph extends StatelessWidget {
  const ModeGlyph({
    super.key,
    required this.type,
    required this.accent,
    this.size = 30,
  });

  final GameModeType type;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ModeGlyphPainter(type: type, accent: accent),
    );
  }
}

class _ModeGlyphPainter extends CustomPainter {
  _ModeGlyphPainter({required this.type, required this.accent});

  final GameModeType type;
  final Color accent;

  late double _s;

  Color get _core => Color.lerp(accent, Colors.white, 0.6)!;

  Paint _glow(double width, {double opacity = 0.85}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = width
    ..color = accent.withOpacity(opacity)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, _s * 0.06);

  Paint _stroke(double width, {Color? color}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = width
    ..color = color ?? _core;

  Offset _p(double x, double y) => Offset(x * _s, y * _s);

  @override
  void paint(Canvas canvas, Size size) {
    _s = size.shortestSide;
    switch (type) {
      case GameModeType.ultimate2:
        _paintUltimate(canvas);
      case GameModeType.classic:
        _paintClassic(canvas);
      case GameModeType.shift:
        _paintShift(canvas);
      case GameModeType.chaos:
        _paintChaos(canvas);
      case GameModeType.ultimateMini:
        _paintUltimateMini(canvas);
    }
  }

  /// Grade 3×3 desenhada em [rect], com traço [width] e cor [color].
  void _paintGrid(Canvas canvas, Rect rect, double width, Color color,
      {bool withGlow = false}) {
    final Path grid = Path();
    for (int i = 1; i <= 2; i++) {
      final double dx = rect.left + rect.width * i / 3;
      final double dy = rect.top + rect.height * i / 3;
      grid
        ..moveTo(dx, rect.top)
        ..lineTo(dx, rect.bottom)
        ..moveTo(rect.left, dy)
        ..lineTo(rect.right, dy);
    }
    if (withGlow) {
      canvas.drawPath(grid, _glow(width * 1.8, opacity: 0.6));
    }
    canvas.drawPath(grid, _stroke(width, color: color));
  }

  /// Clássico: a cerquilha com a diagonal vencedora riscada por cima.
  void _paintClassic(Canvas canvas) {
    final Rect board = Rect.fromLTRB(_s * 0.12, _s * 0.12, _s * 0.88, _s * 0.88);
    _paintGrid(canvas, board, _s * 0.07, accent, withGlow: true);
    final Offset a = _p(0.18, 0.18);
    final Offset b = _p(0.82, 0.82);
    canvas.drawLine(a, b, _glow(_s * 0.16, opacity: 0.9));
    canvas.drawLine(a, b, _stroke(_s * 0.07));
  }

  /// Ultimate: tabuleiro dentro do tabuleiro — o macro com um mini-jogo
  /// aceso na célula central.
  void _paintUltimate(Canvas canvas) {
    final Rect board = Rect.fromLTRB(_s * 0.08, _s * 0.08, _s * 0.92, _s * 0.92);
    _paintGrid(canvas, board, _s * 0.06, accent, withGlow: true);
    final Rect cell = Rect.fromCenter(
      center: board.center,
      width: board.width / 3 - _s * 0.05,
      height: board.height / 3 - _s * 0.05,
    );
    canvas.drawRect(
      cell.inflate(_s * 0.03),
      Paint()
        ..color = accent.withOpacity(0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _s * 0.08),
    );
    _paintGrid(canvas, cell, _s * 0.045, Colors.white);
  }

  /// Shift: peça girando na esteira — nó quadrado + seta circular.
  void _paintShift(Canvas canvas) {
    final Rect orbit = Rect.fromCircle(center: _p(0.5, 0.5), radius: _s * 0.34);
    const double startAngle = -pi / 2 + 0.5;
    const double sweep = 1.62 * pi;
    canvas.drawArc(orbit, startAngle, sweep, false, _glow(_s * 0.13, opacity: 0.8));
    canvas.drawArc(orbit, startAngle, sweep, false, _stroke(_s * 0.06));
    // ponta da seta no fim do arco
    const double endAngle = startAngle + sweep;
    final Offset tip = _p(0.5, 0.5) +
        Offset(cos(endAngle), sin(endAngle)) * _s * 0.34;
    final double tangent = endAngle + pi / 2;
    Offset wing(double turn) =>
        tip - Offset(cos(tangent + turn), sin(tangent + turn)) * _s * 0.16;
    final Path arrow = Path()
      ..moveTo(wing(0.5).dx, wing(0.5).dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(wing(-0.5).dx, wing(-0.5).dy);
    canvas.drawPath(arrow, _glow(_s * 0.12, opacity: 0.8));
    canvas.drawPath(arrow, _stroke(_s * 0.06));
    // a peça que desliza (nó quadrado no início do arco)
    final Offset node = _p(0.5, 0.5) +
        Offset(cos(startAngle), sin(startAngle)) * _s * 0.34;
    final Rect piece = Rect.fromCenter(
        center: node, width: _s * 0.2, height: _s * 0.2);
    canvas.drawRect(piece, Paint()..color = accent.withOpacity(0.9));
    canvas.drawRect(
      piece,
      Paint()
        ..color = accent.withOpacity(0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _s * 0.07),
    );
  }

  /// Chaos: o raio rasgando uma grade partida.
  void _paintChaos(Canvas canvas) {
    // fragmentos da grade, tortos, atrás do raio
    final Paint frag = _stroke(_s * 0.05, color: accent.withOpacity(0.55));
    canvas.drawLine(_p(0.08, 0.30), _p(0.34, 0.24), frag);
    canvas.drawLine(_p(0.14, 0.10), _p(0.24, 0.42), frag);
    canvas.drawLine(_p(0.68, 0.78), _p(0.92, 0.68), frag);
    canvas.drawLine(_p(0.76, 0.58), _p(0.84, 0.90), frag);
    final Path bolt = Path()
      ..moveTo(_s * 0.62, _s * 0.06)
      ..lineTo(_s * 0.32, _s * 0.52)
      ..lineTo(_s * 0.52, _s * 0.52)
      ..lineTo(_s * 0.38, _s * 0.94)
      ..lineTo(_s * 0.72, _s * 0.44)
      ..lineTo(_s * 0.52, _s * 0.44)
      ..lineTo(_s * 0.70, _s * 0.06)
      ..close();
    canvas.drawPath(
      bolt,
      Paint()
        ..color = accent.withOpacity(0.75)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _s * 0.09),
    );
    canvas.drawPath(bolt, Paint()..color = _core);
  }

  /// Mini Supremo: a grade pequena com a faísca de evento no centro.
  void _paintUltimateMini(Canvas canvas) {
    final Rect board = Rect.fromLTRB(_s * 0.14, _s * 0.14, _s * 0.86, _s * 0.86);
    _paintGrid(canvas, board, _s * 0.06, accent, withGlow: true);
    final Offset c = board.center;
    final Path spark = Path()
      ..moveTo(c.dx, c.dy - _s * 0.22)
      ..quadraticBezierTo(c.dx + _s * 0.035, c.dy - _s * 0.035, c.dx + _s * 0.22, c.dy)
      ..quadraticBezierTo(c.dx + _s * 0.035, c.dy + _s * 0.035, c.dx, c.dy + _s * 0.22)
      ..quadraticBezierTo(c.dx - _s * 0.035, c.dy + _s * 0.035, c.dx - _s * 0.22, c.dy)
      ..quadraticBezierTo(c.dx - _s * 0.035, c.dy - _s * 0.035, c.dx, c.dy - _s * 0.22)
      ..close();
    canvas.drawPath(
      spark,
      Paint()
        ..color = accent.withOpacity(0.8)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _s * 0.09),
    );
    canvas.drawPath(spark, Paint()..color = _core);
  }

  @override
  bool shouldRepaint(_ModeGlyphPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.accent != accent;
}

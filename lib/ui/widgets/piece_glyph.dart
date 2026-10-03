import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/piece_skin.dart';
import '../../models/player_marker.dart';
import '../../services/economy_service.dart';
import '../../services/progression_service.dart';

/// Uma peça (X ou O) desenhada no visual equipado. Todo lugar do app que
/// mostra peça passa por aqui, para a compra na loja valer em todos os modos.
///
/// Com [skin] informado desenha aquele visual (prévia da loja); sem ele,
/// acompanha o visual equipado e se redesenha quando o jogador troca.
class PieceGlyph extends StatelessWidget {
  const PieceGlyph({
    super.key,
    required this.marker,
    this.skin,
    this.size,
  });

  final PlayerMarker marker;
  final PieceSkin? skin;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final PieceSkin? fixed = skin;
    if (fixed != null) {
      return _paint(fixed);
    }
    return ValueListenableBuilder<int>(
      valueListenable: ProgressionService.instance.revision,
      builder: (BuildContext context, int _, Widget? __) =>
          _paint(EconomyService.instance.equippedSkin),
    );
  }

  Widget _paint(PieceSkin skin) {
    final Widget glyph = skin.style == PieceSkinStyle.artwork
        ? Image.asset(
            marker == PlayerMarker.cross
                ? 'assets/symbols/x/x.png'
                : 'assets/symbols/o/o.png',
            fit: BoxFit.contain,
          )
        : CustomPaint(
            painter: PiecePainter(skin: skin, marker: marker),
            child: const SizedBox.expand(),
          );
    if (size == null) {
      return glyph;
    }
    return SizedBox(width: size, height: size, child: glyph);
  }
}

/// Desenho vetorial das peças. Ocupa ~70% da caixa, centralizado, para casar
/// com o respiro das artes PNG e não mudar a leitura do tabuleiro ao trocar.
class PiecePainter extends CustomPainter {
  PiecePainter({required this.skin, required this.marker});

  final PieceSkin skin;
  final PlayerMarker marker;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    final Offset center = size.center(Offset.zero);
    final Rect box =
        Rect.fromCenter(center: center, width: side * 0.7, height: side * 0.7);
    final List<Color> colors =
        marker == PlayerMarker.cross ? skin.crossColors : skin.noughtColors;
    final Shader shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(box);

    final double stroke = switch (skin.style) {
      PieceSkinStyle.neon => side * 0.075,
      PieceSkinStyle.candy => side * 0.17,
      PieceSkinStyle.galaxy => side * 0.11,
      _ => side * 0.13,
    };
    final Path path = marker == PlayerMarker.cross
        ? (Path()
          ..moveTo(box.left, box.top)
          ..lineTo(box.right, box.bottom)
          ..moveTo(box.right, box.top)
          ..lineTo(box.left, box.bottom))
        : (Path()..addOval(box.deflate(stroke * 0.15)));

    // Halo: o mesmo traço, mais largo e borrado, por baixo.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke * (skin.style == PieceSkinStyle.neon ? 2.6 : 1.5)
        ..color = colors.first
            .withOpacity(skin.style == PieceSkinStyle.neon ? 0.55 : 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.06),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..shader = shader,
    );

    switch (skin.style) {
      case PieceSkinStyle.neon:
        // Miolo claro: é o que faz o traço parecer tubo de neon aceso.
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = stroke * 0.35
            ..color = Colors.white.withOpacity(0.9),
        );
      case PieceSkinStyle.candy:
        // Reflexo de bala: um traço fino e claro deslocado para cima.
        canvas.save();
        canvas.translate(-stroke * 0.18, -stroke * 0.22);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = stroke * 0.22
            ..color = Colors.white.withOpacity(0.55),
        );
        canvas.restore();
      case PieceSkinStyle.galaxy:
        if (marker == PlayerMarker.nought) {
          canvas.drawOval(
            box.deflate(stroke * 1.25),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke * 0.22
              ..color = colors.last.withOpacity(0.7),
          );
        }
        final Paint star = Paint()..color = Colors.white.withOpacity(0.9);
        for (final Offset at in <Offset>[
          Offset(box.right, box.top + box.height * 0.08),
          Offset(box.left + box.width * 0.04, box.bottom - box.height * 0.1),
          Offset(box.center.dx + box.width * 0.42,
              box.center.dy + box.height * 0.3),
        ]) {
          canvas.drawCircle(at, side * 0.018, star);
        }
      case PieceSkinStyle.gradient:
      case PieceSkinStyle.artwork:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant PiecePainter oldDelegate) =>
      oldDelegate.skin.id != skin.id || oldDelegate.marker != marker;
}

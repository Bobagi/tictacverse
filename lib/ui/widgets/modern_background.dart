import 'dart:ui';

import 'package:flutter/material.dart';

/// Paleta "fliperama neon" do app (derivada do ícone: violeta quente,
/// ciano do X, magenta do O e dourado de energia).
class VerseColors {
  static const Color bgTop = Color(0xFF1A0B2E);
  static const Color bgMid = Color(0xFF2D1152);
  static const Color bgBottom = Color(0xFF3A0F55);
  static const Color surface = Color(0xFF2A1450);
  static const Color surfaceDeep = Color(0xFF1D0E3A);
  static const Color cross = Color(0xFF35D6FF);
  static const Color nought = Color(0xFFFF4FD8);
  static const Color energy = Color(0xFFFFB938);
  static const Color danger = Color(0xFFFF5A6A);
  static const Color mutedText = Color(0xFFC9B8E8);
  static const Color line = Color(0xFF6D4BA6);
}

class ModernGradientBackground extends StatelessWidget {
  const ModernGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            VerseColors.bgTop,
            VerseColors.bgMid,
            VerseColors.bgBottom,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: <Widget>[
          _buildGlowingCircle(
            color: VerseColors.nought.withOpacity(0.22),
            diameter: 300,
            offset: const Offset(-80, -60),
          ),
          _buildGlowingCircle(
            color: VerseColors.cross.withOpacity(0.16),
            diameter: 340,
            offset: const Offset(200, 340),
          ),
          _buildGlowingCircle(
            color: VerseColors.energy.withOpacity(0.10),
            diameter: 260,
            offset: const Offset(-60, 460),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _buildGlowingCircle(
      {required Color color, required double diameter, required Offset offset}) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel(
      {super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          colors: <Color>[VerseColors.surface, VerseColors.surfaceDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: VerseColors.line.withOpacity(0.55), width: 1.4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';

class ModernGradientBackground extends StatelessWidget {
  const ModernGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Color(0xFF0B1224),
            Color(0xFF0F1B35),
            Color(0xFF0A0F1F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: <Widget>[
          _buildGlowingCircle(
            color: Colors.pinkAccent.withOpacity(0.25),
            diameter: 260,
            offset: const Offset(-60, -40),
          ),
          _buildGlowingCircle(
            color: Colors.cyanAccent.withOpacity(0.2),
            diameter: 320,
            offset: const Offset(180, 360),
          ),
          _buildGlowingCircle(
            color: Colors.blueAccent.withOpacity(0.15),
            diameter: 240,
            offset: const Offset(-40, 380),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _buildGlowingCircle({required Color color, required double diameter, required Offset offset}) {
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
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

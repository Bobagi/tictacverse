import 'package:flutter/material.dart';

/// Esmaece a borda de baixo de uma lista, sinalizando que há mais conteúdo.
///
/// Sem isso o último item aparece fatiado no limite do painel e parece um bug
/// de layout, não um convite a rolar.
class FadingEdge extends StatelessWidget {
  const FadingEdge({super.key, required this.child, this.fraction = 0.92});

  final Widget child;

  /// Onde o esmaecimento começa (fração da altura).
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const <Color>[Colors.white, Colors.white, Colors.transparent],
          stops: <double>[0, fraction, 1],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}

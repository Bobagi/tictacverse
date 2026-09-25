import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictacverse/ui/widgets/board_shake.dart';

/// Sonda: guarda o State para o teste saber se o filho foi REMONTADO.
class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  static int instances = 0;

  @override
  void initState() {
    super.initState();
    instances += 1;
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 10, height: 10);
}

Widget host(int trigger) => MaterialApp(
      home: Scaffold(
        body: Center(child: BoardShake(trigger: trigger, child: const _Probe())),
      ),
    );

void main() {
  testWidgets('tremer o tabuleiro NÃO remonta o filho (a linha da vitória continua)',
      (WidgetTester tester) async {
    _ProbeState.instances = 0;
    await tester.pumpWidget(host(0));
    expect(_ProbeState.instances, 1);

    // Dispara a tremida e atravessa o primeiro frame (t: 0 -> >0), o meio e o
    // fim (t = 1): eram os três pontos em que a árvore mudava de forma.
    await tester.pumpWidget(host(1));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 240));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));

    expect(_ProbeState.instances, 1,
        reason: 'o filho foi recriado durante a tremida: linha neon, pop-in e '
            'rotação das peças recomeçam do zero');
  });
}

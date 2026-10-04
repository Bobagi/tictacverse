import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tictacverse/l10n/app_localizations.dart';

import '../../services/audio_service.dart';
import '../../services/haptics_service.dart';
import 'juice/particles.dart';
import 'modern_background.dart';

/// Abre o tutorial jogável do Super Jogo da Velha. Devolve quando o jogador
/// termina ou pula.
Future<void> showUltimateTutorial(
    BuildContext context, AppLocalizations localization) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) =>
        UltimateTutorial(localization: localization),
  );
}

/// Um passo do roteiro. [target] = casa que o jogador precisa tocar
/// (tabuleiro, casa); nulo = passo só de leitura, com botão "próximo".
class TutorialStep {
  const TutorialStep({required this.text, this.target, this.activeBoard});

  final String Function(AppLocalizations l) text;
  final (int, int)? target;

  /// Mini-tabuleiro destacado (para onde a jogada manda).
  final int? activeBoard;
}

/// Roteiro: a regra que confunde é "a casa em que você joga decide o
/// tabuleiro em que o outro joga". O jogador FAZ isso duas vezes, com a
/// resposta do adversário acontecendo na frente dele.
const List<TutorialStep> ultimateTutorialSteps = <TutorialStep>[
  TutorialStep(text: _intro),
  TutorialStep(text: _tapFirst, target: (4, 2), activeBoard: 4),
  TutorialStep(text: _sent, activeBoard: 2),
  TutorialStep(text: _tapSecond, target: (4, 0), activeBoard: 4),
  TutorialStep(text: _final),
];

String _intro(AppLocalizations l) => l.tutorialIntro;
String _tapFirst(AppLocalizations l) => l.tutorialTapFirst;
String _sent(AppLocalizations l) => l.tutorialSent;
String _tapSecond(AppLocalizations l) => l.tutorialTapSecond;
String _final(AppLocalizations l) => l.tutorialFinal;

class UltimateTutorial extends StatefulWidget {
  const UltimateTutorial({super.key, required this.localization});

  final AppLocalizations localization;

  @override
  State<UltimateTutorial> createState() => _UltimateTutorialState();
}

class _UltimateTutorialState extends State<UltimateTutorial>
    with SingleTickerProviderStateMixin {
  int _step = 0;

  /// Peças no tabuleiro do roteiro: (tabuleiro, casa) -> 'X' ou 'O'.
  final Map<(int, int), String> _pieces = <(int, int), String>{};
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  Timer? _reply;
  bool _waitingReply = false;

  /// Explosão na casa certa: o acerto do jogador tem de ser comemorado.
  final ParticleController _fx = ParticleController();
  double _boardSize = 0;

  TutorialStep get _current => ultimateTutorialSteps[_step];

  @override
  void dispose() {
    _pulse.dispose();
    _reply?.cancel();
    _fx.dispose();
    super.dispose();
  }

  void _advance() {
    if (_step >= ultimateTutorialSteps.length - 1) {
      AudioService.instance.play(Sfx.achievement);
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step++);
  }

  void _onCellTap(int board, int cell) {
    final (int, int)? target = _current.target;
    if (target == null || _waitingReply || target != (board, cell)) {
      return;
    }
    AudioService.instance.playMoveSfx();
    AudioService.instance.play(Sfx.capture);
    HapticsService.instance.play(HapticCue.capture);
    setState(() => _pieces[(board, cell)] = 'X');
    if (_boardSize > 0) {
      final double c = _boardSize / 9;
      final int row = (board ~/ 3) * 3 + cell ~/ 3;
      final int col = (board % 3) * 3 + cell % 3;
      _fx.burst(
        center: Offset((col + 0.5) * c, (row + 0.5) * c),
        color: VerseColors.cross,
        accent: VerseColors.coin,
        count: 22,
        speed: 0.9,
        size: 4,
      );
    }
    if (_step == 1) {
      // A resposta do adversário acontece na frente do jogador: ele foi
      // mandado para o tabuleiro 2 e joga no centro dele, o que manda o
      // jogador de volta ao tabuleiro do centro.
      _waitingReply = true;
      setState(() => _step = 2);
      _reply = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) {
          return;
        }
        AudioService.instance.playMoveSfx(isNought: true);
        setState(() {
          _pieces[(2, 4)] = 'O';
          _waitingReply = false;
        });
      });
      return;
    }
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = widget.localization;
    final bool readOnly = _current.target == null;
    final bool last = _step == ultimateTutorialSteps.length - 1;
    return SafeArea(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GlassPanel(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(l.tutorialTitle,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    Text('${_step + 1}/${ultimateTutorialSteps.length}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: VerseColors.mutedText)),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    _current.text(l),
                    key: ValueKey<int>(_step),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    final double size = c.maxWidth.clamp(0, 340).toDouble();
                    _boardSize = size;
                    return Center(
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: GestureDetector(
                          key: const ValueKey<String>('tutorial-board'),
                          onTapUp: (TapUpDetails d) {
                            final double cell = size / 9;
                            final int col =
                                (d.localPosition.dx / cell).floor().clamp(0, 8);
                            final int row =
                                (d.localPosition.dy / cell).floor().clamp(0, 8);
                            final int board = (row ~/ 3) * 3 + col ~/ 3;
                            final int inner = (row % 3) * 3 + col % 3;
                            _onCellTap(board, inner);
                          },
                          child: Stack(
                            children: <Widget>[
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (BuildContext context, _) =>
                                      CustomPaint(
                                    painter: _TutorialBoardPainter(
                                      pieces: _pieces,
                                      activeBoard: _current.activeBoard,
                                      target: _waitingReply
                                          ? null
                                          : _current.target,
                                      pulse: _pulse.value,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                    child: ParticleField(controller: _fx)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // OverflowBar: em 360px, hindi/bengali não cabem lado a lado e
                // os botões descem um embaixo do outro em vez de estourar.
                OverflowBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  overflowAlignment: OverflowBarAlignment.end,
                  overflowSpacing: 6,
                  children: <Widget>[
                    TextButton(
                      key: const ValueKey<String>('tutorial-skip'),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l.tutorialSkip),
                    ),
                    if (readOnly)
                      FilledButton(
                        key: const ValueKey<String>('tutorial-next'),
                        onPressed: _waitingReply ? null : _advance,
                        child: Text(last ? l.tutorialPlay : l.tutorialNext),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Desenha o 9x9 do roteiro: grade grande, grades pequenas, peças, o
/// mini-tabuleiro destacado e a casa-alvo pulsando.
class _TutorialBoardPainter extends CustomPainter {
  _TutorialBoardPainter({
    required this.pieces,
    required this.activeBoard,
    required this.target,
    required this.pulse,
  });

  final Map<(int, int), String> pieces;
  final int? activeBoard;
  final (int, int)? target;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 9;
    final double block = size.width / 3;

    if (activeBoard != null) {
      final Rect r = Rect.fromLTWH((activeBoard! % 3) * block,
          (activeBoard! ~/ 3) * block, block, block);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(8)),
        Paint()..color = VerseColors.coin.withOpacity(0.16),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(8)),
        Paint()
          ..color = VerseColors.coin.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    final Paint thin = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 1;
    for (int i = 1; i < 9; i++) {
      if (i % 3 == 0) {
        continue;
      }
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), thin);
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), thin);
    }
    final Paint thick = Paint()
      ..color = VerseColors.line
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
          Offset(i * block, 0), Offset(i * block, size.height), thick);
      canvas.drawLine(
          Offset(0, i * block), Offset(size.width, i * block), thick);
    }

    Offset centerOf(int board, int inner) {
      final int row = (board ~/ 3) * 3 + inner ~/ 3;
      final int col = (board % 3) * 3 + inner % 3;
      return Offset((col + 0.5) * cell, (row + 0.5) * cell);
    }

    if (target != null) {
      final Offset c = centerOf(target!.$1, target!.$2);
      canvas.drawCircle(
        c,
        cell * (0.32 + 0.12 * pulse),
        Paint()..color = VerseColors.coin.withOpacity(0.35 + 0.35 * pulse),
      );
    }

    for (final MapEntry<(int, int), String> e in pieces.entries) {
      final Offset c = centerOf(e.key.$1, e.key.$2);
      final double r = cell * 0.28;
      if (e.value == 'X') {
        final Paint p = Paint()
          ..color = VerseColors.cross
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(c - Offset(r, r), c + Offset(r, r), p);
        canvas.drawLine(c + Offset(-r, r), c + Offset(r, -r), p);
      } else {
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..color = VerseColors.nought
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TutorialBoardPainter old) =>
      old.pulse != pulse ||
      old.activeBoard != activeBoard ||
      old.target != target ||
      old.pieces.length != pieces.length;
}

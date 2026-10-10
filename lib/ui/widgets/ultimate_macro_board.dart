import 'package:flutter/material.dart';

import '../../controllers/modes/ultimate2_engine.dart';
import '../../models/game_result.dart';
import '../../models/player_marker.dart';
import '../../services/economy_service.dart';
import '../../services/visual_assets.dart';
import 'juice/particles.dart';
import 'juice/press_scale.dart';
import 'juice/pulse.dart';
import 'modern_background.dart';
import 'neon_win_line.dart';
import 'piece_glyph.dart';
import 'pop_in.dart';

/// Tabuleiro do Super Jogo da Velha (macro 3x3 de mini-tabuleiros), com as
/// partículas de peça e de captura e a linha da vitória. Usado pela partida
/// local e pela online.
class UltimateMacroBoard extends StatefulWidget {
  const UltimateMacroBoard({
    super.key,
    required this.state,
    required this.visualAssets,
    required this.onCellTap,
    required this.particles,
    required this.interactive,
  });

  final Ultimate2State state;
  final VisualAssetConfig visualAssets;
  final void Function(int board, int cell) onCellTap;
  final ParticleController particles;
  final bool interactive;

  @override
  State<UltimateMacroBoard> createState() => _UltimateMacroBoardState();
}

class _UltimateMacroBoardState extends State<UltimateMacroBoard> {
  /// Moldura e destaque do mini-tabuleiro jogável: cor do tema em uso.
  Color get _frame => EconomyService.instance.equippedTheme.frame;

  static const double _outerPadding = 6;
  static const double _miniPadding = 4;
  static const double _miniInnerPadding = 3;

  double _lastSize = 0;

  @override
  void didUpdateWidget(UltimateMacroBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _emitParticles(oldWidget.state, widget.state);
  }

  /// Centro de uma célula (board, cell) nas coordenadas do Stack interno.
  Offset _cellCenter(int board, int cell) {
    final double inner = _lastSize - 2 * _outerPadding;
    final double mini = inner / 3;
    final double miniOrigin = mini * (board % 3);
    final double miniOriginY = mini * (board ~/ 3);
    final double cellArea = mini - 2 * (_miniPadding + _miniInnerPadding);
    final double cellSize = cellArea / 3;
    final double offset = _miniPadding + _miniInnerPadding;
    return Offset(
      miniOrigin + offset + (cell % 3 + 0.5) * cellSize,
      miniOriginY + offset + (cell ~/ 3 + 0.5) * cellSize,
    );
  }

  Offset _miniCenter(int board) {
    final double inner = _lastSize - 2 * _outerPadding;
    final double mini = inner / 3;
    return Offset((board % 3 + 0.5) * mini, (board ~/ 3 + 0.5) * mini);
  }

  void _emitParticles(Ultimate2State before, Ultimate2State after) {
    if (_lastSize <= 0 || identical(before, after)) {
      return;
    }
    final double mini = (_lastSize - 2 * _outerPadding) / 3;
    // Peça nova: explosão pequena na célula.
    if (after.lastBoard != null &&
        after.lastCell != null &&
        before.boards[after.lastBoard!][after.lastCell!] == null &&
        after.boards[after.lastBoard!][after.lastCell!] != null) {
      final PlayerMarker marker =
          after.boards[after.lastBoard!][after.lastCell!]!;
      widget.particles.burst(
        center: _cellCenter(after.lastBoard!, after.lastCell!),
        color: marker == PlayerMarker.cross
            ? const Color(0xFF6BE0FF)
            : const Color(0xFFFF6BD9),
        accent: Colors.white,
        count: 10,
        size: mini * 0.05,
        speed: mini / 110,
      );
    }
    // Mini-tabuleiro conquistado: explosão grande, colorida pelo dono.
    for (int board = 0; board < 9; board++) {
      if (before.macro[board] == null && after.macro[board] != null) {
        final PlayerMarker owner = after.macro[board]!;
        widget.particles.burst(
          center: _miniCenter(board),
          color: owner == PlayerMarker.cross
              ? const Color(0xFF6BE0FF)
              : const Color(0xFFFF6BD9),
          accent: VerseColors.energy,
          count: 30,
          size: mini * 0.09,
          speed: mini / 55,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Ultimate2State state = widget.state;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _frame.withOpacity(0.5), width: 2),
        color: Colors.white.withOpacity(0.03),
      ),
      padding: const EdgeInsets.all(_outerPadding),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _lastSize = constraints.biggest.shortestSide + 2 * _outerPadding;
          return Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  for (int row = 0; row < 3; row++)
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          for (int col = 0; col < 3; col++)
                            Expanded(child: _buildMini(context, row * 3 + col)),
                        ],
                      ),
                    ),
                ],
              ),
              Positioned.fill(
                  child: ParticleField(controller: widget.particles)),
              if (state.result.resolution == GameResolution.victory &&
                  state.result.winningLine != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: NeonWinLine(
                      key: ValueKey<String>(
                          'macro-${state.result.winningLine!.join('-')}'),
                      winningLine: state.result.winningLine!,
                      color: state.result.winner == PlayerMarker.cross
                          ? const Color(0xFF6BE0FF)
                          : const Color(0xFFFF6BD9),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMini(BuildContext context, int board) {
    final Ultimate2State state = widget.state;
    final bool playable = state.isBoardPlayable(board);
    final PlayerMarker? owner = state.macro[board];
    final bool closed = state.isBoardClosed(board);
    final bool isWinningBoard =
        state.result.winningLine?.contains(board) ?? false;
    final Color ownerColor = owner == PlayerMarker.cross
        ? const Color(0xFF6BE0FF)
        : const Color(0xFFFF6BD9);

    return Padding(
      padding: const EdgeInsets.all(_miniPadding),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: playable
              ? _frame.withOpacity(0.10)
              : (owner != null
                  ? ownerColor.withOpacity(0.08)
                  : Colors.white.withOpacity(0.03)),
          border: Border.all(
            color: playable
                ? _frame
                : (owner != null
                    ? ownerColor.withOpacity(0.45)
                    : Colors.white.withOpacity(closed ? 0.10 : 0.22)),
            width: playable ? 1.8 : 1,
          ),
          boxShadow: playable
              ? <BoxShadow>[
                  BoxShadow(color: _frame.withOpacity(0.35), blurRadius: 12),
                ]
              : const <BoxShadow>[],
        ),
        child: Stack(
          children: <Widget>[
            Opacity(
              opacity: owner != null ? 0.25 : (closed ? 0.45 : 1),
              child: Padding(
                padding: const EdgeInsets.all(_miniInnerPadding),
                child: Column(
                  children: <Widget>[
                    for (int r = 0; r < 3; r++)
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            for (int c = 0; c < 3; c++)
                              Expanded(child: _buildCell(board, r * 3 + c)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (owner != null)
              Positioned.fill(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.72,
                    heightFactor: 0.72,
                    child: PopIn(
                      beginScale: 1.7,
                      duration: const Duration(milliseconds: 380),
                      child: Pulse(
                        active: isWinningBoard,
                        maxScale: 1.12,
                        period: const Duration(milliseconds: 520),
                        child: PieceGlyph(marker: owner),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(int board, int cell) {
    final Ultimate2State state = widget.state;
    final PlayerMarker? marker = state.boards[board][cell];
    final bool isLast = state.lastBoard == board && state.lastCell == cell;
    return PressScale(
      enabled: widget.interactive && state.isCellPlayable(board, cell),
      pressedScale: 0.85,
      child: GestureDetector(
        onTap: () => widget.onCellTap(board, cell),
        child: Container(
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: isLast
                ? Colors.amberAccent.withOpacity(0.18)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: marker == null
              ? null
              : Padding(
                  padding: const EdgeInsets.all(2),
                  child: PopIn(
                    duration: const Duration(milliseconds: 200),
                    child: PieceGlyph(marker: marker),
                  ),
                ),
        ),
      ),
    );
  }
}

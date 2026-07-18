import 'dart:math';

import '../models/cpu_difficulty.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';
import '../models/player_marker.dart';
import 'cpu_strategy.dart';
import 'modes/chaos_rules_engine.dart';
import 'modes/classic_rules_engine.dart';
import 'modes/game_rules_engine.dart';
import 'modes/shift_rules_engine.dart';
import 'modes/ultimate_mini_rules_engine.dart';

class GameController {
  GameController({
    required this.modeDefinition,
    required this.playAgainstCpu,
    this.cpuDifficulty = CpuDifficulty.medium,
    Random? random,
  }) : _strategy = CpuStrategy(random: random) {
    _engine = _buildEngine();
    state = _engine.start();
  }

  final GameModeDefinition modeDefinition;
  final bool playAgainstCpu;
  final CpuDifficulty cpuDifficulty;
  final CpuStrategy _strategy;

  late GameRulesEngine _engine;
  late GameState state;

  void selectCell(int index) {
    if (state.result.isFinal) {
      return;
    }
    state = _engine.handlePlayerMove(state, index);
    if (_shouldTriggerCpuMove()) {
      _performCpuMove();
    }
  }

  /// Aplica só a jogada do humano — a CPU NÃO responde aqui. A UI agenda a
  /// resposta com [performPendingCpuMove] após a pausa de "pensamento".
  void selectCellHumanOnly(int index) {
    if (state.result.isFinal) {
      return;
    }
    state = _engine.handlePlayerMove(state, index);
  }

  /// Há uma resposta da CPU aguardando ser executada?
  bool get isCpuMovePending => _shouldTriggerCpuMove();

  /// Executa a jogada pendente da CPU (no-op se não houver ou se acabou).
  void performPendingCpuMove() {
    if (_shouldTriggerCpuMove()) {
      _performCpuMove();
    }
  }

  void resetMatch() {
    _engine = _buildEngine();
    state = _engine.start();
  }

  GameRulesEngine _buildEngine() {
    switch (modeDefinition.type) {
      case GameModeType.classic:
        return ClassicRulesEngine();
      case GameModeType.shift:
        return ShiftRulesEngine();
      case GameModeType.chaos:
        return ChaosRulesEngine();
      case GameModeType.ultimateMini:
        return UltimateMiniRulesEngine();
      case GameModeType.ultimate2:
        // Tic Tac Toe 2 tem tela/engine próprias (Ultimate2Screen).
        throw UnsupportedError('ultimate2 não usa GameController');
    }
  }

  bool _shouldTriggerCpuMove() =>
      playAgainstCpu && !state.result.isFinal && state.currentPlayer == PlayerMarker.nought;

  void _performCpuMove() {
    final int? chosenMove = _strategy.chooseMove(
      state: state,
      mode: modeDefinition.type,
      difficulty: cpuDifficulty,
    );
    if (chosenMove != null) {
      final GameState attemptedState = _engine.handlePlayerMove(state, chosenMove);
      if (!identical(attemptedState, state)) {
        state = attemptedState;
        return;
      }
    }
    // Fallback defensivo: primeira célula aceita pela engine.
    for (int i = 0; i < state.board.length; i++) {
      if (state.isCellAvailable(i)) {
        final GameState attemptedState = _engine.handlePlayerMove(state, i);
        if (!identical(attemptedState, state)) {
          state = attemptedState;
          break;
        }
      }
    }
  }
}

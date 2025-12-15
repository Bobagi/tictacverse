import '../models/game_mode.dart';
import '../models/game_state.dart';
import '../models/player_marker.dart';
import 'modes/chaos_rules_engine.dart';
import 'modes/classic_rules_engine.dart';
import 'modes/game_rules_engine.dart';
import 'modes/shift_rules_engine.dart';
import 'modes/ultimate_mini_rules_engine.dart';

class GameController {
  GameController({required this.modeDefinition, required this.playAgainstCpu}) {
    _engine = _buildEngine();
    state = _engine.start();
  }

  final GameModeDefinition modeDefinition;
  final bool playAgainstCpu;

  late GameRulesEngine _engine;
  late GameState state;

  void selectCell(int index) {
    state = _engine.handlePlayerMove(state, index);
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
    }
  }

  bool _shouldTriggerCpuMove() => playAgainstCpu && !state.result.isFinal && state.currentPlayer == PlayerMarker.nought;

  void _performCpuMove() {
    for (int i = 0; i < state.board.length; i++) {
      if (state.isCellAvailable(i)) {
        state = _engine.handlePlayerMove(state, i);
        break;
      }
    }
  }
}

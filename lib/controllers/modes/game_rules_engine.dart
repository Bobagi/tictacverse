import '../../models/game_state.dart';

abstract class GameRulesEngine {
  GameState start();
  GameState handlePlayerMove(GameState currentState, int selectedIndex);
}

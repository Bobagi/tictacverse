import 'package:flutter/foundation.dart';

import '../models/achievement.dart';
import '../models/progress_state.dart';
import 'progression_engine.dart';
import 'storage_service.dart';

/// Ponte entre o [ProgressionEngine] (regra pura) e o resto do app: guarda o
/// estado no [StorageService] e avisa a UI quando algo muda.
class ProgressionService {
  ProgressionService._();

  static final ProgressionService instance = ProgressionService._();

  final ProgressionEngine engine = ProgressionEngine();

  /// Incrementado a cada mudança, para os widgets se redesenharem sem precisar
  /// de um objeto de estado observável para cada contador.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  ProgressState get state => StorageService.instance.progress;

  List<AchievementDefinition> get catalog => engine.catalog;

  int get xp => state.xp;

  int get level => ProgressionEngine.levelForXp(state.xp);

  (int, int) get levelBar => ProgressionEngine.levelBar(state.xp);

  int get unlockedCount => state.unlockedAchievements.length;

  bool isUnlocked(AchievementDefinition achievement) =>
      state.unlockedAchievements.contains(achievement.id);

  /// Reavalia o catálogo no boot. Serve para quando uma atualização traz
  /// conquistas novas: quem já cumpria o requisito recebe na hora, em vez de
  /// ter de jogar mais uma partida para o desbloqueio disparar.
  void reconcileOnBoot() {
    final List<AchievementDefinition> unlocked = engine.reconcile(state);
    if (unlocked.isEmpty) {
      return;
    }
    StorageService.instance.saveProgress();
    revision.value += 1;
  }

  /// Registra o fim de uma partida e devolve o que mudou (XP, nível, medalhas).
  ProgressionResult registerMatch(MatchOutcome outcome) {
    final ProgressionResult result =
        engine.applyMatch(state, outcome, DateTime.now());
    StorageService.instance.saveProgress();
    revision.value += 1;
    return result;
  }
}

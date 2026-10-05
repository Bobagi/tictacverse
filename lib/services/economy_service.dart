import '../models/board_theme.dart';
import '../models/piece_skin.dart';
import '../models/progress_state.dart';
import 'economy_engine.dart';
import 'progression_service.dart';
import 'storage_service.dart';

/// Ponte entre o [EconomyEngine] (regra pura) e o app: grava no
/// [StorageService] e avisa a UI pelo mesmo `revision` da progressão, já que
/// moedas e visuais moram no mesmo [ProgressState].
class EconomyService {
  EconomyService._({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static final EconomyService instance = EconomyService._();

  final EconomyEngine engine = const EconomyEngine();
  final DateTime Function() _clock;

  ProgressState get _state => StorageService.instance.progress;

  int get coins => _state.coins;

  PieceSkin get equippedSkin => pieceSkinById(_state.equippedSkin);

  bool owns(PieceSkin skin) => _state.hasSkin(skin.id);

  bool get canClaimDaily => engine.canClaimDaily(_state, _clock());

  /// Dia da sequência e valor do bônus que o próximo resgate pagaria.
  int get nextDailyStreak => engine.nextDailyStreak(_state, _clock());
  int get nextDailyReward => EconomyEngine.rewardForStreak(nextDailyStreak);

  int get adCoinsRemaining => engine.adCoinsRemaining(_state, _clock());

  int claimDaily() => _commit(engine.claimDaily(_state, _clock()));

  /// Crédito extra igual ao bônus que acabou de ser resgatado ("dobrar"). Só
  /// depois de o SDK confirmar a recompensa do anúncio premiado.
  int grantDailyDouble(int amount) {
    engine.earn(_state, amount);
    return _commit(amount);
  }

  int grantAdCoins() => _commit(engine.grantAdCoins(_state, _clock()));

  SkinPurchaseResult buy(PieceSkin skin) {
    final SkinPurchaseResult result = engine.buySkin(_state, skin.id);
    if (result == SkinPurchaseResult.purchased) {
      _commit(1);
    }
    return result;
  }

  bool get adsRemoved => _state.adsRemoved;

  /// Produtos que a Play confirmou que o jogador possui.
  Set<String> get playOwned => Set<String>.unmodifiable(_state.playOwned);

  /// Grava o que a Play confirmou que o jogador possui (ver
  /// [EconomyEngine.applyPlayOwnership]).
  Future<void> applyPlayOwnership(Set<String> owned) async {
    if (engine.applyPlayOwnership(_state, owned)) {
      await _persist();
    }
  }

  Future<void> _persist() async {
    await StorageService.instance.saveProgress();
    ProgressionService.instance.revision.value += 1;
  }

  BoardTheme get equippedTheme => boardThemeById(_state.equippedTheme);

  bool ownsTheme(BoardTheme theme) => _state.hasTheme(theme.id);

  SkinPurchaseResult buyTheme(BoardTheme theme) {
    final SkinPurchaseResult result = engine.buyTheme(_state, theme.id);
    if (result == SkinPurchaseResult.purchased) {
      _commit(1);
    }
    return result;
  }

  bool equipTheme(BoardTheme theme) {
    final bool ok = engine.equipTheme(_state, theme.id);
    if (ok) {
      _commit(1);
    }
    return ok;
  }

  bool equip(PieceSkin skin) {
    final bool ok = engine.equipSkin(_state, skin.id);
    if (ok) {
      _commit(1);
    }
    return ok;
  }

  int _commit(int changed) {
    if (changed > 0) {
      StorageService.instance.saveProgress();
      ProgressionService.instance.revision.value += 1;
    }
    return changed;
  }
}

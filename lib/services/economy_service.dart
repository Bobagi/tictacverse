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

  bool owns(PieceSkin skin) => _state.ownedSkins.contains(skin.id);

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

  /// Entrega o que o servidor confirmou e grava ANTES de a compra ser
  /// consumida/finalizada na Play: se o app morrer no meio, a Play reentrega,
  /// o servidor confirma de novo e o token impede o crédito em dobro.
  Future<StoreGrant> applyServerGrant({
    required String purchaseToken,
    required int coins,
    required bool removeAds,
    bool permanent = false,
  }) async {
    final StoreGrant grant = engine.applyServerGrant(_state,
        purchaseToken: purchaseToken,
        coins: coins,
        removeAds: removeAds,
        permanent: permanent);
    await _persist();
    return grant;
  }

  /// Desfaz uma compra estornada (ver [EconomyEngine.applyRevocation]).
  Future<RevocationEffect> applyRevocation({
    required String redemptionId,
    required int coins,
    required bool removeAds,
  }) async {
    final RevocationEffect effect = engine.applyRevocation(_state,
        redemptionId: redemptionId, coins: coins, removeAds: removeAds);
    if (effect.applied) {
      await _persist();
    }
    return effect;
  }

  Future<void> _persist() async {
    await StorageService.instance.saveProgress();
    ProgressionService.instance.revision.value += 1;
  }

  BoardTheme get equippedTheme => boardThemeById(_state.equippedTheme);

  bool ownsTheme(BoardTheme theme) => _state.ownedThemes.contains(theme.id);

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

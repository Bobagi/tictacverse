import '../controllers/rewarded_ad_controller.dart';
import 'ad_service.dart';
import 'ads_configuration.dart';
import 'progression_engine.dart';
import 'progression_service.dart';

/// Decide se o convite "assista a um anúncio e dobre o XP" aparece no fim da
/// partida, e executa o crédito. Compartilhado pelas telas de jogo (Clássico e
/// Super Jogo da Velha) para as regras de proteção da conta valerem nas duas.
///
/// Regras, todas obrigatórias:
/// - Só com anúncio JÁ carregado: prometer o bônus e não ter o que exibir é
///   pior do que ficar calado.
/// - Nunca logo depois de um intersticial que foi mesmo exibido (encadear
///   anúncios queima o jogador e chama atenção da política do AdMob).
/// - Só quando a cadência do [AdService] libera, contada UMA vez por partida.
/// - Só com XP ganho na partida (o bônus dobra exatamente esse número).
/// - O crédito acontece somente depois de o SDK confirmar a recompensa.
class DoubleXpOffer {
  DoubleXpOffer({
    required this.rewardedAdController,
    required this.adService,
    ProgressionService? progressionService,
    bool? adsEnabled,
  })  : _progression = progressionService ?? ProgressionService.instance,
        _adsEnabled = adsEnabled ?? AdsConfiguration.adsEnabled;

  final RewardedAdGateway rewardedAdController;
  final AdService adService;
  final ProgressionService _progression;
  final bool _adsEnabled;

  ProgressionResult? _earned;
  bool _interstitialShownThisMatch = false;
  bool _rewardedOfferDueThisMatch = false;

  /// Chame assim que a partida acabar, com o resultado já registrado.
  void onMatchEnded(ProgressionResult earned) {
    _earned = earned;
    _interstitialShownThisMatch = false;
    _rewardedOfferDueThisMatch = false;
    rewardedAdController.loadRewardedAd();
  }

  /// Chame quando a celebração terminou e o intersticial já teve a sua vez.
  /// Conta a cadência aqui, uma vez por partida, e nunca dentro de um
  /// `builder` (que pode rodar de novo e adiantar o intervalo).
  void onCelebrationDone({required bool interstitialShown}) {
    _interstitialShownThisMatch = interstitialShown;
    _rewardedOfferDueThisMatch = adService.shouldOfferRewardedOnMatchEnd();
  }

  /// A oferta, ou `null` quando não há o que oferecer.
  Future<ProgressionResult?> Function()? build() {
    if (!_adsEnabled) {
      return null;
    }
    if (_interstitialShownThisMatch) {
      return null;
    }
    if (!_rewardedOfferDueThisMatch) {
      return null;
    }
    if (!rewardedAdController.isReady) {
      return null;
    }
    final ProgressionResult? earned = _earned;
    if (earned == null || earned.xpGained <= 0) {
      return null;
    }
    return _watchAdForDoubleXp;
  }

  /// O valor do bônus é fixado ANTES de abrir o anúncio (o XP da partida que
  /// acabou), então dobrar é sempre dobrar aquele número - e o crédito só
  /// acontece se o SDK confirmar que o jogador assistiu até o fim.
  Future<ProgressionResult?> _watchAdForDoubleXp() async {
    final ProgressionResult? earned = _earned;
    if (earned == null || earned.xpGained <= 0) {
      return null;
    }
    final int bonusXp = earned.xpGained;
    final bool rewarded = await rewardedAdController.showForReward();
    if (!rewarded) {
      return null;
    }
    return _progression.grantBonusXp(bonusXp);
  }
}

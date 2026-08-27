import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_unit_id_provider.dart';

/// Anúncio premiado (opt-in): o jogador escolhe assisti-lo em troca de um
/// bônus. Nunca é exibido sozinho - só a partir de um toque explícito.
class RewardedAdController {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _disposed = false;

  /// Resolve o `showForReward()` que ainda estiver pendente quando a tela sair,
  /// para nenhum `await` ficar preso num Future que nunca completa.
  void Function()? _pendingSettle;

  /// Há anúncio carregado e pronto para exibir. A oferta só aparece na UI
  /// quando isto é verdadeiro: prometer o bônus e depois não ter anúncio para
  /// mostrar é pior do que não oferecer.
  bool get isReady => _rewardedAd != null;

  void loadRewardedAd() {
    if (_disposed || _rewardedAd != null || _isLoading) {
      return;
    }
    final String adUnitId = AdUnitIdProvider.getRewardedAdUnitId();
    if (adUnitId.isEmpty) {
      return;
    }
    _isLoading = true;
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _isLoading = false;
          // A tela pode ter saído enquanto o anúncio carregava: sem isto,
          // sobra um RewardedAd vivo que ninguém mais libera.
          if (_disposed) {
            ad.dispose();
            return;
          }
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// Exibe o anúncio e resolve com `true` **somente** se o jogador assistiu até
  /// o fim e o SDK confirmou a recompensa.
  ///
  /// Resolve com `false` quando não havia anúncio carregado, quando ele falhou
  /// ao abrir, ou quando o jogador fechou antes do fim. Quem chama nunca deve
  /// creditar o bônus sem esperar por este `true`.
  Future<bool> showForReward() {
    final RewardedAd? ad = _disposed ? null : _rewardedAd;
    if (ad == null) {
      loadRewardedAd();
      return Future<bool>.value(false);
    }
    // Solta a referência antes de exibir: um segundo toque enquanto o anúncio
    // está na tela não pode reaproveitar a mesma instância.
    _rewardedAd = null;

    final Completer<bool> completer = Completer<bool>();
    bool earned = false;
    void settle() {
      _pendingSettle = null;
      if (!completer.isCompleted) {
        completer.complete(earned);
      }
    }

    _pendingSettle = settle;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (Ad ad) {
        ad.dispose();
        loadRewardedAd();
        settle();
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        ad.dispose();
        loadRewardedAd();
        settle();
      },
    );
    ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      earned = true;
    });
    return completer.future;
  }

  void dispose() {
    _disposed = true;
    // Se o jogador já tinha ganho a recompensa, o `settle` pendente resolve com
    // `true` e o crédito acontece mesmo com a tela saindo - assistiu, recebe.
    _pendingSettle?.call();
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}

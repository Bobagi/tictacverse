import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_unit_id_provider.dart';

class InterstitialAdController {
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  void loadInterstitialAd() {
    if (_interstitialAd != null || _isLoading) {
      return;
    }
    final String adUnitId = AdUnitIdProvider.getInterstitialAdUnitId();
    if (adUnitId.isEmpty) {
      return;
    }
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// Exibe o intersticial se houver um carregado. Devolve `true` só quando ele
  /// realmente foi para a tela - a tela de jogo usa isso para não emendar a
  /// oferta de anúncio premiado logo depois de um intersticial.
  bool showInterstitialAdIfAvailable() {
    if (_interstitialAd == null) {
      loadInterstitialAd();
      return false;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (Ad ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
    return true;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

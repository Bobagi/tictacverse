import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_unit_id_provider.dart';

class InterstitialAdController {
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  void loadInterstitialAd() {
    if (_isLoading || _interstitialAd != null) {
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

  void showInterstitialAdIfAvailable() {
    if (_interstitialAd == null) {
      loadInterstitialAd();
      return;
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
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

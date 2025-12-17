import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_unit_id_provider.dart';
import '../services/metrics_service.dart';

class MandatoryFullScreenAdController {
  MandatoryFullScreenAdController({
    required this.metricsService,
    this.matchesBeforeAd = 3,
  }) {
    _preloadRewardedAd();
  }

  final MetricsService metricsService;
  final int matchesBeforeAd;

  int _completedMatches = 0;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isRewardedLoading = false;
  bool _isInterstitialLoading = false;

  void tryShowAdAfterMatchCompleted() {
    _completedMatches += 1;
    if (_completedMatches % matchesBeforeAd != 0) {
      _preloadRewardedAd();
      return;
    }
    _showAvailableAd();
  }

  void preloadAds() {
    _preloadRewardedAd();
  }

  void _showAvailableAd() {
    if (_rewardedAd != null) {
      _presentRewardedAd();
      return;
    }
    if (_interstitialAd != null) {
      _presentInterstitialAd();
      return;
    }
    _loadRewardedAd(onLoaded: _presentRewardedAd, onFailed: _loadInterstitialAd);
  }

  void _preloadRewardedAd() {
    if (_rewardedAd == null && !_isRewardedLoading) {
      _loadRewardedAd();
    }
  }

  void _loadRewardedAd({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    final String adUnitId = AdUnitIdProvider.getRewardedAdUnitId();
    if (adUnitId.isEmpty) {
      onFailed?.call();
      return;
    }
    _isRewardedLoading = true;
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          onLoaded?.call();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedLoading = false;
          _rewardedAd = null;
          onFailed?.call();
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    if (_isInterstitialLoading) {
      return;
    }
    final String adUnitId = AdUnitIdProvider.getInterstitialAdUnitId();
    if (adUnitId.isEmpty) {
      return;
    }
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _presentInterstitialAd();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  void _presentRewardedAd() {
    if (_rewardedAd == null) {
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (Ad ad) {
        ad.dispose();
        _rewardedAd = null;
        _preloadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        ad.dispose();
        _rewardedAd = null;
        _loadInterstitialAd();
      },
    );
    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {});
    metricsService.recordAdImpression();
  }

  void _presentInterstitialAd() {
    if (_interstitialAd == null) {
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (Ad ad) {
        ad.dispose();
        _interstitialAd = null;
        _preloadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        ad.dispose();
        _interstitialAd = null;
        _preloadRewardedAd();
      },
    );
    _interstitialAd!.show();
    metricsService.recordAdImpression();
  }

  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd = null;
    _interstitialAd = null;
  }
}

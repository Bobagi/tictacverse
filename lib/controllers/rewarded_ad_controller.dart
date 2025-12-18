import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_unit_id_provider.dart';

class RewardedAdController {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  void loadRewardedAd() {
    if (_isLoading || _rewardedAd != null) {
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
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  void showRewardedAdIfAvailable({required void Function(RewardItem reward) onUserEarnedReward}) {
    if (_rewardedAd == null) {
      loadRewardedAd();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (Ad ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );
    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) => onUserEarnedReward(reward));
    _rewardedAd = null;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}

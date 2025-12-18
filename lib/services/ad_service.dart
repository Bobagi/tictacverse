class AdService {
  AdService({this.interstitialInterval = 3});

  final int interstitialInterval;
  int _matchesSinceInterstitial = 0;
  bool _shouldUseShorterInterstitialInterval = true;

  bool shouldShowBannerOnGameScreen() => true;

  bool shouldShowInterstitialOnMatchEnd() {
    _matchesSinceInterstitial += 1;

    final int currentInterval = _shouldUseShorterInterstitialInterval ? 2 : interstitialInterval;
    final bool shouldDisplay = _matchesSinceInterstitial % currentInterval == 0;

    if (shouldDisplay) {
      _shouldUseShorterInterstitialInterval = !_shouldUseShorterInterstitialInterval;
    }

    return shouldDisplay;
  }

  void resetTracking() {
    _matchesSinceInterstitial = 0;
    _shouldUseShorterInterstitialInterval = true;
  }
}
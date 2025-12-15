class AdService {
  AdService({this.interstitialInterval = 3});

  final int interstitialInterval;
  int _matchesSinceInterstitial = 0;

  bool shouldShowBannerOnGameScreen() => true;

  bool shouldShowInterstitialOnMatchEnd() {
    if (_matchesSinceInterstitial == 0) {
      _matchesSinceInterstitial += 1;
      return false;
    }
    final bool shouldDisplay = _matchesSinceInterstitial % interstitialInterval == 0;
    _matchesSinceInterstitial += 1;
    return shouldDisplay;
  }

  void resetTracking() {
    _matchesSinceInterstitial = 0;
  }
}

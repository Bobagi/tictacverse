class AdService {
  AdService({this.interstitialInterval = 5});

  final int interstitialInterval;
  int _matchesSinceInterstitial = 0;

  bool shouldShowBannerOnGameScreen() => true;

  bool shouldShowInterstitialOnMatchEnd() {
    _matchesSinceInterstitial += 1;
    if (_matchesSinceInterstitial < interstitialInterval) {
      return false;
    }
    _matchesSinceInterstitial = 0;
    return true;
  }

  void resetTracking() {
    _matchesSinceInterstitial = 0;
  }
}

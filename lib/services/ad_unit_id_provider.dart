import 'dart:io';

class AdUnitIdProvider {
  static const String _androidBannerAdUnitId = 'ca-app-pub-5349785075769585/4437308497';
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-5349785075769585/7877860053';
  static const String _androidRewardedAdUnitId = 'ca-app-pub-5349785075769585/6564778389';

  static String getBannerAdUnitId() {
    if (Platform.isAndroid) {
      return _androidBannerAdUnitId;
    }
    return '';
  }

  static String getInterstitialAdUnitId() {
    if (Platform.isAndroid) {
      return _androidInterstitialAdUnitId;
    }
    return '';
  }

  static String getRewardedAdUnitId() {
    if (Platform.isAndroid) {
      return _androidRewardedAdUnitId;
    }
    return '';
  }
}

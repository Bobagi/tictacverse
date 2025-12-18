import 'dart:io';

class AdUnitIdProvider {
  static String getBannerAdUnitId() {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5349785075769585/4437308497';
    }
    return '';
  }

  static String getInterstitialAdUnitId() {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5349785075769585/7877860053';
    }
    return '';
  }

  static String getRewardedAdUnitId() {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5349785075769585/6564778389';
    }
    return '';
  }
}

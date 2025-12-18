import 'dart:io';

import 'ads_configuration.dart';

class AdUnitIdProvider {
  static String getBannerAdUnitId() {
    if (AdsConfiguration.activeAdsMode == AdsMode.off) {
      return '';
    }
    if (!Platform.isAndroid) {
      return '';
    }
    if (AdsConfiguration.activeAdsMode == AdsMode.test) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    if (AdsConfiguration.activeAdsMode == AdsMode.real) {
      return 'ca-app-pub-5349785075769585/4437308497';
    }
    return '';
  }

  static String getInterstitialAdUnitId() {
    if (AdsConfiguration.activeAdsMode == AdsMode.off) {
      return '';
    }
    if (!Platform.isAndroid) {
      return '';
    }
    if (AdsConfiguration.activeAdsMode == AdsMode.test) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    if (AdsConfiguration.activeAdsMode == AdsMode.real) {
      return 'ca-app-pub-5349785075769585/7877860053';
    }
    return '';
  }

  static String getRewardedAdUnitId() {
    if (AdsConfiguration.activeAdsMode == AdsMode.off) {
      return '';
    }
    if (!Platform.isAndroid) {
      return '';
    }
    if (AdsConfiguration.activeAdsMode == AdsMode.test) {
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    if (AdsConfiguration.activeAdsMode == AdsMode.real) {
      return 'ca-app-pub-5349785075769585/6564778389';
    }
    return '';
  }
}

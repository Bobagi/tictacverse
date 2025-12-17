import 'dart:io';

import 'package:flutter/foundation.dart';

class AdUnitIdProvider {
  static String getBannerAdUnitId() {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111';
      }
      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716';
      }
    } else {
      if (Platform.isAndroid) {
        return 'REPLACE_WITH_ANDROID_BANNER_AD_UNIT_ID';
      }
      if (Platform.isIOS) {
        return 'REPLACE_WITH_IOS_BANNER_AD_UNIT_ID';
      }
    }
    return '';
  }

  static String getInterstitialAdUnitId() {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712';
      }
      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910';
      }
    } else {
      if (Platform.isAndroid) {
        return 'REPLACE_WITH_ANDROID_INTERSTITIAL_AD_UNIT_ID';
      }
      if (Platform.isIOS) {
        return 'REPLACE_WITH_IOS_INTERSTITIAL_AD_UNIT_ID';
      }
    }
    return '';
  }

  static String getRewardedAdUnitId() {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/5224354917';
      }
      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313';
      }
    } else {
      if (Platform.isAndroid) {
        return 'REPLACE_WITH_ANDROID_REWARDED_AD_UNIT_ID';
      }
      if (Platform.isIOS) {
        return 'REPLACE_WITH_IOS_REWARDED_AD_UNIT_ID';
      }
    }
    return '';
  }
}

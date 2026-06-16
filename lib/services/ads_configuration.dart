import 'package:flutter/foundation.dart';

enum AdsMode { off, test, real }

class AdsConfiguration {
  static const String _adsModeDefineKey = 'ADS_MODE';

  static AdsMode get activeAdsMode {
    // An explicit --dart-define=ADS_MODE=... always wins (off / test / real).
    const String adsModeValue = String.fromEnvironment(_adsModeDefineKey);
    switch (adsModeValue.toLowerCase()) {
      case 'off':
        return AdsMode.off;
      case 'real':
        return AdsMode.real;
      case 'test':
        return AdsMode.test;
      default:
        // No explicit override (e.g. building straight from the IDE):
        // release builds (the ones shipped to the Play Store) serve REAL ads,
        // every other build (debug/profile) serves TEST ads. This prevents
        // accidentally shipping test ads — which never generate revenue.
        return kReleaseMode ? AdsMode.real : AdsMode.test;
    }
  }
}

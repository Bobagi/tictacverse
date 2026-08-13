import 'package:flutter/foundation.dart';

enum AdsMode { off, test, real }

class AdsConfiguration {
  static const String _adsModeDefineKey = 'ADS_MODE';

  /// Kill switch dos anúncios: com true, o app não inicializa ads/consent e as
  /// áreas de banner somem da UI (usado durante a suspensão do AdMob de
  /// jul-ago/2026, reativada em 2026-08-13).
  static const bool adsSuspended = false;

  static bool get adsEnabled => activeAdsMode != AdsMode.off;

  static AdsMode get activeAdsMode {
    if (adsSuspended) {
      return AdsMode.off;
    }
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
        // accidentally shipping test ads - which never generate revenue.
        return kReleaseMode ? AdsMode.real : AdsMode.test;
    }
  }
}

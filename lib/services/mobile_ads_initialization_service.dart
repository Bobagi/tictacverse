import 'package:google_mobile_ads/google_mobile_ads.dart';

class MobileAdsInitializationService {
  bool _hasInitialized = false;

  Future<void> initialize() async {
    if (_hasInitialized) {
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _hasInitialized = true;
    } catch (_) {
      _hasInitialized = false;
    }
  }
}

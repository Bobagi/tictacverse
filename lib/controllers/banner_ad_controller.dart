import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_unit_id_provider.dart';

class BannerAdController {
  BannerAd? _bannerAd;
  bool _isLoading = false;
  AdSize _activeAdSize = AdSize.mediumRectangle;
  String _activeAdUnitId = '';

  double get expectedAdHeight => _activeAdSize.height.toDouble();

  Future<void> loadBannerAd({
    required BuildContext context,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailed,
  }) async {
    if (_bannerAd != null || _isLoading) {
      return;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool shouldUseMediumRectangle = screenWidth >= 380;

    final AdSize nextAdSize =
        shouldUseMediumRectangle ? AdSize.mediumRectangle : AdSize.banner;
    final String nextAdUnitId = shouldUseMediumRectangle
        ? AdUnitIdProvider.getMediumRectangleAdUnitId()
        : AdUnitIdProvider.getBannerAdUnitId();

    if (nextAdUnitId.isEmpty) {
      return;
    }

    _activeAdSize = nextAdSize;
    _activeAdUnitId = nextAdUnitId;
    _isLoading = true;

    final BannerAd bannerAd = BannerAd(
      adUnitId: _activeAdUnitId,
      size: _activeAdSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          _bannerAd = ad as BannerAd;
          _isLoading = false;
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          _bannerAd = null;
          _isLoading = false;
          onAdFailed?.call();
        },
      ),
    );

    bannerAd.load();
  }

  Widget buildBannerAdWidget({double? reservedHeight}) {
    final double adHeight = reservedHeight ?? expectedAdHeight;

    final Widget adWidget = _bannerAd == null
        ? SizedBox(
            width: _activeAdSize.width.toDouble(),
            height: _activeAdSize.height.toDouble(),
          )
        : SizedBox(
            width: _activeAdSize.width.toDouble(),
            height: _activeAdSize.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          );

    return SizedBox(
      height: adHeight,
      width: double.infinity,
      child: Center(child: adWidget),
    );
  }

  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
}

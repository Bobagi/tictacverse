import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_unit_id_provider.dart';

class BannerAdController {
  BannerAd? _bannerAd;
  bool _isLoading = false;

  void loadBannerAd({VoidCallback? onAdLoaded, VoidCallback? onAdFailed}) {
    if (_bannerAd != null || _isLoading) {
      return;
    }
    final String adUnitId = AdUnitIdProvider.getBannerAdUnitId();
    if (adUnitId.isEmpty) {
      return;
    }
    _isLoading = true;
    final BannerAd banner = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
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
    banner.load();
  }

  Widget buildBannerAdWidget() {
    if (_bannerAd == null) {
      return const SizedBox(
        height: 50,
        width: 320,
      );
    }
    return SizedBox(
      height: _bannerAd!.size.height.toDouble(),
      width: _bannerAd!.size.width.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
}

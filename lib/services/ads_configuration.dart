enum AdsMode { off, test, real }

class AdsConfiguration {
  static const String _adsModeDefineKey = 'ADS_MODE';

  static AdsMode get activeAdsMode {
    const String adsModeValue = String.fromEnvironment(
      _adsModeDefineKey,
      defaultValue: 'test',
    );
    switch (adsModeValue.toLowerCase()) {
      case 'off':
        return AdsMode.off;
      case 'real':
        return AdsMode.real;
      case 'test':
      default:
        return AdsMode.test;
    }
  }
}

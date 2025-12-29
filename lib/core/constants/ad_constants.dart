import 'dart:io';

/// Constants for AdMob ad units
/// Currently using Google's test ad unit IDs for safe testing
class AdConstants {
  AdConstants._();

  // Banner Ad Unit IDs
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Test banner ad unit for Android
      return 'ca-app-pub-3940256099942544/6300978111';
      // Production: Replace with your real ad unit ID
      // return 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_AD_UNIT_ID';
    } else if (Platform.isIOS) {
      // Test banner ad unit for iOS
      return 'ca-app-pub-3940256099942544/2934735716';
      // Production: Replace with your real ad unit ID
      // return 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_AD_UNIT_ID';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Ad refresh intervals (optional - for future use)
  static const int bannerRefreshSeconds = 60;

  // Whether ads are enabled
  static const bool adsEnabled = true;
}

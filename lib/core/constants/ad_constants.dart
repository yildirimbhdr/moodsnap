import 'dart:io';

/// Constants for AdMob ad units
/// Currently using Google's test ad unit IDs for safe testing
class AdConstants {
  AdConstants._();

  // Banner Ad Unit IDs
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Test banner ad unit for Android
      return 'ca-app-pub-7806268665482970/9944903589';
      // Production: Replace with your real ad unit ID
      // return 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_AD_UNIT_ID';
    } else if (Platform.isIOS) {
      // Test banner ad unit for iOS
      return 'ca-app-pub-7806268665482970/8133467776';
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

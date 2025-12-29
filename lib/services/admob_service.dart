import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/result.dart';
import '../core/constants/ad_constants.dart';

/// Service for managing AdMob advertisements
/// Follows the same singleton pattern as NotificationService and AchievementService
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  bool _initialized = false;

  /// Initialize AdMob SDK
  Future<Result<void>> init() async {
    try {
      if (_initialized) {
        return const Success(null);
      }

      if (!AdConstants.adsEnabled) {
        if (kDebugMode) {
          print('📱 AdMob: Ads are disabled in constants');
        }
        return const Success(null);
      }

      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();

      // Optional: Set request configuration for test devices
      if (kDebugMode) {
        final RequestConfiguration requestConfiguration = RequestConfiguration(
          testDeviceIds: ['TEST_DEVICE_ID'], // Add your test device ID here
        );
        MobileAds.instance.updateRequestConfiguration(requestConfiguration);
      }

      _initialized = true;

      if (kDebugMode) {
        print('📱 AdMob: Successfully initialized');
      }

      return const Success(null);
    } catch (e) {
      if (kDebugMode) {
        print('📱 AdMob: Initialization error: $e');
      }
      return Failure(AppError(
        type: ErrorType.unknown,
        message: 'Failed to initialize AdMob',
        originalError: e,
      ));
    }
  }

  /// Create a banner ad
  /// This method creates and returns a configured BannerAd instance
  BannerAd createBannerAd({
    required void Function() onAdLoaded,
    required void Function(LoadAdError error) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: AdConstants.bannerAdUnitId,
      size: AdSize.banner, // 320x50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            print('📱 AdMob: Banner ad loaded');
          }
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            print('📱 AdMob: Banner ad failed to load: $error');
          }
          ad.dispose();
          onAdFailedToLoad(error);
        },
        onAdOpened: (ad) {
          if (kDebugMode) {
            print('📱 AdMob: Banner ad opened');
          }
        },
        onAdClosed: (ad) {
          if (kDebugMode) {
            print('📱 AdMob: Banner ad closed');
          }
        },
      ),
    );
  }

  /// Check if AdMob is initialized and ready
  bool get isInitialized => _initialized;

  /// Check if ads are enabled
  bool get areAdsEnabled => AdConstants.adsEnabled;
}

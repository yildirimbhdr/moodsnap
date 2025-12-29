import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../main.dart';

/// Banner ad widget for Calendar screen
/// Manages ad lifecycle and displays banner ad at bottom of calendar
class CalendarBannerAd extends ConsumerStatefulWidget {
  const CalendarBannerAd({super.key});

  @override
  ConsumerState<CalendarBannerAd> createState() => _CalendarBannerAdState();
}

class _CalendarBannerAdState extends ConsumerState<CalendarBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adMobService = ref.read(adMobServiceProvider);

    // Only load ad if service is initialized and ads are enabled
    if (!adMobService.isInitialized || !adMobService.areAdsEnabled) {
      return;
    }

    _bannerAd = adMobService.createBannerAd(
      onAdLoaded: () {
        setState(() {
          _isAdLoaded = true;
        });
      },
      onAdFailedToLoad: (error) {
        setState(() {
          _isAdLoaded = false;
        });
      },
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If ad is not loaded, return empty container (no space taken)
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    // Return ad widget with proper sizing
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

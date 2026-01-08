import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodysnap/firebase_options.dart';
import 'package:moodysnap/services/storage/storage_service.dart';
import 'package:moodysnap/services/achievement_service.dart';
import 'package:moodysnap/services/custom_mood_service.dart';
import 'package:moodysnap/services/notification_service.dart';
import 'package:moodysnap/services/admob_service.dart';
import 'package:moodysnap/services/analytics_service.dart';
import 'package:moodysnap/core/utils/result.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  final storageService = StorageService();
  final storageResult = await storageService.init();
  if (storageResult.isFailure) {
    // Critical error - cannot continue without storage
    throw storageResult.errorOrNull!;
  }

  final achievementService = AchievementService();
  await achievementService.init();

  final customMoodService = CustomMoodService();
  await customMoodService.init();

  // Initialize notification service
  final notificationService = NotificationService();
  notificationService.setStorageService(storageService); // Set storage for localization
  await notificationService.init();

  // Initialize AdMob service
  final adMobService = AdMobService();
  await adMobService.init();

  // Initialize Analytics service
  final analyticsService = AnalyticsService();
  await analyticsService.init();

  // Schedule daily reminder if enabled AND onboarding is complete
  // (Don't schedule on first launch - onboarding will handle it)
  if (storageService.isOnboardingComplete() && storageService.areNotificationsEnabled()) {
    final hour = storageService.getNotificationHour();
    final minute = storageService.getNotificationMinute();
    await notificationService.scheduleDailyReminder(hour, minute);
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        achievementServiceProvider.overrideWithValue(achievementService),
        customMoodServiceProvider.overrideWithValue(customMoodService),
        notificationServiceProvider.overrideWithValue(notificationService),
        adMobServiceProvider.overrideWithValue(adMobService),
        analyticsServiceProvider.overrideWithValue(analyticsService),
      ],
      child: const MoodSnapApp(),
    ),
  );
}

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden');
});

final achievementServiceProvider = Provider<AchievementService>((ref) {
  throw UnimplementedError('AchievementService must be overridden');
});

final customMoodServiceProvider = Provider<CustomMoodService>((ref) {
  throw UnimplementedError('CustomMoodService must be overridden');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('NotificationService must be overridden');
});

final adMobServiceProvider = Provider<AdMobService>((ref) {
  throw UnimplementedError('AdMobService must be overridden');
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  throw UnimplementedError('AnalyticsService must be overridden');
});
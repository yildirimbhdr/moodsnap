import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodysnap/firebase_options.dart';
import 'package:moodysnap/services/storage/storage_service.dart';
import 'package:moodysnap/services/achievement_service.dart';
import 'package:moodysnap/services/custom_mood_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  final storageService = StorageService();
  await storageService.init();

  final achievementService = AchievementService();
  await achievementService.init();

  final customMoodService = CustomMoodService();
  await customMoodService.init();

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
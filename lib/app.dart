import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/main/main_container.dart';
import 'main.dart';

class MoodSnapApp extends ConsumerWidget {
  const MoodSnapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageService = ref.watch(storageServiceProvider);
    final languageCode = storageService.getLanguage();

    return MaterialApp(
      title: 'MoodSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: Locale(languageCode),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: storageService.isOnboardingComplete()
          ? const MainContainer()
          : const OnboardingScreen(),
    );
  }
}

// Language Provider
final languageProvider = StateProvider<String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getLanguage();
});
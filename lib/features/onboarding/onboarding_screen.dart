import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodysnap/features/main/main_container.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';
import '../../core/utils/result.dart';
import '../../main.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    HapticUtils.lightImpact();
  }

  void _skipOnboarding() {
    final storage = ref.read(storageServiceProvider);
    storage.setOnboardingComplete();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainContainer()),
    );
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _skipOnboarding();
    }
  }

  Future<void> _requestNotificationPermission() async {
    final notificationService = ref.read(notificationServiceProvider);
    final storage = ref.read(storageServiceProvider);

    // Request permission
    final permissionResult = await notificationService.requestPermissions();

    if (permissionResult.dataOrNull == true) {
      // Permission granted - enable notifications and schedule
      storage.setNotificationsEnabled(true);
      final hour = storage.getNotificationHour();
      final minute = storage.getNotificationMinute();
      await notificationService.scheduleDailyReminder(hour, minute);
    } else {
      // Permission denied - disable notifications
      storage.setNotificationsEnabled(false);
    }

    // Go to next page
    _nextPage();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    l10n.skip,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            
            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildPage(
                    emoji: '😊',
                    title: l10n.onboarding1Title,
                    description: l10n.onboarding1Desc,
                  ),
                  _buildPage(
                    emoji: '📅',
                    title: l10n.onboarding2Title,
                    description: l10n.onboarding2Desc,
                  ),
                  _buildPage(
                    emoji: '📊',
                    title: l10n.onboarding3Title,
                    description: l10n.onboarding3Desc,
                  ),
                  _buildNotificationPage(),
                ],
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.textHint,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Next/Start button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _currentPage == 3 ? _requestNotificationPermission : _nextPage,
                  child: Text(
                    _currentPage == 3
                        ? l10n.enableNotifications
                        : (_currentPage == 2 ? l10n.next : l10n.next),
                  ),
                ),
              ),
            ),

            // Skip notifications button (only on notification page)
            if (_currentPage == 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    l10n.skipForNow,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String emoji,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 120),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPage() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🔔',
            style: TextStyle(fontSize: 120),
          ),
          const SizedBox(height: 48),
          Text(
            l10n.onboarding4Title,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboarding4Desc,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
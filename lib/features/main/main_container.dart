import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodysnap/features/home/home_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../main.dart';
import '../calendar/calendar_screen.dart';
import '../settings/settings_screen.dart';

class MainContainer extends ConsumerStatefulWidget {
  const MainContainer({super.key});

  @override
  ConsumerState<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends ConsumerState<MainContainer> {
  int _currentIndex = 0;
  bool _hasCheckedPermission = false;

  @override
  void initState() {
    super.initState();
    // Check notification permission after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermission();
    });
  }

  Future<void> _checkNotificationPermission() async {
    if (_hasCheckedPermission) return;
    _hasCheckedPermission = true;

    final storage = ref.read(storageServiceProvider);
    final notificationService = ref.read(notificationServiceProvider);

    // Check if notifications are enabled in settings
    final notificationsEnabled = storage.areNotificationsEnabled();

    if (notificationsEnabled) {
      // Check actual system permission
      final hasPermission = await notificationService.areNotificationsEnabled();

      if (!hasPermission && mounted) {
        // Permission not granted but user wants notifications
        // Show dialog to request permission
        _showNotificationPermissionDialog();
      }
    }
  }

  Future<void> _showNotificationPermissionDialog() async {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.notifPermissionTitle),
        content: Text(l10n.onboarding4Desc),
        actions: [
          TextButton(
            onPressed: () {
              final storage = ref.read(storageServiceProvider);
              storage.setNotificationsEnabled(false);
              Navigator.pop(context);
            },
            child: Text(l10n.notifPermissionNo),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final notificationService = ref.read(notificationServiceProvider);
              final storage = ref.read(storageServiceProvider);

              final permissionResult = await notificationService.requestPermissions();

              if (permissionResult.dataOrNull == true) {
                // Permission granted - schedule notification
                final hour = storage.getNotificationHour();
                final minute = storage.getNotificationMinute();
                await notificationService.scheduleDailyReminder(hour, minute);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.notificationEnabled.replaceAll('{title}', l10n.dailyMoodReminder)),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } else {
                // Permission denied
                storage.setNotificationsEnabled(false);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.notificationPermissionDenied),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.notifPermissionYes),
          ),
        ],
      ),
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const CalendarScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: _getCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  activeIcon: Icons.home_rounded,
                  label: l10n.today,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  label: l10n.calendar,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: l10n.settings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.08),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
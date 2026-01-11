import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodysnap/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../core/utils/battery_optimization_helper.dart';
import '../../main.dart';
import '../../app.dart';
import '../achievements/achievements_screen.dart';
import '../custom_moods/custom_moods_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _systemNotificationPermission;

  @override
  void initState() {
    super.initState();
    _checkSystemPermission();
  }

  Future<void> _checkSystemPermission() async {
    final notificationService = ref.read(notificationServiceProvider);
    final hasPermission = await notificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _systemNotificationPermission = hasPermission;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final currentLanguage = storage.getLanguage();
    final userName = storage.getUserName();
    final notificationsEnabled = storage.areNotificationsEnabled();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:  Text(
          l10n.settings,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: l10n.settings,
            children: [
              _buildListTile(
                icon: Icons.person_outline,
                title: l10n.nameInputTitle,
                subtitle: userName ?? l10n.touchToChange,
                onTap: () => _showNameDialog(context,l10n),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Language Section
          _buildSection(
            title: l10n.language,
            children: [
              _buildListTile(
                icon: Icons.language,
                title: l10n.language,
                subtitle: _getLanguageName(currentLanguage),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context,l10n),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Notifications Section
          _buildSection(
            title: l10n.notifications,
            children: [
              // Show warning if system permission is denied
              if (_systemNotificationPermission == false && !notificationsEnabled)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.notificationPermissionDenied,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: l10n.dailyMoodReminder,
                subtitle: _systemNotificationPermission == false && !notificationsEnabled
                    ? l10n.notificationPermissionDenied
                    : l10n.everyDayNotificationSequence.replaceAll("{hour}", "${storage.getNotificationHour().toString().padLeft(2, '0')}:${storage.getNotificationMinute().toString().padLeft(2, '0')}"),
                value: notificationsEnabled,
                onChanged: (value) async {
                  if (value) {
                    // Request permission first
                    final notificationService = ref.read(notificationServiceProvider);
                    final permissionResult = await notificationService.requestPermissions();

                    if (permissionResult.dataOrNull == true) {
                      storage.setNotificationsEnabled(true);
                      final hour = storage.getNotificationHour();
                      final minute = storage.getNotificationMinute();
                      final scheduleResult = await notificationService.scheduleDailyReminder(hour, minute);

                      // Update system permission state
                      _systemNotificationPermission = true;

                      if (mounted) {
                        if (scheduleResult.isSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.notificationEnabled.replaceAll('{title}', l10n.dailyMoodReminder)),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('HATA: ${scheduleResult.errorOrNull?.message ?? "Bilinmeyen hata"}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                          storage.setNotificationsEnabled(false);
                        }
                      }
                    } else {
                      // Permission denied
                      _systemNotificationPermission = false;

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.notificationPermissionDenied),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } else {
                    // Disable notifications
                    final notificationService = ref.read(notificationServiceProvider);
                    await notificationService.cancelDailyReminder();
                    storage.setNotificationsEnabled(false);
                  }
                  setState(() {});
                },
              ),
              if (notificationsEnabled) ...[
                _buildListTile(
                  icon: Icons.access_time,
                  title: l10n.notificationTime,
                  subtitle: '${storage.getNotificationHour().toString().padLeft(2, '0')}:${storage.getNotificationMinute().toString().padLeft(2, '0')}',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showNotificationTimePicker(context, l10n),
                ),
             
                _buildListTile(
                  icon: Icons.help_outline,
                  title: l10n.notificationsNotWorking,
                  subtitle: l10n.batteryOptimizationSettings,
                  onTap: () => BatteryOptimizationHelper.showBatteryOptimizationGuide(context),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Achievements SectionP
          _buildSection(
            title: l10n.achievements,
            children: [
              _buildListTile(
                icon: Icons.emoji_events,
                title: l10n.achievements,
                subtitle: l10n.achievementsUnlocked,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AchievementsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Custom Moods Section
          _buildSection(
            title: l10n.customMoods,
            children: [
              _buildListTile(
                icon: Icons.palette_outlined,
                title: l10n.customMoods,
                subtitle: l10n.manageYourMoods,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomMoodsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Section
          _buildSection(
            title: l10n.stats,
            children: [
              _buildListTile(
                icon: Icons.show_chart,
                title: l10n.streak,
                subtitle: '${storage.getCurrentStreak()} ${l10n.days}',
              ),
              _buildListTile(
                icon: Icons.emoji_events_outlined,
                title: l10n.longestStreak,
                subtitle: '${storage.getLongestStreak()} ${l10n.days}',
              ),
              _buildListTile(
                icon: Icons.calendar_today,
                title: l10n.totalEntries, 
                subtitle: '${storage.getAllMoodEntries().length} ${l10n.days}',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Danger Zone
          _buildSection(
            title: l10n.dangerZone,
            children: [
              _buildListTile(
                icon: Icons.delete_forever_outlined,
                title: l10n.deleteAllData,
                subtitle: l10n.deleteAllDataWarning,
                titleColor: Colors.red,
                onTap: () => _showDeleteAllDialog(context,l10n),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Center(
            child: Column(
              children: [
                Text(
                  l10n.appName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Version 0.1.0',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: titleColor),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'tr':
        return 'Türkçe 🇹🇷';
      case 'en':
        return 'English 🇺🇸';
      case 'de':
        return 'Deutsch 🇩🇪';
      default:
        return 'Türkçe 🇹🇷';
    }
  }

  void _showNameDialog(BuildContext context , l10n) {
    final storage = ref.read(storageServiceProvider);
    final controller = TextEditingController(text: storage.getUserName());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text(l10n.name),
        content: TextField(
          controller: controller,
          decoration:  InputDecoration(hintText: l10n.nameInputHint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              storage.setUserName(controller.text);
              Navigator.pop(context);
              setState(() {});
            },
            child:  Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context,l10n) {
    final storage = ref.read(storageServiceProvider);
    final currentLanguage = storage.getLanguage();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Türkçe 🇹🇷'),
              value: 'tr',
              groupValue: currentLanguage,
              onChanged: (value) {
                storage.setLanguage(value!);
                ref.read(languageProvider.notifier).state = value;
                Navigator.pop(context);
                setState(() {});
              },
            ),
            RadioListTile<String>(
              title: const Text('English 🇺🇸'),
              value: 'en',
              groupValue: currentLanguage,
              onChanged: (value) {
                storage.setLanguage(value!);
                ref.read(languageProvider.notifier).state = value;
                Navigator.pop(context);
                setState(() {});
              },
            ),
            RadioListTile<String>(
              title: const Text('Deutsch 🇩🇪'),
              value: 'de',
              groupValue: currentLanguage,
              onChanged: (value) {
                storage.setLanguage(value!);
                ref.read(languageProvider.notifier).state = value;
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationTimePicker(BuildContext context, l10n) async {
    // Check if permission is granted first
    if (_systemNotificationPermission == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce bildirim izni vermelisiniz!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final storage = ref.read(storageServiceProvider);
    final currentHour = storage.getNotificationHour();
    final currentMinute = storage.getNotificationMinute();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.cardBackground,
              hourMinuteColor: AppColors.primary.withOpacity(0.1),
              hourMinuteTextColor: AppColors.primary,
              dayPeriodColor: AppColors.primary.withOpacity(0.2),
              dayPeriodTextColor: AppColors.primary,
              dialHandColor: AppColors.primary,
              dialBackgroundColor: AppColors.primary.withOpacity(0.1),
              entryModeIconColor: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && (picked.hour != currentHour || picked.minute != currentMinute)) {
      // IMPORTANT: await storage write before updating UI
      await storage.setNotificationTime(picked.hour, picked.minute);

      // Reschedule notification with new time
      if (storage.areNotificationsEnabled()) {
        final notificationService = ref.read(notificationServiceProvider);
        final result = await notificationService.scheduleDailyReminder(picked.hour, picked.minute);

        if (context.mounted) {
          final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

          if (result.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.notificationTimeSet.replaceAll('{time}', timeStr)),
                backgroundColor: AppColors.primary,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('HATA: ${result.errorOrNull?.message ?? "Bilinmeyen hata"}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }

      setState(() {});
    }
  }

  void _showDeleteAllDialog(BuildContext context,l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAllData),
        content: Text(
          l10n.deleteAllDataConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final storage = ref.read(storageServiceProvider);
              await storage.clearAllData();
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

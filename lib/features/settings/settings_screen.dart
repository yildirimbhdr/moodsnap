import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodysnap/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../main.dart';
import '../../app.dart';
import '../achievements/achievements_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: l10n.dailyMoodReminder,
                subtitle: l10n.everyDayNotificationSequence.replaceAll("{hour}", "21:00"),
                value: notificationsEnabled,
                onChanged: (value) {
                  storage.setNotificationsEnabled(value);
                  setState(() {});
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Achievements Section
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

          const Center(
            child: Column(
              children: [
                Text(
                  'MoodSnap',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
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

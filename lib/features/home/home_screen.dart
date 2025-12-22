// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodie/features/moon_entry/mood_entry_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/emoji_constants.dart';
import '../../data/models/mood_entry.dart';
import '../../main.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _MoodEntryScreenState();
}

class _MoodEntryScreenState extends ConsumerState<HomeScreen> {
  late final storage;
  late final userName;
  late final streak;
  MoodEntry? todayEntry;
  @override
  void initState() {
    super.initState();
    storage = ref.read(storageServiceProvider);
    userName = storage.getUserName();
    streak = storage.getCurrentStreak();
    todayEntry = storage.getTodayMood();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background, // Temanıza göre
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title(userName,l10n),
              const SizedBox(height: 24),
              currentMoodCart(l10n),
              const SizedBox(height: 32),
              Row(
                children: [
                  _buildMiniStatCard(l10n.streak, "🔥 $streak ${l10n.day}", Colors.orange),
                  const SizedBox(width: 16),
                  _buildMiniStatCard(l10n.rank, "⭐ Top %10", Colors.purple),
                ],
              ),
              const SizedBox(height: 32),
              _lastEntriesSection(l10n),
            ],
          ),
        ),
      ),
    );
  }
  Widget _lastEntriesSection(l10n) {
    final List<MoodEntry> recentEntries = storage.getRecentMoodEntries(3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentEntries,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Column(
          children: recentEntries.map((MoodEntry entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Text(
                  EmojiConstants.moods[entry.mood] ?? '✨',
                  style: const TextStyle(fontSize: 30),
                ),
                title: Text(
                  entry.mood,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  (entry.note?.isNotEmpty ?? false) ? entry.note : l10n.noDetails,
                ),
                trailing: Text(
                  "${entry.date.day}/${entry.date.month}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget currentMoodCart(l10n) => GestureDetector(
    onTap: () async {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MoodEntryScreen()),
      ).then((_) {
        setState(() {
          final entry = storage.getTodayMood();
          if (entry != null) {
            todayEntry = entry;
          }
        });
      });
    },

    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.6),AppColors.primary.withOpacity(0.6), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Text(
                EmojiConstants.moods[todayEntry?.mood] ?? '✨',
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.todayMoodIs.replaceAll(
                  '{mood}',
                  todayEntry?.mood,
                ), // l10n dosyana eklemelisin
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.touchToChange,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const Positioned(
            right: 0,
            top: 0,
            child: Icon(Icons.edit, color: Colors.white, size: 20),
          ),
        ],
      ),
    ),
  );

  Widget title(userName,ln10) => Text(
    userName != null
        ? ln10.youLookGreat + ", $userName!"
        : ln10.youLookGreat,
    style: Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
  );
}

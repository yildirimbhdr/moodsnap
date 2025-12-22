import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/mood_entry.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/emoji_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';

class DayDetailSheet extends ConsumerWidget {
  final MoodEntry entry;

  const DayDetailSheet({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final monthNames = [
      l10n.january, l10n.february, l10n.march, l10n.april,
      l10n.may, l10n.june, l10n.july, l10n.august,
      l10n.september, l10n.october, l10n.november, l10n.december,
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Date
          Text(
            '${entry.date.day} ${monthNames[entry.date.month - 1]} ${entry.date.year}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          
          const SizedBox(height: 24),
          
          // Emoji
          Text(
            EmojiConstants.getEmoji(entry.mood),
            style: const TextStyle(fontSize: 80),
          ),
          
          const SizedBox(height: 16),
          
          // Mood label
          Text(
            _getMoodLabel(entry.mood, l10n),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          
          if (entry.note != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry.note!,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          Image.file(File(entry.photoPath!), height: 50),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteDialog(context, ref);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.delete),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Edit functionality (FAZ 2)
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.edit),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _getMoodLabel(String mood, AppLocalizations l10n) {
    switch (mood) {
      case 'happy':
        return l10n.moodHappy;
      case 'sad':
        return l10n.moodSad;
      case 'angry':
        return l10n.moodAngry;
      case 'anxious':
        return l10n.moodAnxious;
      case 'tired':
        return l10n.moodTired;
      case 'neutral':
      default:
        return l10n.moodNeutral;
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: const Text('Bu günü silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final storage = ref.read(storageServiceProvider);
              await storage.deleteMoodEntry(entry.dateKey);
              if (context.mounted) {
                Navigator.pop(context);
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
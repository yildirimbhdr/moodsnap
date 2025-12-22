import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/custom_mood_service.dart';

class EmojiConstants {
  static const Map<String, String> moods = {
    'happy': '😊',
    'neutral': '😐',
    'sad': '😔',
    'angry': '😡',
    'anxious': '😰',
    'tired': '😴',
  };

  static const Map<String, String> moodLabels = {
    'happy': 'mood_happy',
    'neutral': 'mood_neutral',
    'sad': 'mood_sad',
    'angry': 'mood_angry',
    'anxious': 'mood_anxious',
    'tired': 'mood_tired',
  };

  /// Get emoji for a mood (supports both default and custom moods)
  /// If customMoodService is provided, it will check custom moods first
  static String getEmoji(String mood, {CustomMoodService? customMoodService}) {
    if (customMoodService != null) {
      return customMoodService.getMoodEmoji(mood);
    }
    return moods[mood] ?? '✨';
  }

  static String getLabel(String mood) => moodLabels[mood] ?? 'mood_neutral';

  /// Get localized mood name (supports both default and custom moods)
  /// If customMoodService is provided, it will check custom moods first
  static String getLocalizedMood(String mood, AppLocalizations l10n, {CustomMoodService? customMoodService}) {
    if (customMoodService != null) {
      return customMoodService.getMoodName(mood);
    }

    switch (mood) {
      case 'happy':
        return l10n.moodHappy;
      case 'neutral':
        return l10n.moodNeutral;
      case 'sad':
        return l10n.moodSad;
      case 'angry':
        return l10n.moodAngry;
      case 'anxious':
        return l10n.moodAnxious;
      case 'tired':
        return l10n.moodTired;
      default:
        return mood;
    }
  }

  /// Get mood color (supports both default and custom moods)
  /// If customMoodService is provided, it will use custom mood colors
  static Color getMoodColor(String mood, {CustomMoodService? customMoodService}) {
    if (customMoodService != null) {
      return customMoodService.getMoodColor(mood);
    }

    // Fallback to default colors (these should match AppColors)
    switch (mood) {
      case 'happy':
        return const Color(0xFF4CAF50);
      case 'sad':
        return const Color(0xFF2196F3);
      case 'angry':
        return const Color(0xFFF44336);
      case 'anxious':
        return const Color(0xFFFF9800);
      case 'tired':
        return const Color(0xFF9C27B0);
      case 'neutral':
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class TagConstants {
  static const String work = 'work';
  static const String family = 'family';
  static const String health = 'health';
  static const String weather = 'weather';
  static const String sleep = 'sleep';
  static const String social = 'social';
  static const String exercise = 'exercise';
  static const String food = 'food';
  static const String relationship = 'relationship';
  static const String money = 'money';

  static List<String> get all => [
        work,
        family,
        health,
        weather,
        sleep,
        social,
        exercise,
        food,
        relationship,
        money,
      ];

  static String getLocalizedTag(String tag, AppLocalizations l10n) {
    switch (tag) {
      case work:
        return l10n.tagWork;
      case family:
        return l10n.tagFamily;
      case health:
        return l10n.tagHealth;
      case weather:
        return l10n.tagWeather;
      case sleep:
        return l10n.tagSleep;
      case social:
        return l10n.tagSocial;
      case exercise:
        return l10n.tagExercise;
      case food:
        return l10n.tagFood;
      case relationship:
        return l10n.tagRelationship;
      case money:
        return l10n.tagMoney;
      default:
        return tag;
    }
  }

  static IconData getTagIcon(String tag) {
    switch (tag) {
      case work:
        return Icons.work_outline;
      case family:
        return Icons.family_restroom;
      case health:
        return Icons.favorite_outline;
      case weather:
        return Icons.wb_sunny_outlined;
      case sleep:
        return Icons.bedtime_outlined;
      case social:
        return Icons.people_outline;
      case exercise:
        return Icons.fitness_center_outlined;
      case food:
        return Icons.restaurant_outlined;
      case relationship:
        return Icons.favorite_border;
      case money:
        return Icons.attach_money;
      default:
        return Icons.tag;
    }
  }

  static Color getTagColor(String tag) {
    switch (tag) {
      case work:
        return const Color(0xFF6366F1); // Indigo
      case family:
        return const Color(0xFFEC4899); // Pink
      case health:
        return const Color(0xFFEF4444); // Red
      case weather:
        return const Color(0xFFF59E0B); // Amber
      case sleep:
        return const Color(0xFF8B5CF6); // Purple
      case social:
        return const Color(0xFF10B981); // Emerald
      case exercise:
        return const Color(0xFF06B6D4); // Cyan
      case food:
        return const Color(0xFFF97316); // Orange
      case relationship:
        return const Color(0xFFEC4899); // Pink
      case money:
        return const Color(0xFF22C55E); // Green
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  static String getTagEmoji(String tag) {
    switch (tag) {
      case work:
        return '💼';
      case family:
        return '👨‍👩‍👧‍👦';
      case health:
        return '❤️';
      case weather:
        return '☀️';
      case sleep:
        return '😴';
      case social:
        return '👥';
      case exercise:
        return '💪';
      case food:
        return '🍽️';
      case relationship:
        return '💕';
      case money:
        return '💰';
      default:
        return '🏷️';
    }
  }
}

import 'package:hive/hive.dart';
import '../data/models/achievement.dart';
import '../data/models/mood_entry.dart';

class AchievementService {
  static const String _boxName = 'achievements';
  late Box<Achievement> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Achievement>(_boxName);
    await _initializeAchievements();
  }

  // Initialize default achievements
  Future<void> _initializeAchievements() async {
    if (_box.isEmpty) {
      final achievements = [
        Achievement(
          id: 'first_step',
          title: 'İlk Adım',
          description: 'İlk mood\'unu ekledin!',
          emoji: '👣',
          type: AchievementType.firstEntry,
          targetValue: 1,
        ),
        Achievement(
          id: 'streak_7',
          title: 'Başlangıç Yıldızı',
          description: '7 gün üst üste mood kaydı',
          emoji: '🌟',
          type: AchievementType.streak,
          targetValue: 7,
        ),
        Achievement(
          id: 'streak_30',
          title: 'Ay Ustası',
          description: '30 gün üst üste mood kaydı',
          emoji: '🌙',
          type: AchievementType.streak,
          targetValue: 30,
        ),
        Achievement(
          id: 'streak_100',
          title: 'Efsane',
          description: '100 gün üst üste mood kaydı',
          emoji: '👑',
          type: AchievementType.streak,
          targetValue: 100,
        ),
        Achievement(
          id: 'photo_10',
          title: 'Fotoğrafçı',
          description: '10 fotoğraflı mood kaydı',
          emoji: '📸',
          type: AchievementType.photoEntries,
          targetValue: 10,
        ),
      ];

      for (var achievement in achievements) {
        await _box.put(achievement.id, achievement);
      }
    }
  }

  // Get all achievements
  List<Achievement> getAllAchievements() {
    return _box.values.toList()..sort((a, b) {
        // Unlocked ones first, then by target value
        if (a.isUnlocked != b.isUnlocked) {
          return b.isUnlocked ? 1 : -1;
        }
        return a.targetValue.compareTo(b.targetValue);
      });
  }

  // Get unlocked achievements
  List<Achievement> getUnlockedAchievements() {
    return _box.values.where((a) => a.isUnlocked).toList();
  }

  // Check and unlock achievements
  Future<List<Achievement>> checkAchievements({
    required List<MoodEntry> allEntries,
    required int currentStreak,
  }) async {
    final newlyUnlocked = <Achievement>[];

    for (var achievement in _box.values) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;

      switch (achievement.type) {
        case AchievementType.firstEntry:
          shouldUnlock = allEntries.isNotEmpty;
          break;

        case AchievementType.streak:
          shouldUnlock = currentStreak >= achievement.targetValue;
          break;

        case AchievementType.photoEntries:
          final photoCount = allEntries
              .where((e) => e.photoPath != null && e.photoPath!.isNotEmpty)
              .length;
          shouldUnlock = photoCount >= achievement.targetValue;
          break;

        case AchievementType.totalEntries:
          shouldUnlock = allEntries.length >= achievement.targetValue;
          break;
      }

      if (shouldUnlock) {
        final unlocked = achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        await _box.put(achievement.id, unlocked);
        newlyUnlocked.add(unlocked);
      }
    }

    return newlyUnlocked;
  }

  // Get progress for an achievement
  double getProgress(Achievement achievement, {
    required List<MoodEntry> allEntries,
    required int currentStreak,
  }) {
    int currentValue = 0;

    switch (achievement.type) {
      case AchievementType.firstEntry:
        currentValue = allEntries.isEmpty ? 0 : 1;
        break;

      case AchievementType.streak:
        currentValue = currentStreak;
        break;

      case AchievementType.photoEntries:
        currentValue = allEntries
            .where((e) => e.photoPath != null && e.photoPath!.isNotEmpty)
            .length;
        break;

      case AchievementType.totalEntries:
        currentValue = allEntries.length;
        break;
    }

    return (currentValue / achievement.targetValue).clamp(0.0, 1.0);
  }
}

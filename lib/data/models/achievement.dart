import 'package:hive/hive.dart';

part 'achievement.g.dart';

@HiveType(typeId: 1)
class Achievement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String emoji;

  @HiveField(4)
  final AchievementType type;

  @HiveField(5)
  final int targetValue;

  @HiveField(6)
  final bool isUnlocked;

  @HiveField(7)
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.targetValue,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      emoji: emoji,
      type: type,
      targetValue: targetValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

@HiveType(typeId: 2)
enum AchievementType {
  @HiveField(0)
  streak,

  @HiveField(1)
  firstEntry,

  @HiveField(2)
  photoEntries,

  @HiveField(3)
  totalEntries,
}

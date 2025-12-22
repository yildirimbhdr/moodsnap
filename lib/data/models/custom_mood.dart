import 'package:hive/hive.dart';

part 'custom_mood.g.dart';

@HiveType(typeId: 3)
class CustomMood extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String emoji;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String colorHex;

  @HiveField(5)
  final bool isDefault;

  CustomMood({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdAt,
    required this.colorHex,
    this.isDefault = false,
  });

  // Factory constructor for easy creation
  factory CustomMood.create({
    required String name,
    required String emoji,
    required String colorHex,
  }) {
    return CustomMood(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      emoji: emoji,
      createdAt: DateTime.now(),
      colorHex: colorHex,
      isDefault: false,
    );
  }

  // Factory for default moods
  factory CustomMood.defaultMood({
    required String id,
    required String name,
    required String emoji,
    required String colorHex,
  }) {
    return CustomMood(
      id: id,
      name: name,
      emoji: emoji,
      createdAt: DateTime.now(),
      colorHex: colorHex,
      isDefault: true,
    );
  }

  // CopyWith for updates
  CustomMood copyWith({
    String? name,
    String? emoji,
    String? colorHex,
  }) {
    return CustomMood(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault,
    );
  }
}

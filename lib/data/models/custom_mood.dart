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

  CustomMood({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdAt,
  });

  factory CustomMood.create({
    required String name,
    required String emoji,
  }) {
    return CustomMood(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
  }
}

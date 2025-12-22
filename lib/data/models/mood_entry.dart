import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 0)
class MoodEntry extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final DateTime date;
  
  @HiveField(2)
  final String mood;
  
  @HiveField(3)
  final String? note;
  
  @HiveField(4)
  final String? photoPath;
  
  @HiveField(5)
  final String? audioPath;

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    this.note,
    this.photoPath,
    this.audioPath,
  });

  // Factory constructor for easy creation
  factory MoodEntry.create({
    required String mood,
    String? note,
    String? photoPath,
    String? audioPath,
  }) {
    return MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      mood: mood,
      note: note,
      photoPath: photoPath,
      audioPath: audioPath,
    );
  }

  // CopyWith for updates
  MoodEntry copyWith({
    String? mood,
    String? note,
    String? photoPath,
    String? audioPath,
  }) {
    return MoodEntry(
      id: id,
      date: date,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
      audioPath: audioPath ?? this.audioPath,
    );
  }

  // Date without time for comparison
  String get dateKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
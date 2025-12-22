import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../data/models/custom_mood.dart';

/// Service for managing custom moods
/// Follows SOLID principles and provides clean API
class CustomMoodService {
  static const String _boxName = 'custom_moods';
  late Box<CustomMood> _box;

  /// Initialize the service and register default moods
  Future<void> init() async {
    _box = await Hive.openBox<CustomMood>(_boxName);
    await _initializeDefaultMoods();
  }

  /// Initialize default moods if not already present
  Future<void> _initializeDefaultMoods() async {
    if (_box.isEmpty) {
      final defaultMoods = [
        CustomMood.defaultMood(
          id: 'happy',
          name: 'Happy',
          emoji: '😊',
          colorHex: '#4CAF50',
        ),
        CustomMood.defaultMood(
          id: 'neutral',
          name: 'Neutral',
          emoji: '😐',
          colorHex: '#9E9E9E',
        ),
        CustomMood.defaultMood(
          id: 'sad',
          name: 'Sad',
          emoji: '😔',
          colorHex: '#2196F3',
        ),
        CustomMood.defaultMood(
          id: 'angry',
          name: 'Angry',
          emoji: '😡',
          colorHex: '#F44336',
        ),
        CustomMood.defaultMood(
          id: 'anxious',
          name: 'Anxious',
          emoji: '😰',
          colorHex: '#FF9800',
        ),
        CustomMood.defaultMood(
          id: 'tired',
          name: 'Tired',
          emoji: '😴',
          colorHex: '#9C27B0',
        ),
      ];

      for (var mood in defaultMoods) {
        await _box.put(mood.id, mood);
      }
    }
  }

  /// Get all moods (default + custom)
  List<CustomMood> getAllMoods() {
    return _box.values.toList()
      ..sort((a, b) {
        // Default moods first
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        // Then by creation date
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  /// Get only custom (user-created) moods
  List<CustomMood> getCustomMoods() {
    return _box.values.where((mood) => !mood.isDefault).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get a mood by ID
  CustomMood? getMoodById(String id) {
    return _box.get(id);
  }

  /// Get mood color
  Color getMoodColor(String id) {
    final mood = getMoodById(id);
    if (mood == null) return Colors.grey;
    return Color(int.parse(mood.colorHex.replaceFirst('#', '0xFF')));
  }

  /// Get mood emoji
  String getMoodEmoji(String id) {
    final mood = getMoodById(id);
    return mood?.emoji ?? '✨';
  }

  /// Get mood name
  String getMoodName(String id) {
    final mood = getMoodById(id);
    return mood?.name ?? id;
  }

  /// Create a new custom mood
  Future<void> createMood(CustomMood mood) async {
    await _box.put(mood.id, mood);
  }

  /// Update an existing mood
  Future<void> updateMood(CustomMood mood) async {
    if (!mood.isDefault) {
      await _box.put(mood.id, mood);
    }
  }

  /// Delete a custom mood (cannot delete default moods)
  Future<bool> deleteMood(String id) async {
    final mood = _box.get(id);
    if (mood != null && !mood.isDefault) {
      await _box.delete(id);
      return true;
    }
    return false;
  }

  /// Check if mood exists
  bool moodExists(String id) {
    return _box.containsKey(id);
  }

  /// Check if emoji is already used
  bool isEmojiUsed(String emoji, {String? excludeId}) {
    return _box.values.any((mood) =>
      mood.emoji == emoji && mood.id != excludeId
    );
  }

  /// Check if name is already used
  bool isNameUsed(String name, {String? excludeId}) {
    final normalizedName = name.trim().toLowerCase();
    return _box.values.any((mood) =>
      mood.name.trim().toLowerCase() == normalizedName && mood.id != excludeId
    );
  }

  /// Get total count of custom moods
  int getCustomMoodCount() {
    return _box.values.where((mood) => !mood.isDefault).length;
  }

  /// Dispose resources
  Future<void> dispose() async {
    // Box will be closed when Hive is closed
  }
}

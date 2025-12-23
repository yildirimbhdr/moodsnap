import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../data/models/custom_mood.dart';
import '../core/utils/result.dart';

/// Service for managing custom moods
/// Follows SOLID principles and provides clean API
class CustomMoodService {
  static const String _boxName = 'custom_moods';
  late Box<CustomMood> _box;

  /// Initialize the service and register default moods
  Future<Result<void>> init() async {
    try {
      _box = await Hive.openBox<CustomMood>(_boxName);
      await _initializeDefaultMoods();
      return const Success(null);
    } catch (e) {
      return Failure(AppError(
        type: ErrorType.storage,
        message: 'Failed to initialize custom moods service',
        originalError: e,
      ));
    }
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

  /// Get mood name (returns ID for translation lookup if default mood)
  /// For default moods, returns the ID (like 'happy', 'sad') for l10n lookup
  /// For custom moods, returns the actual custom name
  String getMoodName(String id) {
    final mood = getMoodById(id);
    if (mood == null) return id;

    // For default moods, return ID so UI can translate it
    // For custom moods, return the actual name
    return mood.isDefault ? id : mood.name;
  }

  /// Create a new custom mood
  Future<Result<void>> createMood(CustomMood mood) async {
    try {
      // Validate mood name
      if (mood.name.trim().isEmpty) {
        return const Failure(AppError(
          type: ErrorType.validation,
          message: 'Mood name cannot be empty',
        ));
      }

      // Check for duplicates
      if (isNameUsed(mood.name)) {
        return const Failure(AppError(
          type: ErrorType.validation,
          message: 'Mood name already exists',
        ));
      }

      if (isEmojiUsed(mood.emoji)) {
        return const Failure(AppError(
          type: ErrorType.validation,
          message: 'Emoji already used',
        ));
      }

      await _box.put(mood.id, mood);
      return const Success(null);
    } catch (e) {
      return Failure(AppError(
        type: ErrorType.storage,
        message: 'Failed to create mood',
        originalError: e,
      ));
    }
  }

  /// Update an existing mood
  Future<Result<void>> updateMood(CustomMood mood) async {
    try {
      // Cannot update default moods
      if (mood.isDefault) {
        return const Failure(AppError(
          type: ErrorType.validation,
          message: 'Cannot update default moods',
        ));
      }

      // Check if mood exists
      if (!moodExists(mood.id)) {
        return const Failure(AppError(
          type: ErrorType.notFound,
          message: 'Mood not found',
        ));
      }

      // Validate mood name
      if (mood.name.trim().isEmpty) {
        return const Failure(AppError(
          type: ErrorType.validation,
          message: 'Mood name cannot be empty',
        ));
      }

      // Check for duplicates (excluding current mood)
      if (isNameUsed(mood.name, excludeId: mood.id)) {
        return const Failure(AppError(
          type: ErrorType.validation,
          message: 'Mood name already exists',
        ));
      }

      if (isEmojiUsed(mood.emoji, excludeId: mood.id)) {
        return const Failure(AppError(
          type: ErrorType.validation,
          message: 'Emoji already used',
        ));
      }

      await _box.put(mood.id, mood);
      return const Success(null);
    } catch (e) {
      return Failure(AppError(
        type: ErrorType.storage,
        message: 'Failed to update mood',
        originalError: e,
      ));
    }
  }

  /// Delete a custom mood (cannot delete default moods)
  Future<Result<void>> deleteMood(String id) async {
    try {
      final mood = _box.get(id);

      if (mood == null) {
        return const Failure(AppError(
          type: ErrorType.notFound,
          message: 'Mood not found',
        ));
      }

      if (mood.isDefault) {
        return const Failure(AppError(
          type: ErrorType.validation,
          message: 'Cannot delete default moods',
        ));
      }

      await _box.delete(id);
      return const Success(null);
    } catch (e) {
      return Failure(AppError(
        type: ErrorType.storage,
        message: 'Failed to delete mood',
        originalError: e,
      ));
    }
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

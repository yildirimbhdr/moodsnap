import 'package:hive_flutter/hive_flutter.dart';
import 'package:moodie/data/models/mood_entry.dart';

class StorageService {
  static const String _moodBoxName = 'mood_entries';
  static const String _settingsBoxName = 'settings';
  
  late Box<MoodEntry> _moodBox;
  late Box _settingsBox;

  // Initialize Hive
  Future<void> init() async {
    await Hive.initFlutter();
    
    Hive.registerAdapter(MoodEntryAdapter());
    
    _moodBox = await Hive.openBox<MoodEntry>(_moodBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

   getRecentMoodEntries(int count)  {
    final entries = _moodBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return entries.take(count).toList();
  }
  Future<void> saveMoodEntry(MoodEntry entry) async {
    await _moodBox.put(entry.dateKey, entry);
  }

  MoodEntry? getMoodEntry(DateTime date) {
    final dateKey = _getDateKey(date);
    return _moodBox.get(dateKey);
  }

  MoodEntry? getTodayMood() {
    return getMoodEntry(DateTime.now());
  }

  List<MoodEntry> getAllMoodEntries() {
    return _moodBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<MoodEntry> getMoodEntriesForMonth(int year, int month) {
    return _moodBox.values.where((entry) {
      return entry.date.year == year && entry.date.month == month;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> deleteMoodEntry(String dateKey) async {
    await _moodBox.delete(dateKey);
  }

  // Settings Operations
  Future<void> setOnboardingComplete() async {
    await _settingsBox.put('onboarding_complete', true);
  }

  bool isOnboardingComplete() {
    return _settingsBox.get('onboarding_complete', defaultValue: false);
  }

  Future<void> setUserName(String name) async {
    await _settingsBox.put('user_name', name);
  }

  String? getUserName() {
    return _settingsBox.get('user_name');
  }

  Future<void> setLanguage(String languageCode) async {
    await _settingsBox.put('language', languageCode);
  }

  String getLanguage() {
    return _settingsBox.get('language', defaultValue: 'en');
  }

  Future<void> setNotificationTime(int hour) async {
    await _settingsBox.put('notification_hour', hour);
  }

  int getNotificationTime() {
    return _settingsBox.get('notification_hour', defaultValue: 21);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsBox.put('notifications_enabled', enabled);
  }

  bool areNotificationsEnabled() {
    return _settingsBox.get('notifications_enabled', defaultValue: true);
  }

  // Streak Calculation
  int getCurrentStreak() {
    final entries = getAllMoodEntries();
    if (entries.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    while (true) {
      final entry = getMoodEntry(checkDate);
      if (entry == null) break;
      
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int getLongestStreak() {
    return _settingsBox.get('longest_streak', defaultValue: 0);
  }

  Future<void> updateLongestStreak(int streak) async {
    final current = getLongestStreak();
    if (streak > current) {
      await _settingsBox.put('longest_streak', streak);
    }
  }

  // Helper
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Clear all data (for settings/debug)
  Future<void> clearAllData() async {
    await _moodBox.clear();
    await _settingsBox.clear();
  }
}
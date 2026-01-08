import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/result.dart';

/// Service for managing Firebase Analytics
/// Tracks user behavior, screen views, and custom events
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _initialized = false;

  /// Initialize Firebase Analytics
  Future<Result<void>> init() async {
    try {
      if (_initialized) {
        return const Success(null);
      }

      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);

      // Enable analytics collection
      await _analytics!.setAnalyticsCollectionEnabled(true);

      _initialized = true;

      if (kDebugMode) {
        print('📊 Analytics: Successfully initialized');
      }

      // Log app open event
      await logAppOpen();

      return const Success(null);
    } catch (e) {
      if (kDebugMode) {
        print('📊 Analytics: Initialization error: $e');
      }
      return Failure(AppError(
        type: ErrorType.unknown,
        message: 'Failed to initialize Analytics',
        originalError: e,
      ));
    }
  }

  /// Get the analytics observer for navigation tracking
  FirebaseAnalyticsObserver? get observer => _observer;

  /// Check if analytics is initialized
  bool get isInitialized => _initialized;

  /// Log app open event
  Future<void> logAppOpen() async {
    if (!_initialized || _analytics == null) return;

    try {
      await _analytics!.logAppOpen();
      if (kDebugMode) {
        print('📊 Analytics: App opened');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📊 Analytics: Error logging app open: $e');
      }
    }
  }

  /// Log mood entry creation
  Future<void> logMoodEntry({
    required String mood,
    bool hasNote = false,
    bool hasImage = false,
  }) async {
    if (!_initialized || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'mood_entry_created',
        parameters: {
          'mood': mood,
          'has_note': hasNote,
          'has_image': hasImage,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: Mood entry logged - $mood');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📊 Analytics: Error logging mood entry: $e');
      }
    }
  }

  /// Log achievement unlocked
  Future<void> logAchievementUnlocked(String achievementId) async {
    if (!_initialized || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'achievement_unlocked',
        parameters: {
          'achievement_id': achievementId,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: Achievement unlocked - $achievementId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📊 Analytics: Error logging achievement: $e');
      }
    }
  }

  /// Log custom mood creation
  Future<void> logCustomMoodCreated(String moodName) async {
    if (!_initialized || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'custom_mood_created',
        parameters: {
          'mood_name': moodName,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: Custom mood created - $moodName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📊 Analytics: Error logging custom mood: $e');
      }
    }
  }

  /// Log notification settings change
  Future<void> logNotificationSettingsChanged({
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    if (!_initialized || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'notification_settings_changed',
        parameters: {
          'enabled': enabled,
          if (hour != null) 'hour': hour,
          if (minute != null) 'minute': minute,
        },
      );
      if (kDebugMode) {
        print('📊 Analytics: Notification settings changed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📊 Analytics: Error logging notification settings: $e');
      }
    }
  }

  /// Log onboarding completion
  Future<void> logOnboardingCompleted() async {
    if (!_initialized || _analytics == null) return;

    try {
      await _analytics!.logEvent(name: 'onboarding_completed');
      if (kDebugMode) {
        print('📊 Analytics: Onboarding completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📊 Analytics: Error logging onboarding completion: $e');
      }
    }
  }

  /// Log screen view manually (automatic tracking is handled by observer)
  Future<void> logScreenView(String screenName) async {
    if (!_initialized || _analytics == null) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
      );
      if (kDebugMode) {
        print('📊 Analytics: Screen view - $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📊 Analytics: Error logging screen view: $e');
      }
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_initialized || _analytics == null) return;

    try {
      await _analytics!.setUserProperty(
        name: name,
        value: value,
      );
      if (kDebugMode) {
        print('📊 Analytics: User property set - $name: $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📊 Analytics: Error setting user property: $e');
      }
    }
  }
}

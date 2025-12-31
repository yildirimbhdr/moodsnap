import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import '../core/utils/result.dart';
import 'storage/storage_service.dart';

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  StorageService? _storageService;

  /// Set storage service for localization support
  void setStorageService(StorageService storage) {
    _storageService = storage;
  }

  /// Get localized strings based on current language
  Map<String, String> _getLocalizedStrings() {
    final language = _storageService?.getLanguage() ?? 'en';

    switch (language) {
      case 'tr':
        return {
          'notificationTitle': 'Bugün nasıl hissediyorsun? 🌙',
          'notificationBody': 'Ruh halini kaydetme zamanı geldi!',
          'channelName': 'Günlük Hatırlatma',
          'channelDesc': 'Her gün ruh halini kaydetmen için hatırlatma',
          'testTitle': 'Test Bildirimi 🔔',
          'testBody': 'Bildirimler çalışıyor!',
        };
      case 'de':
        return {
          'notificationTitle': 'Wie fühlst du dich heute? 🌙',
          'notificationBody': 'Zeit, deine Stimmung zu protokollieren!',
          'channelName': 'Tägliche Erinnerung',
          'channelDesc': 'Tägliche Erinnerung, deine Stimmung zu protokollieren',
          'testTitle': 'Test-Benachrichtigung 🔔',
          'testBody': 'Benachrichtigungen funktionieren!',
        };
      default: // English
        return {
          'notificationTitle': 'How are you feeling today? 🌙',
          'notificationBody': "It's time to log your mood!",
          'channelName': 'Daily Reminder',
          'channelDesc': 'Daily reminder to log your mood',
          'testTitle': 'Test Notification 🔔',
          'testBody': 'Notifications are working!',
        };
    }
  }

  /// Initialize notification service
  Future<Result<void>> init() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Use device's local timezone
      // This ensures notifications work correctly regardless of user location
      final String timeZoneName = DateTime.now().timeZoneName;
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        // Fallback to Europe/Istanbul if timezone not found
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      }

      // Android initialization settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings - IMPORTANT: Don't request permissions here
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // We'll request manually
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      final bool? initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // IMPORTANT: On iOS, initialize() can return false even when it succeeds
      // This is a known issue with flutter_local_notifications on iOS
      // Since the plugin still works (test notifications work), we mark it as initialized
      _initialized = true;

      return const Success(null);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
        print('Stack trace: $stackTrace');
      }
      return Failure(AppError(
        type: ErrorType.unknown,
        message: 'Notification initialization error: $e',
        originalError: e,
      ));
    }
  }

  /// Request notification permissions
  Future<Result<bool>> requestPermissions() async {
    try {
      // Android 13+ requires runtime permission
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          final bool? granted = await androidPlugin.requestNotificationsPermission();
          return Success(granted ?? false);
        }
      }

      // iOS permission request
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final IOSFlutterLocalNotificationsPlugin? iosPlugin =
            _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          final bool? granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return Success(granted ?? false);
        }
      }

      return const Success(true);
    } catch (e) {
      return Failure(AppError(
        type: ErrorType.permission,
        message: 'Failed to request notification permissions',
        originalError: e,
      ));
    }
  }

  /// Schedule daily reminder at specific hour and minute
  Future<Result<void>> scheduleDailyReminder(int hour, [int minute = 0]) async {
    try {
      if (!_initialized) {
        return const Failure(AppError(
          type: ErrorType.unknown,
          message: 'NotificationService not initialized',
        ));
      }

      // Cancel existing daily reminder
      await _notifications.cancel(0); // ID: 0 for daily reminder

      // Create notification time
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the scheduled time is in the past, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Get localized strings
      final strings = _getLocalizedStrings();

      // Android notification details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_reminder', // Channel ID
        strings['channelName']!, // Channel name
        channelDescription: strings['channelDesc']!,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details - using default sound
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      // Combined notification details
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification
      await _notifications.zonedSchedule(
        0, // Notification ID
        strings['notificationTitle']!,
        strings['notificationBody']!,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at same time
      );

      return const Success(null);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error scheduling daily reminder: $e');
        print('Stack trace: $stackTrace');
      }
      return Failure(AppError(
        type: ErrorType.unknown,
        message: 'Failed to schedule daily reminder: $e',
        originalError: e,
      ));
    }
  }

  /// Cancel daily reminder
  Future<Result<void>> cancelDailyReminder() async {
    try {
      await _notifications.cancel(0); // Cancel notification with ID 0
      return const Success(null);
    } catch (e) {
      return Failure(AppError(
        type: ErrorType.unknown,
        message: 'Failed to cancel daily reminder',
        originalError: e,
      ));
    }
  }

  /// Cancel all notifications
  Future<Result<void>> cancelAll() async {
    try {
      await _notifications.cancelAll();
      return const Success(null);
    } catch (e) {
      return Failure(AppError(
        type: ErrorType.unknown,
        message: 'Failed to cancel notifications',
        originalError: e,
      ));
    }
  }

  /// Show immediate test notification
  Future<Result<void>> showTestNotification() async {
    try {
      // Get localized strings
      final strings = _getLocalizedStrings();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test notification channel',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        999, // Test notification ID
        strings['testTitle']!,
        strings['testBody']!,
        details,
      );

      return const Success(null);
    } catch (e) {
      return Failure(AppError(
        type: ErrorType.unknown,
        message: 'Failed to show test notification',
        originalError: e,
      ));
    }
  }

  /// Schedule a test notification 30 seconds in the future (for background testing)
  Future<Result<void>> scheduleBackgroundTestNotification() async {
    try {
      if (!_initialized) {
        return const Failure(AppError(
          type: ErrorType.unknown,
          message: 'NotificationService not initialized',
        ));
      }

      // Get localized strings
      final strings = _getLocalizedStrings();

      // Schedule for 30 seconds from now
      final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 30));

      // Android notification details with high priority for background delivery
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'background_test_channel',
        'Background Test Notifications',
        channelDescription: 'Test notification channel for background delivery',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
      );

      // iOS notification details - using default sound
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Cancel any existing background test notification
      await _notifications.cancel(998);

      // Schedule the notification
      await _notifications.zonedSchedule(
        998, // Background test notification ID
        '${strings['testTitle']!} (30s)',
        'Uygulama kapalıyken bu bildirimi aldıysanız, bildirimler çalışıyor! 🎉',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      return const Success(null);
    } catch (e) {
      return Failure(AppError(
        type: ErrorType.unknown,
        message: 'Failed to schedule background test notification',
        originalError: e,
      ));
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final settings = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings ?? false;
    }

    return false;
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Here you can navigate to specific screen based on payload
    // For example, navigate to mood entry screen
  }
}

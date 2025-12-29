import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import '../core/utils/result.dart';

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification service
  Future<Result<void>> init() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Find local timezone
      // For production, you should use flutter_native_timezone package
      // For now, we'll use UTC+3 (Istanbul) as default
      final String timeZoneName = 'Europe/Istanbul';
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      // Android initialization settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
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

      if (initialized == true) {
        _initialized = true;
        return const Success(null);
      } else {
        return const Failure(AppError(
          type: ErrorType.permission,
          message: 'Failed to initialize notifications',
        ));
      }
    } catch (e) {
      return Failure(AppError(
        type: ErrorType.unknown,
        message: 'Notification initialization error',
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

  /// Schedule daily reminder at specific hour
  Future<Result<void>> scheduleDailyReminder(int hour) async {
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
      // tz.TZDateTime scheduledDate = tz.TZDateTime(
      //   tz.local,
      //   now.year,
      //   now.month,
      //   now.day,
      //   hour,
      //   0,
      // );
    tz.TZDateTime scheduledDate = now.add(const Duration(minutes: 1));

      // If the scheduled time is in the past, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Android notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_reminder', // Channel ID
        'Günlük Hatırlatma', // Channel name
        channelDescription: 'Her gün ruh halini kaydetmen için hatırlatma',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.aiff',
      );

      // Combined notification details
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification
      await _notifications.zonedSchedule(
        0, // Notification ID
        'Bugün nasıl hissediyorsun? 🌙',
        'Ruh halini kaydetme zamanı geldi!',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at same time
      );

      if (kDebugMode) {
        print('📱 Daily reminder scheduled for $hour:00');
        print('   Next notification: $scheduledDate');
      }

      return const Success(null);
    } catch (e) {
      return Failure(AppError(
        type: ErrorType.unknown,
        message: 'Failed to schedule daily reminder',
        originalError: e,
      ));
    }
  }

  /// Cancel daily reminder
  Future<Result<void>> cancelDailyReminder() async {
    try {
      await _notifications.cancel(0); // Cancel notification with ID 0

      if (kDebugMode) {
        print('📱 Daily reminder cancelled');
      }

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
        'Test Bildirimi 🔔',
        'Bildirimler çalışıyor!',
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
    if (kDebugMode) {
      print('📱 Notification tapped: ${response.payload}');
    }
    // Here you can navigate to specific screen based on payload
    // For example, navigate to mood entry screen
  }
}

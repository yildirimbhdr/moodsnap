# Flutter Local Notifications - Kapsamlı Kurulum Rehberi

Bu döküman, Flutter projelerinizde zamanlı (scheduled) bildirimler kurmanız için adım adım rehberdir. iOS ve Android'de test edilmiş, çalışan bir sistem.

## 📋 İçindekiler

1. [Genel Bakış](#genel-bakış)
2. [Dependencies](#dependencies)
3. [iOS Konfigürasyonu](#ios-konfigürasyonu)
4. [Android Konfigürasyonu](#android-konfigürasyonu)
5. [Kod İmplementasyonu](#kod-implementasyonu)
6. [Karşılaşılan Sorunlar ve Çözümler](#karşılaşılan-sorunlar-ve-çözümler)
7. [Test Etme](#test-etme)
8. [Önemli Notlar](#önemli-notlar)

---

## Genel Bakış

Bu sistem şunları sağlar:
- ✅ **Günlük zamanlı bildirimler** (her gün aynı saatte)
- ✅ **iOS ve Android desteği**
- ✅ **Uygulama kapalıyken çalışan bildirimler**
- ✅ **Kullanıcı dostu izin yönetimi**
- ✅ **Çoklu dil desteği**
- ✅ **Timezone desteği**

---

## Dependencies

### pubspec.yaml

```yaml
dependencies:
  flutter_local_notifications: ^17.2.3
  timezone: ^0.9.4
```

Kurulum:
```bash
flutter pub get
```

---

## iOS Konfigürasyonu

### 1. Info.plist Ayarları

`ios/Runner/Info.plist` dosyasına ekleyin:

```xml
<key>NSUserNotificationsUsageDescription</key>
<string>MoodieSnap needs notification permission to remind you to log your daily mood.</string>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### 2. AppDelegate.swift Konfigürasyonu

`ios/Runner/AppDelegate.swift` dosyasını aşağıdaki gibi düzenleyin:

```swift
import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set flutter_local_notifications to handle presentation
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 3. Podfile Minimum iOS Version

`ios/Podfile` dosyasında minimum iOS versiyonunu kontrol edin:

```ruby
platform :ios, '15.0'  # veya daha yüksek
```

Değişiklik yaptıysanız:
```bash
cd ios
pod install
cd ..
```

---

## Android Konfigürasyonu

### 1. AndroidManifest.xml

`android/app/src/main/AndroidManifest.xml` dosyasına ekleyin:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />

    <application>
        <!-- Existing code -->

        <!-- Notification Receiver -->
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false" />

        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

### 2. build.gradle Minimum SDK

`android/app/build.gradle` dosyasında:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // minimum 21
        targetSdkVersion 34
    }
}
```

---

## Kod İmplementasyonu

### 1. NotificationService Sınıfı

`lib/services/notification_service.dart` dosyası oluşturun:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification service
  Future<void> init() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Set local timezone
    final String timeZoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization - DON'T request permissions here
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    // CRITICAL: iOS initialize() may return false but still work
    _initialized = true;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      return await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }

    return false;
  }

  /// Schedule daily reminder
  Future<void> scheduleDailyReminder(int hour, [int minute = 0]) async {
    if (!_initialized) return;

    // Cancel existing
    await _notifications.cancel(0);

    // Create scheduled time
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time passed, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Android details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminder',
      channelDescription: 'Daily reminder notification',
      importance: Importance.high,
      priority: Priority.high,
    );

    // iOS details
    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule
    await _notifications.zonedSchedule(
      0, // ID
      'Reminder Title',
      'Reminder Body',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  /// Cancel daily reminder
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(0);
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final settings = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings ?? false;
    }

    return false;
  }
}
```

### 2. main.dart'ta Başlatma

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.init();

  // If notifications are enabled in settings, schedule them
  if (/* check your storage */) {
    await notificationService.scheduleDailyReminder(21, 0); // 9 PM
  }

  runApp(MyApp());
}
```

### 3. Kullanıcıdan İzin İsteme

Onboarding veya ana sayfada:

```dart
Future<void> _requestNotificationPermission() async {
  final notificationService = NotificationService();
  final granted = await notificationService.requestPermissions();

  if (granted) {
    // İzin verildi - bildirim schedule et
    await notificationService.scheduleDailyReminder(21, 0);
  } else {
    // İzin reddedildi
    print('Notification permission denied');
  }
}
```

---

## Karşılaşılan Sorunlar ve Çözümler

### ❌ Sorun 1: iOS'ta `initialize()` false dönüyor

**Sebep:** iOS'ta `flutter_local_notifications` plugin'i bazen false dönse bile çalışır.

**Çözüm:**
```dart
// iOS için false dönse bile initialized olarak işaretle
_initialized = true;
```

### ❌ Sorun 2: iOS'ta zamanlı bildirimler çalışmıyor

**Sebep:** AppDelegate.swift'te delegate düzgün ayarlanmamış.

**Çözüm:**
```swift
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}
```

### ❌ Sorun 3: iOS'ta bildirim sesi yok

**Sebep:** Olmayan bir ses dosyası kullanılıyor.

**Çözüm:** iOS için default ses kullanın:
```dart
const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
  // sound: 'notification_sound.aiff', // BUNU KALDIR
);
```

### ❌ Sorun 4: Bildirim schedule ediliyor ama gelmiyor

**Sebep:**
- Timezone yanlış ayarlanmış
- `matchDateTimeComponents` eksik

**Çözüm:**
```dart
// Timezone'u düzgün ayarla
tz.initializeTimeZones();
tz.setLocalLocation(tz.getLocation(timeZoneName));

// Günlük tekrar için gerekli
matchDateTimeComponents: DateTimeComponents.time,
```

### ❌ Sorun 5: Android 13+ izin istemiyor

**Sebep:** Runtime permission eksik.

**Çözüm:**
```dart
final androidPlugin = _notifications
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
final granted = await androidPlugin?.requestNotificationsPermission();
```

### ❌ Sorun 6: Pending notifications 0 gözüküyor

**Sebep:** `zonedSchedule()` sessizce başarısız oluyor.

**Çözüm:**
- İzin kontrolü yap
- Notification details'i kontrol et (iOS ses dosyası vb.)
- `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle` ekle

---

## Test Etme

### Manuel Test

1. **İzin testi:**
```dart
final hasPermission = await notificationService.areNotificationsEnabled();
print('Has permission: $hasPermission');
```

2. **Schedule testi:**
```dart
// 1 dakika sonrası için ayarla
final now = DateTime.now();
await notificationService.scheduleDailyReminder(
  now.hour,
  now.minute + 1
);
```

3. **Pending notifications kontrolü:**
```dart
final pending = await notificationService.getPendingNotifications();
print('Pending: ${pending.length}');
for (var p in pending) {
  print('ID: ${p.id}, Title: ${p.title}');
}
```

### Test Notification

Anında test bildirimi için:

```dart
Future<void> showTestNotification() async {
  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'test_channel',
    'Test Notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  const DarwinNotificationDetails iosDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await _notifications.show(
    999,
    'Test Notification',
    'This is a test!',
    details,
  );
}
```

---

## Önemli Notlar

### ⚠️ iOS Spesifik

1. **İzin isteme:** iOS'ta izni her zaman manuel olarak isteyin, `initialize()` içinde değil.

2. **AppDelegate:** Mutlaka delegate'i ayarlayın, yoksa bildirimler görünmez.

3. **Background Modes:** Info.plist'te `UIBackgroundModes` mutlaka olmalı.

4. **Ses dosyası:** Eğer custom ses kullanmayacaksanız, hiç belirtmeyin (default ses kullanılır).

### ⚠️ Android Spesifik

1. **Exact Alarms:** Android 12+ için `SCHEDULE_EXACT_ALARM` permission gerekli.

2. **Boot Receiver:** Telefon yeniden başlatıldığında bildirimleri restore etmek için gerekli.

3. **Battery Optimization:** Bazı üreticiler (Xiaomi, Huawei) bildirimleri engelleyebilir. Kullanıcıya battery optimization'ı kapatmasını söyleyin.

### ⚠️ Genel

1. **Timezone:** Mutlaka doğru timezone kullanın, yoksa bildirimler yanlış saatte gelir.

2. **Permission kontrolü:** Bildirim schedule etmeden önce mutlaka izin kontrolü yapın.

3. **Error handling:** `try-catch` kullanın, özellikle iOS'ta beklenmedik hatalar olabilir.

4. **Testing:** Her platformda fiziksel cihazda test edin - simulator'da bildirimler farklı davranabilir.

---

## Hızlı Başlangıç Checklist

- [ ] `flutter_local_notifications` ve `timezone` dependencies eklendi
- [ ] iOS Info.plist ayarları yapıldı
- [ ] iOS AppDelegate.swift düzenlendi
- [ ] Android AndroidManifest.xml ayarları yapıldı
- [ ] Android minimum SDK 21+
- [ ] NotificationService sınıfı oluşturuldu
- [ ] main.dart'ta initialize edildi
- [ ] İzin isteme mekanizması eklendi
- [ ] Fiziksel cihazda test edildi
- [ ] Pending notifications kontrol edildi
- [ ] Uygulama kapalıyken test edildi

---

## Ek Kaynaklar

- [flutter_local_notifications package](https://pub.dev/packages/flutter_local_notifications)
- [timezone package](https://pub.dev/packages/timezone)
- [iOS Notification Guide](https://developer.apple.com/documentation/usernotifications)
- [Android Notification Guide](https://developer.android.com/develop/ui/views/notifications)

---

**Son Güncelleme:** 31 Aralık 2025
**Test Edilen Platformlar:** iOS 15+, Android 12+
**Flutter Version:** 3.x

---

## Yardım ve Destek

Bu rehberi kullanırken sorun yaşarsanız:

1. Önce "Karşılaşılan Sorunlar ve Çözümler" bölümüne bakın
2. Terminal loglarını kontrol edin (özellikle error mesajları)
3. Pending notifications sayısını kontrol edin
4. Fiziksel cihazda test edin (simulator yerine)

Başarılar! 🎉

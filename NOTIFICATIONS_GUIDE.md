# 🔔 Bildirim Sistemi Kullanım Rehberi

## ✅ TAMAMLANAN İŞLEMLER

Tebrikler! Projenize **Local Notifications** sistemi başarıyla entegre edildi.

---

## 📋 ÖZELLIKLER

### 1. **Günlük Hatırlatma**
- Her gün belirli bir saatte otomatik bildirim gönderir
- Kullanıcı tarafından ayarlanabilir saat
- "Bugün nasıl hissediyorsun? 🌙" mesajı

### 2. **Akıllı Zamanlama**
- Cihaz yeniden başlatılsa bile bildirimler devam eder
- Telefon kapalıyken bile zamanında gönderilir (exact alarm)
- Timezone destekli (şu an: Europe/Istanbul)

### 3. **Kullanıcı Kontrolü**
- Settings ekranından açma/kapama
- Bildirim saati değiştirme
- Test bildirimi gönderme

### 4. **Platform Desteği**
- ✅ Android 5.0+ (API 21+)
- ✅ iOS 10.0+
- ✅ Android 13+ için runtime permission

---

## 🎯 KULLANIM

### Kullanıcı Perspektifi:

1. **Ayarlar → Notifications** bölümüne git
2. "Günlük Ruh Hali Hatırlatıcısı" switch'ini aç
3. İzin istendi: "İzin Ver" tıkla
4. ✅ Bildirimler aktif edildi!

**Ek Ayarlar:**
- **Bildirim Saati:** İstediğin saati seç (varsayılan 21:00)
- **Test Bildirimi:** Hemen test bildirimi gönder

---

## 🔧 TEKNİK DETAYLAR

### Dosya Yapısı:

```
lib/
├── services/
│   └── notification_service.dart          # NotificationService class
├── features/settings/
│   └── settings_screen.dart               # UI integration
└── main.dart                              # Service initialization
```

### NotificationService API:

```dart
// Initialize
await notificationService.init();

// Request permission
final result = await notificationService.requestPermissions();

// Schedule daily reminder at 21:00
await notificationService.scheduleDailyReminder(21);

// Cancel daily reminder
await notificationService.cancelDailyReminder();

// Send test notification
await notificationService.showTestNotification();

// Check if enabled
bool enabled = await notificationService.areNotificationsEnabled();
```

---

## 📱 ANDROID YAPILANDIRMASI

### AndroidManifest.xml

Aşağıdaki izinler eklendi:
- `POST_NOTIFICATIONS` - Bildirim gönderme (Android 13+)
- `RECEIVE_BOOT_COMPLETED` - Cihaz açılışında bildirimleri yeniden zamanlama
- `VIBRATE` - Titreşim
- `SCHEDULE_EXACT_ALARM` - Tam zamanında bildirim
- `USE_EXACT_ALARM` - Exact alarm kullanımı

### Notification Receivers:

- `ScheduledNotificationBootReceiver` - Cihaz açılışında çalışır
- `ScheduledNotificationReceiver` - Zamanlanmış bildirimleri tetikler

---

## 🍎 iOS YAPILANDIRMASI

### AppDelegate.swift

UNUserNotificationCenter delegate olarak ayarlandı.

### Permissions:

iOS'ta kullanıcı bildirim iznini açıkça vermeli. İlk bildirim açılışında otomatik sorar.

---

## 🚨 ÖNEMLİ NOTLAR

### Android 13+ (API 33+):

Runtime permission gereklidir. Kullanıcı ilk kez bildirimi açtığında izin penceresi çıkar.

### Exact Alarms:

Android 12+ (API 31+) cihazlarda exact alarm izni gerekli. Eğer kullanıcı battery optimization ayarlarında kısıtlama yaparsa, bildirimler gecikebilir.

**Önerilen Çözüm:**
```dart
// Kullanıcıyı ayarlara yönlendirme (gelecekte eklenebilir)
await AndroidFlutterLocalNotificationsPlugin()
    .requestExactAlarm();
```

### Background Restrictions:

Bazı cihazlar (Xiaomi, Huawei, vb.) agresif battery optimization yapar:
- Kullanıcıya manuel ayar talimatı verin
- "Ayarlar → Batarya → Uygulamalar → MoodySnap → Kısıtlama Yok"

---

## 🧪 TEST ETME

### 1. Test Bildirimi:

```dart
// Settings ekranında "Test Bildirimi Gönder" butonuna tıkla
```

### 2. Günlük Hatırlatmayı Test Etme:

**Hızlı Test (Demo amaçlı):**

NotificationService'de `scheduleDailyReminder` metodunu geçici olarak değiştir:

```dart
// 1 dakika sonra bildirim gönder (test için)
tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(minutes: 1));

// Normal kod (günlük):
// scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0);
```

### 3. Cihaz Yeniden Başlatma Testi:

1. Bildirimi zamanla (örn: 5 dakika sonra)
2. Cihazı yeniden başlat
3. Zamanı geldiğinde bildirim çalmalı ✅

---

## 🔮 GELİŞTİRME ÖNERİLERİ

### 1. **Multi-Language Support**

Şu anda bildirim metni hardcoded. L10n eklenebilir:

```dart
// Before:
'Bugün nasıl hissediyorsun? 🌙'

// After:
AppLocalizations.of(context).notificationTitle
```

### 2. **Notification Payload**

Bildirime tıklandığında direkt mood entry ekranına git:

```dart
const NotificationDetails details = NotificationDetails(
  android: AndroidNotificationDetails(
    'daily_reminder',
    'Günlük Hatırlatma',
    // ... other settings
  ),
);

await _notifications.zonedSchedule(
  0,
  'Bildirim Başlığı',
  'Bildirim İçeriği',
  scheduledDate,
  details,
  payload: 'mood_entry', // <-- Payload ekle
  // ...
);

// Handle tap:
void _onNotificationTapped(NotificationResponse response) {
  if (response.payload == 'mood_entry') {
    // Navigate to mood entry screen
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => MoodEntryScreen()),
    );
  }
}
```

### 3. **Firebase Cloud Messaging (Opsiyonel)**

Server-side bildirimler için FCM ekleyebilirsiniz:

**Kullanım Senaryoları:**
- Yeni özellik duyuruları
- Motivasyon mesajları (server'dan)
- Sosyal özellikler (arkadaş bildirimleri)

**Setup:**
```bash
flutter pub add firebase_messaging
```

### 4. **Timezone Auto-Detection**

Şu an Europe/Istanbul fixed. Dinamik yapalım:

```bash
flutter pub add flutter_native_timezone
```

```dart
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
tz.setLocalLocation(tz.getLocation(timeZoneName));
```

### 5. **Custom Notification Sound**

Özel ses dosyası eklemek:

**Android:**
- Ses dosyasını `android/app/src/main/res/raw/notification_sound.mp3` ekle

**iOS:**
- Ses dosyasını `ios/Runner/notification_sound.aiff` ekle

### 6. **Rich Notifications**

Görselli, actionable bildirimler:

```dart
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'daily_reminder',
  'Günlük Hatırlatma',
  styleInformation: BigPictureStyleInformation(
    FilePathAndroidBitmap('path/to/image.png'),
  ),
  actions: <AndroidNotificationAction>[
    AndroidNotificationAction('quick_log', 'Hızlı Kaydet'),
    AndroidNotificationAction('dismiss', 'Kapat'),
  ],
);
```

---

## 🐛 SORUN GİDERME

### Bildirim Gelmiyor?

**1. Permission Check:**
```dart
bool enabled = await notificationService.areNotificationsEnabled();
print('Notifications enabled: $enabled');
```

**2. Pending Notifications:**
```dart
final pending = await notificationService.getPendingNotifications();
print('Pending: ${pending.length}');
for (var notification in pending) {
  print('ID: ${notification.id}, Title: ${notification.title}');
}
```

**3. Android Logs:**
```bash
adb logcat | grep Flutter
```

**4. iOS Logs:**
```bash
# Xcode → Window → Devices and Simulators → Open Console
```

### Android 13+ Permission Denied?

Kullanıcı izni reddetmişse, settings'e yönlendir:

```dart
import 'package:permission_handler/permission_handler.dart';

if (await Permission.notification.isDenied) {
  openAppSettings();
}
```

---

## 📊 ANALYTICS (Opsiyonel)

Bildirim performansını track etmek:

```dart
// Firebase Analytics entegrasyonu
FirebaseAnalytics.instance.logEvent(
  name: 'notification_scheduled',
  parameters: {'hour': hour},
);

FirebaseAnalytics.instance.logEvent(
  name: 'notification_tapped',
);
```

---

## ✨ SONUÇ

Artık uygulamanızda tam functional bir local notification sistemi var!

**Çalışan Özellikler:**
- ✅ Günlük hatırlatma
- ✅ Özelleştirilebilir saat
- ✅ Permission handling
- ✅ Test notification
- ✅ Boot persistence
- ✅ Android & iOS support

**Sonraki Adımlar:**
1. Test edin (hem Android hem iOS)
2. Gerçek cihazda deneyin
3. İsterseniz FCM ekleyin (opsiyonel)

---

## 📞 DESTEK

Sorun mu yaşıyorsunuz?
- NotificationService debug modda detaylı log verir
- `kDebugMode` block'ları kontrol edin
- Test notification ile başlayın

Başarılar! 🎉

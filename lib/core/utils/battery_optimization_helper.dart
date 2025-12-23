import 'package:flutter/material.dart';

/// Helper to guide users on battery optimization settings
class BatteryOptimizationHelper {
  /// Show dialog with instructions for specific manufacturers
  static void showBatteryOptimizationGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirimler Gelmiyor mu?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bazı cihazlarda bildirimler için ek ayar gerekebilir:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildManufacturerGuide('Xiaomi (MIUI)', [
                'Ayarlar → Uygulamalar → MoodySnap',
                'Diğer İzinler → Arka Planda Başlat: İzin Ver',
                'Batarya Tasarrufu → Kısıtlama Yok',
                'Autostart: Açık',
              ]),
              const SizedBox(height: 12),
              _buildManufacturerGuide('Huawei (EMUI)', [
                'Ayarlar → Uygulamalar → MoodySnap',
                'Batarya → Uygulama Başlatma: Manuel Yönet',
                'Otomatik başlat, İkincil başlat, Arka planda çalış: Hepsini Aç',
              ]),
              const SizedBox(height: 12),
              _buildManufacturerGuide('OnePlus', [
                'Ayarlar → Batarya → Batarya Optimizasyonu',
                'MoodySnap → Optimize Etme',
              ]),
              const SizedBox(height: 12),
              _buildManufacturerGuide('Samsung', [
                'Ayarlar → Uygulamalar → MoodySnap',
                'Batarya → Arka Plan Kullanım Sınırı: Kaldır',
                'Uyku Modu: MoodySnap\'i Asla Uykuya Alma',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  static Widget _buildManufacturerGuide(String manufacturer, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          manufacturer,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  /// Get manufacturer-specific battery optimization message
  static String getBatteryOptimizationMessage() {
    // In a real app, you would detect the device manufacturer
    // For now, return a generic message
    return 'Bazı cihazlarda batarya optimizasyonu ayarlarını değiştirmeniz gerekebilir.';
  }
}

import 'package:vibration/vibration.dart';

class HapticUtils {
  // Light tap feedback
  static Future<void> lightImpact() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 10);
    }
  }

  // Medium feedback
  static Future<void> mediumImpact() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 20);
    }
  }

  // Success feedback (pattern)
  static Future<void> success() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(
        pattern: [0, 50, 50, 50],
        intensities: [0, 128, 0, 255],
      );
    }
  }

  // Selection changed
  static Future<void> selectionClick() async {
    await lightImpact();
  }
}
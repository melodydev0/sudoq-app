import 'package:vibration/vibration.dart';
import 'storage_service.dart';

/// Centralized haptic feedback that respects the vibration setting.
/// Uses the Vibration plugin for reliable cross-device support.
class HapticService {
  static bool get _enabled => StorageService.getSettings().vibrationEnabled;

  static void selectionClick() {
    if (_enabled) Vibration.vibrate(duration: 10, amplitude: 40);
  }

  static void lightImpact() {
    if (_enabled) Vibration.vibrate(duration: 20, amplitude: 60);
  }

  static void mediumImpact() {
    if (_enabled) Vibration.vibrate(duration: 30, amplitude: 128);
  }

  static void heavyImpact() {
    if (_enabled) Vibration.vibrate(duration: 50, amplitude: 255);
  }
}

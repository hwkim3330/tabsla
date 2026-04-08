import 'package:flutter/services.dart';

class Haptics {
  static const _channel = MethodChannel('com.dashboard.tesla_dashboard/vibration');

  /// Light tap — button press
  static Future<void> tap() => _vibrate(30, 80);

  /// Medium — gear change, mode switch
  static Future<void> medium() => _vibrate(50, 150);

  /// Strong — warning, collision alert
  static Future<void> strong() => _vibrate(100, 255);

  /// Double tap — confirmation
  static Future<void> doubleTap() async {
    try {
      await _channel.invokeMethod('vibratePattern', {'pattern': [0, 40, 60, 40]});
    } catch (_) {}
  }

  /// Speed bump feel
  static Future<void> bump() async {
    try {
      await _channel.invokeMethod('vibratePattern', {'pattern': [0, 20, 30, 20, 30, 20]});
    } catch (_) {}
  }

  static Future<void> _vibrate(int duration, int amplitude) async {
    try {
      await _channel.invokeMethod('vibrate', {'duration': duration, 'amplitude': amplitude});
    } catch (_) {}
  }
}

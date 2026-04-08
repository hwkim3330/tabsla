import 'dart:async';
import 'package:flutter/services.dart';

class DeviceTemp {
  static const _channel = MethodChannel('com.dashboard.tesla_dashboard/battery');

  static Future<double> getBatteryTemp() async {
    try {
      final temp = await _channel.invokeMethod<double>('getBatteryTemperature');
      return temp ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

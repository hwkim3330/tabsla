import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';
import 'weather_service.dart';

class SensorManager extends ChangeNotifier {
  static const _batteryChannel = MethodChannel('com.dashboard.tesla_dashboard/battery');

  // Accelerometer
  double _lateralG = 0;
  double _longitudinalG = 0;
  double _totalG = 1.0;

  // Gyroscope
  double _pitch = 0, _roll = 0;

  // Compass
  double _compassHeading = 0;

  // Noise
  double _noiseDb = 0;
  bool _micActive = false;

  // Battery temp
  double _batteryTemp = 0;

  // Weather
  double _outsideTemp = 0;
  double _humidity = 0;
  double _windSpeed = 0;
  String _weatherDesc = '';
  bool _weatherLoaded = false;

  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _magnetSub;
  StreamSubscription? _noiseSub;
  Timer? _tempTimer;
  Timer? _weatherTimer;

  double get lateralG => _lateralG;
  double get longitudinalG => _longitudinalG;
  double get totalG => _totalG;
  double get pitch => _pitch;
  double get roll => _roll;
  double get compassHeading => _compassHeading;
  double get noiseDb => _noiseDb;
  bool get micActive => _micActive;
  double get batteryTemp => _batteryTemp;
  double get outsideTemp => _outsideTemp;
  double get humidity => _humidity;
  double get windSpeed => _windSpeed;
  String get weatherDesc => _weatherDesc;
  bool get weatherLoaded => _weatherLoaded;

  Future<void> init(LatLng position) async {
    _initAccel();
    _initGyro();
    _initCompass();
    await _initMic();
    _startBatteryTempPolling();
    _fetchWeather(position);
    _weatherTimer = Timer.periodic(const Duration(minutes: 10), (_) => _fetchWeather(position));
  }

  void updatePosition(LatLng pos) {
    // Weather updates on timer, not every GPS tick
  }

  void _initAccel() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((e) {
      _lateralG = e.x / 9.81;
      _longitudinalG = e.y / 9.81 - 1.0;
      _totalG = sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / 9.81;
      notifyListeners();
    });
  }

  void _initGyro() {
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((e) {
      _pitch += e.x * 0.05;
      _roll += e.y * 0.05;
      _pitch *= 0.95;
      _roll *= 0.95;
      notifyListeners();
    });
  }

  void _initCompass() {
    _magnetSub = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((e) {
      _compassHeading = atan2(e.y, e.x) * 180 / pi;
      if (_compassHeading < 0) _compassHeading += 360;
      notifyListeners();
    });
  }

  Future<void> _initMic() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;
    try {
      _noiseSub = NoiseMeter().noise.listen((n) {
        _noiseDb = n.meanDecibel;
        _micActive = true;
        notifyListeners();
      });
    } catch (_) {}
  }

  void _startBatteryTempPolling() {
    _fetchBatteryTemp();
    _tempTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchBatteryTemp());
  }

  Future<void> _fetchBatteryTemp() async {
    try {
      final temp = await _batteryChannel.invokeMethod<double>('getBatteryTemperature');
      if (temp != null) {
        _batteryTemp = temp;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _fetchWeather(LatLng pos) async {
    final w = await WeatherService.getCurrentWeather(pos);
    if (w != null) {
      _outsideTemp = w.temperature;
      _humidity = w.humidity;
      _windSpeed = w.windSpeed;
      _weatherDesc = w.description;
      _weatherLoaded = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magnetSub?.cancel();
    _noiseSub?.cancel();
    _tempTimer?.cancel();
    _weatherTimer?.cancel();
    super.dispose();
  }
}

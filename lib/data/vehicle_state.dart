import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'route_data.dart';

class DetectedObject {
  final double x, y;
  final String type;
  final double speed;
  final int id;
  DetectedObject({required this.x, required this.y, required this.type, required this.speed, required this.id});
}

class VehicleState extends ChangeNotifier {
  bool _simMode = false;
  bool get simMode => _simMode;

  LatLng _position = const LatLng(37.5665, 126.9780);
  double _speed = 0;
  double _heading = 0;
  bool _gpsReady = false;
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;

  int _waypointIndex = 0;
  double _segmentProgress = 0;

  String _gear = 'P';
  bool _isParked = true;
  double _batteryLevel = 87;
  double _range = 348;
  double _power = 0;
  double _steeringAngle = 0;
  double _insideTemp = 22;
  double _outsideTemp = 18;
  bool _acOn = true;
  String _currentStreet = '';
  double _tripDistance = 0;
  List<DetectedObject> _detectedObjects = [];
  Timer? _simTimer;
  final _rng = Random();
  int _objId = 0;
  final List<LatLng> _trail = [];

  LatLng get position => _position;
  double get speed => _speed;
  double get heading => _heading;
  bool get gpsReady => _gpsReady;
  String get gear => _gear;
  bool get isParked => _isParked;
  double get batteryLevel => _batteryLevel;
  double get range => _range;
  double get power => _power;
  double get steeringAngle => _steeringAngle;
  double get insideTemp => _insideTemp;
  double get outsideTemp => _outsideTemp;
  bool get acOn => _acOn;
  String get currentStreet => _currentStreet;
  double get tripDistance => _tripDistance;
  List<DetectedObject> get detectedObjects => _detectedObjects;
  List<LatLng> get trail => _trail;

  Future<void> init() async {
    await _initGps();
  }

  // Navigation route for sim to follow
  List<LatLng>? _navRoute;
  List<LatLng>? get navRoute => _navRoute;
  double _navTotalDist = 0; // meters
  double _navTotalDuration = 0; // seconds
  double _navAvgSpeed = 50; // km/h calculated from route

  void setNavRoute(List<LatLng> route, {double totalDist = 0, double totalDuration = 0}) {
    if (route.length < 2) return;
    _navRoute = route;
    _navTotalDist = totalDist;
    _navTotalDuration = totalDuration;
    // Calculate average speed from route data
    if (totalDuration > 0 && totalDist > 0) {
      _navAvgSpeed = (totalDist / 1000) / (totalDuration / 3600); // km/h
      _navAvgSpeed = _navAvgSpeed.clamp(20, 120);
      _simTargetSpeed = _navAvgSpeed;
    }
    _waypointIndex = 0;
    _segmentProgress = 0;
    _position = route.first;
    _trail.clear();
    _currentStreet = 'Following route';
    if (!_simMode) enableSimulation();
    notifyListeners();
  }

  void clearNavRoute() {
    _navRoute = null;
    notifyListeners();
  }

  List<LatLng> get _activeRoute => _navRoute ?? seoulRoute;

  void enableSimulation() {
    _simMode = true;
    _positionStream?.cancel();
    _position = _activeRoute.first;
    _waypointIndex = 0;
    _segmentProgress = 0;
    _isParked = false;
    _gear = 'D';
    _speed = 50;
    _trail.clear();
    _tripDistance = 0;
    _currentStreet = _navRoute != null ? 'Following route' : 'Sejong-daero';
    _startSimTimer();
    notifyListeners();
  }

  void disableSimulation() {
    _simMode = false;
    _simTimer?.cancel();
    _isParked = true;
    _gear = 'P';
    _speed = 0;
    _detectedObjects.clear();
    _trail.clear();
    _initGps();
    notifyListeners();
  }

  void _startSimTimer() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_isParked && _simMode) _simDrive();
      _updateObjects();
      notifyListeners();
    });
  }

  double _simTargetSpeed = 60;
  double get simTargetSpeed => _simTargetSpeed;

  void setSimSpeed(double s) {
    _simTargetSpeed = s.clamp(10, 200);
    notifyListeners();
  }

  void _simDrive() {
    final target = _simTargetSpeed + sin(_segmentProgress * pi * 2) * 10;
    _speed += (target - _speed) * 0.02 + (_rng.nextDouble() - 0.5) * 0.5;
    _speed = _speed.clamp(5, 200);
    _power = _speed * 0.5 + (_rng.nextDouble() - 0.3) * 10;
    _batteryLevel -= 0.0002;
    _batteryLevel = _batteryLevel.clamp(0, 100);
    _range = _batteryLevel * 4;

    final route = _activeRoute;
    _segmentProgress += _speed * 0.000015;
    if (_segmentProgress >= 1.0) {
      _segmentProgress -= 1.0;
      _waypointIndex = (_waypointIndex + 1) % (route.length - 1);
      if (_navRoute == null && _waypointIndex < routeStreetNames.length) {
        _currentStreet = routeStreetNames[_waypointIndex];
      }
    }

    final from = route[_waypointIndex];
    final to = route[(_waypointIndex + 1) % route.length];
    _position = LatLng(
      from.latitude + (to.latitude - from.latitude) * _segmentProgress,
      from.longitude + (to.longitude - from.longitude) * _segmentProgress,
    );
    _heading = atan2(to.longitude - from.longitude, to.latitude - from.latitude) * 180 / pi;

    if (_waypointIndex + 2 < route.length) {
      final next = route[_waypointIndex + 2];
      final fh = atan2(next.longitude - to.longitude, next.latitude - to.latitude) * 180 / pi;
      var diff = fh - _heading;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;
      _steeringAngle = (diff * _segmentProgress).clamp(-25, 25);
    }

    _trail.add(_position);
    if (_trail.length > 500) _trail.removeAt(0);
    _tripDistance += _speed * 0.05 / 3600;
  }

  Future<void> _initGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _position = LatLng(pos.latitude, pos.longitude);
      _heading = pos.heading;
      _gpsReady = true;
      notifyListeners();

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 2),
      ).listen((pos) {
        if (_simMode) return;
        _position = LatLng(pos.latitude, pos.longitude);
        if (pos.speed >= 0) _speed = pos.speed * 3.6;
        if (pos.heading >= 0 && pos.speed > 0.5) _heading = pos.heading;
        if (_lastPosition != null && !_isParked) {
          _tripDistance += Geolocator.distanceBetween(
            _lastPosition!.latitude, _lastPosition!.longitude, pos.latitude, pos.longitude) / 1000;
        }
        _trail.add(_position);
        if (_trail.length > 500) _trail.removeAt(0);
        _lastPosition = pos;
        _gpsReady = true;
        _power = _speed * 0.5;
        notifyListeners();
      });
    } catch (_) {}

    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateObjects();
      notifyListeners();
    });
  }

  void _updateObjects() {
    if (_rng.nextDouble() < 0.04 && _detectedObjects.length < 8 && _speed > 5) {
      final types = ['car', 'car', 'car', 'truck', 'pedestrian', 'bike'];
      final lanes = [-0.35, -0.12, 0.12, 0.35];
      _detectedObjects.add(DetectedObject(
        x: lanes[_rng.nextInt(lanes.length)],
        y: 0.15 + _rng.nextDouble() * 0.65,
        type: types[_rng.nextInt(types.length)],
        speed: _speed + (_rng.nextDouble() - 0.5) * 30,
        id: _objId++,
      ));
    }
    _detectedObjects = _detectedObjects.map((o) => DetectedObject(
      x: o.x + (_rng.nextDouble() - 0.5) * 0.002,
      y: o.y - (_speed - o.speed) * 0.00015,
      type: o.type, speed: o.speed, id: o.id,
    )).where((o) => o.y > 0.05 && o.y < 0.95).toList();
  }

  void toggleDrive() {
    _isParked = !_isParked;
    _gear = _isParked ? 'P' : 'D';
    if (!_isParked && !_simMode) { _tripDistance = 0; _trail.clear(); }
    notifyListeners();
  }

  void toggleAc() { _acOn = !_acOn; notifyListeners(); }
  void setInsideTemp(double t) { _insideTemp = t.clamp(16, 30); notifyListeners(); }

  @override
  void dispose() {
    _simTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }
}

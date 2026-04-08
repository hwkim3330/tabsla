import 'package:flutter/material.dart';
import '../data/vehicle_state.dart';
import '../data/sensor_manager.dart';
import '../data/haptics.dart';
import '../widgets/surround_view.dart';
import '../widgets/camera_surround_view.dart';
import '../widgets/map_view.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/sensor_hud.dart';
import '../widgets/media_player.dart';
import '../widgets/energy_graph.dart';
import '../widgets/dashcam.dart';
import '../widgets/car_model_viewer.dart';
import '../widgets/sketchpad.dart';
import '../widgets/mini_game.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _v = VehicleState();
  final _s = SensorManager();
  late AnimationController _anim;
  bool _mapFull = false;
  bool _camMode = false;
  String? _activeApp; // null, 'music', 'energy', 'dashcam', 'car', 'sketch', 'game'

  @override
  void initState() {
    super.initState();
    _v.addListener(_r);
    _s.addListener(_r);
    _v.init().then((_) => _s.init(_v.position));
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  void _r() { if (mounted) setState(() {}); }

  @override
  void dispose() { _anim.dispose(); _v.dispose(); _s.dispose(); super.dispose(); }

  void _closeApp() { Haptics.tap(); setState(() => _activeApp = null); }

  Widget _surround() => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => SurroundView(
      speed: _v.speed, gear: _v.gear, steeringAngle: _v.steeringAngle,
      objects: _v.detectedObjects, animationValue: _anim.value,
      batteryLevel: _v.batteryLevel, range: _v.range,
    ),
  );

  Widget _camera() => CameraSurroundView(
    speed: _v.speed, gear: _v.gear, steeringAngle: _v.steeringAngle,
    objects: _v.detectedObjects, batteryLevel: _v.batteryLevel,
    range: _v.range, power: _v.power,
  );

  Widget _map() => MapView(
    position: _v.position, heading: _v.heading, isMoving: !_v.isParked,
    speed: _v.speed, currentStreet: _v.currentStreet,
    tripDistance: _v.tripDistance, trail: _v.trail,
  );

  Widget _sensorHud() => SensorHud(
    lateralG: _s.lateralG, longitudinalG: _s.longitudinalG, totalG: _s.totalG,
    compass: _s.compassHeading, noiseDb: _s.noiseDb, micActive: _s.micActive,
    roll: _s.roll, pitch: _s.pitch, batteryTemp: _s.batteryTemp,
    outsideTemp: _s.outsideTemp, humidity: _s.humidity,
    windSpeed: _s.windSpeed, weatherDesc: _s.weatherDesc,
    weatherLoaded: _s.weatherLoaded,
  );

  Widget? _buildApp() {
    switch (_activeApp) {
      case 'music': return MediaPlayer(onClose: _closeApp);
      case 'energy': return EnergyGraph(power: _v.power, batteryLevel: _v.batteryLevel, speed: _v.speed, onClose: _closeApp);
      case 'dashcam': return Dashcam(onClose: _closeApp);
      case 'car': return CarModelViewer(batteryLevel: _v.batteryLevel, onClose: _closeApp);
      case 'sketch': return Sketchpad(onClose: _closeApp);
      case 'game': return MiniGame(onClose: _closeApp);
      default: return null;
    }
  }

  Widget _leftDefault() => Stack(
    children: [
      _camMode ? _camera() : _surround(),
      Positioned(right: 6, top: 36, bottom: 100, child: _sensorHud()),
      Positioned(
        top: 8, left: 8,
        child: GestureDetector(
          onTap: () { Haptics.tap(); setState(() => _camMode = !_camMode); },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(7)),
            child: Icon(_camMode ? Icons.view_in_ar_rounded : Icons.videocam_rounded, color: Colors.white.withValues(alpha: 0.45), size: 15),
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final app = _buildApp();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: _mapFull
                ? Stack(
                    children: [
                      _map(),
                      Positioned(top: 8, left: 8,
                        child: GestureDetector(
                          onTap: () { Haptics.tap(); setState(() => _mapFull = false); },
                          child: Container(
                            width: 150, height: 100,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)]),
                            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _surround()),
                          ),
                        ),
                      ),
                      Positioned(top: 8, right: 8,
                        child: _MapBtn(Icons.fullscreen_exit_rounded, () { Haptics.tap(); setState(() => _mapFull = false); })),
                    ],
                  )
                : Row(
                    children: [
                      // Left panel: app or default surround
                      Expanded(child: app ?? _leftDefault()),
                      // Right: map
                      Expanded(
                        child: Stack(
                          children: [
                            _map(),
                            Positioned(top: 8, right: 8,
                              child: _MapBtn(Icons.fullscreen_rounded, () { Haptics.tap(); setState(() => _mapFull = true); })),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          BottomBar(
            insideTemp: _v.insideTemp, acOn: _v.acOn,
            batteryLevel: _v.batteryLevel, range: _v.range,
            isParked: _v.isParked, simMode: _v.simMode,
            activeApp: _activeApp,
            onToggleDrive: () { Haptics.medium(); _v.toggleDrive(); },
            onToggleAc: () { Haptics.tap(); _v.toggleAc(); },
            onToggleSim: () { Haptics.doubleTap(); _v.simMode ? _v.disableSimulation() : _v.enableSimulation(); },
            onAppSelect: (id) { Haptics.tap(); setState(() => _activeApp = id); },
          ),
        ],
      ),
    );
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _MapBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)]),
      child: Icon(icon, size: 18, color: const Color(0xFF374151)),
    ));
  }
}

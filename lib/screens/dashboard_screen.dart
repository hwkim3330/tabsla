import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
import '../widgets/settings_panel.dart';

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
  String? _app; // null, music, energy, dashcam, car, sketch, game, settings

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

  void _close() { Haptics.tap(); setState(() => _app = null); }

  Widget _surround() => SurroundView(
    speed: _v.speed, gear: _v.gear, steeringAngle: _v.steeringAngle,
    objects: _v.detectedObjects, animationValue: 0,
    batteryLevel: _v.batteryLevel, range: _v.range,
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
    onRouteSet: (route, dist, dur) => _v.setNavRoute(route, totalDist: dist, totalDuration: dur),
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
    switch (_app) {
      case 'music': return MediaPlayer(onClose: _close);
      case 'energy': return EnergyGraph(power: _v.power, batteryLevel: _v.batteryLevel, speed: _v.speed, onClose: _close);
      case 'dashcam': return Dashcam(onClose: _close);
      case 'car': return CarModelViewer(batteryLevel: _v.batteryLevel, range: _v.range, onClose: _close);
      case 'sketch': return Sketchpad(onClose: _close);
      case 'game': return MiniGame(onClose: _close);
      case 'settings': return SettingsPanel(
        simMode: _v.simMode, acOn: _v.acOn, insideTemp: _v.insideTemp,
        fanSpeed: 3, batteryLevel: _v.batteryLevel,
        onToggleSimMode: () { _v.simMode ? _v.disableSimulation() : _v.enableSimulation(); },
        onToggleAc: _v.toggleAc,
        onTempChanged: _v.setInsideTemp,
        onFanChanged: (_) {},
        onClose: _close,
      );
      default: return null;
    }
  }

  Widget _leftDefault() => Stack(
    children: [
      _camMode ? _camera() : _surround(),

      // Sensor HUD
      Positioned(right: 6, top: 50, bottom: 60, child: _sensorHud()),

      // Camera toggle
      Positioned(bottom: 12, left: 12, child: _SmallBtn(
        icon: _camMode ? Icons.view_in_ar_rounded : Icons.videocam_rounded,
        onTap: () { Haptics.tap(); setState(() => _camMode = !_camMode); })),

      // Sim speed
      if (_v.simMode && !_camMode)
        Positioned(
          bottom: 8, left: 12, right: 80,
          child: _SimSpeedControl(speed: _v.simTargetSpeed, onChanged: _v.setSimSpeed),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final appWidget = _buildApp();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: _mapFull
                ? Stack(children: [
                    _map(),
                    Positioned(top: 8, left: 8,
                      child: GestureDetector(
                        onTap: () { Haptics.tap(); setState(() => _mapFull = false); },
                        child: Container(width: 150, height: 100,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)]),
                          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _surround()),
                        ),
                      ),
                    ),
                    Positioned(top: 8, right: 8,
                      child: _Btn(Icons.fullscreen_exit_rounded, () { Haptics.tap(); setState(() => _mapFull = false); })),
                  ])
                : Row(children: [
                    Expanded(child: appWidget ?? _leftDefault()),
                    Expanded(child: Stack(children: [
                      _map(),
                      Positioned(top: 8, right: 8,
                        child: _Btn(Icons.fullscreen_rounded, () { Haptics.tap(); setState(() => _mapFull = true); })),
                    ])),
                  ]),
          ),
          BottomBar(
            insideTemp: _v.insideTemp, acOn: _v.acOn,
            batteryLevel: _v.batteryLevel, range: _v.range,
            isParked: _v.isParked, simMode: _v.simMode,
            activeApp: _app,
            onToggleDrive: () { Haptics.medium(); _v.toggleDrive(); },
            onToggleAc: () { Haptics.tap(); _v.toggleAc(); },
            onToggleSim: () { Haptics.doubleTap(); _v.simMode ? _v.disableSimulation() : _v.enableSimulation(); },
            onAppSelect: (id) { Haptics.tap(); setState(() => _app = id); },
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _Btn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)]),
    child: Icon(icon, size: 18, color: const Color(0xFF374151)),
  ));
}


class _SmallBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(7)),
    child: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 15)));
}

class _ModelBtn extends StatelessWidget {
  final String label, id, current;
  final ValueChanged<String> onTap;
  const _ModelBtn(this.label, this.id, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final on = current == id;
    return GestureDetector(onTap: () => onTap(id), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: on ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: on ? Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5), width: 1) : null),
      child: Text(label, style: TextStyle(color: on ? const Color(0xFF60A5FA) : Colors.white38, fontSize: 10, fontWeight: FontWeight.w600))));
  }
}

// Sim speed slider
class _SimSpeedControl extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onChanged;
  const _SimSpeedControl({required this.speed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(speed - 10),
            child: const Icon(Icons.remove_rounded, color: Colors.white54, size: 16),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: const Color(0xFFF59E0B),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                thumbColor: Colors.white,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: speed.clamp(10, 200),
                min: 10, max: 200,
                onChanged: onChanged,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(speed + 10),
            child: const Icon(Icons.add_rounded, color: Colors.white54, size: 16),
          ),
          const SizedBox(width: 6),
          Text('${speed.toInt()}',
            style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w700)),
          Text(' km/h',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9)),
        ],
      ),
    );
  }
}

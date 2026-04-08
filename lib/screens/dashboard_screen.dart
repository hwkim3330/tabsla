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
    onRouteSet: (route) => _v.setNavRoute(route),
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

      // 3D ego car model — bg matches road color at car position
      if (!_camMode)
        Positioned(
          left: 0, right: 0, top: 0, bottom: 0,
          child: LayoutBuilder(builder: (ctx, box) {
            // Road ends at 62%, car center at ~70%
            final carTop = box.maxHeight * 0.56;
            final carLeft = box.maxWidth / 2 - 85;
            return Stack(children: [
              Positioned(
                left: carLeft, top: carTop,
                width: 170, height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _EgoCarModel(steer: _v.steeringAngle),
                ),
              ),
            ]);
          }),
        ),

      // Sensor HUD
      Positioned(right: 6, top: 50, bottom: 60, child: _sensorHud()),

      // Camera toggle
      Positioned(top: 80, left: 16,
        child: GestureDetector(
          onTap: () { Haptics.tap(); setState(() => _camMode = !_camMode); },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(7)),
            child: Icon(_camMode ? Icons.view_in_ar_rounded : Icons.videocam_rounded, color: Colors.white.withValues(alpha: 0.45), size: 15),
          ),
        ),
      ),

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


// 3D ego car — road-color background so box edges invisible
class _EgoCarModel extends StatefulWidget {
  final double steer;
  const _EgoCarModel({required this.steer});
  @override
  State<_EgoCarModel> createState() => _EgoCarModelState();
}

class _EgoCarModelState extends State<_EgoCarModel> {
  late final WebViewController _wv;

  // Road gradient bottom color — must match surround_view road color
  static const _roadColor = Color(0xFF333D4C);

  @override
  void initState() {
    super.initState();
    _wv = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_roadColor)
      ..loadHtmlString('''
<!DOCTYPE html><html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=no">
<script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.4.0/model-viewer.min.js"></script>
<style>*{margin:0;padding:0}body{background:#333D4C;overflow:hidden}
model-viewer{width:100vw;height:100vh;--poster-color:#333D4C}</style>
</head><body>
<model-viewer id="mv"
  src="https://hwkim3330.github.io/tabsla/models/lowpoly_car.glb"
  alt="ego car"
  camera-controls
  camera-orbit="180deg 55deg 2.2m"
  min-camera-orbit="auto 20deg 1m"
  max-camera-orbit="auto 85deg 5m"
  field-of-view="25deg"
  exposure="1.3"
  shadow-intensity="0.6"
  shadow-softness="1"
  environment-image="neutral"
  tone-mapping="commerce"
  interaction-prompt="none"
  touch-action="pan-y"
  style="background:#333D4C"
></model-viewer>
<script>
const mv=document.getElementById('mv');
function setAngle(deg){mv.cameraOrbit=(180+deg)+'deg 55deg 2.2m';}
</script>
</body></html>''');
  }

  @override
  void didUpdateWidget(_EgoCarModel old) {
    super.didUpdateWidget(old);
    if (old.steer != widget.steer) {
      final a = (widget.steer * -2).clamp(-30, 30).toInt();
      _wv.runJavaScript('setAngle($a)');
    }
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _wv);
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

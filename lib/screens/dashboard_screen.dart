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
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  void _r() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _anim.dispose();
    _v.dispose();
    _s.dispose();
    super.dispose();
  }

  void _close() {
    Haptics.tap();
    setState(() => _app = null);
  }

  Widget _surround() => SurroundView(
    speed: _v.speed,
    gear: _v.gear,
    steeringAngle: _v.steeringAngle,
    objects: _v.detectedObjects,
    animationValue: 0,
    batteryLevel: _v.batteryLevel,
    range: _v.range,
  );

  Widget _camera() => CameraSurroundView(
    speed: _v.speed,
    gear: _v.gear,
    steeringAngle: _v.steeringAngle,
    objects: _v.detectedObjects,
    batteryLevel: _v.batteryLevel,
    range: _v.range,
    power: _v.power,
  );

  Widget _map() => MapView(
    position: _v.position,
    heading: _v.heading,
    isMoving: !_v.isParked,
    speed: _v.speed,
    currentStreet: _v.currentStreet,
    tripDistance: _v.tripDistance,
    trail: _v.trail,
    onRouteSet: (route, dist, dur) =>
        _v.setNavRoute(route, totalDist: dist, totalDuration: dur),
  );

  Widget _sensorHud() => SensorHud(
    lateralG: _s.lateralG,
    longitudinalG: _s.longitudinalG,
    totalG: _s.totalG,
    compass: _s.compassHeading,
    noiseDb: _s.noiseDb,
    micActive: _s.micActive,
    roll: _s.roll,
    pitch: _s.pitch,
    batteryTemp: _s.batteryTemp,
    outsideTemp: _s.outsideTemp,
    humidity: _s.humidity,
    windSpeed: _s.windSpeed,
    weatherDesc: _s.weatherDesc,
    weatherLoaded: _s.weatherLoaded,
  );

  Widget? _buildApp() {
    switch (_app) {
      case 'music':
        return MediaPlayer(onClose: _close);
      case 'energy':
        return EnergyGraph(
          power: _v.power,
          batteryLevel: _v.batteryLevel,
          speed: _v.speed,
          onClose: _close,
        );
      case 'dashcam':
        return Dashcam(onClose: _close);
      case 'car':
        return CarModelViewer(
          batteryLevel: _v.batteryLevel,
          range: _v.range,
          onClose: _close,
        );
      case 'sketch':
        return Sketchpad(onClose: _close);
      case 'game':
        return MiniGame(onClose: _close);
      case 'settings':
        return SettingsPanel(
          simMode: _v.simMode,
          acOn: _v.acOn,
          insideTemp: _v.insideTemp,
          fanSpeed: 3,
          batteryLevel: _v.batteryLevel,
          onToggleSimMode: () {
            _v.simMode ? _v.disableSimulation() : _v.enableSimulation();
          },
          onToggleAc: _v.toggleAc,
          onTempChanged: _v.setInsideTemp,
          onFanChanged: (_) {},
          onClose: _close,
        );
      default:
        return null;
    }
  }

  Widget _leftDefault() => Stack(
    children: [
      _camMode ? _camera() : _surround(),

      // Sensor HUD
      Positioned(right: 6, top: 50, bottom: 60, child: _sensorHud()),

      // Camera toggle
      Positioned(
        bottom: 12,
        left: 12,
        child: _SmallBtn(
          icon: _camMode ? Icons.view_in_ar_rounded : Icons.videocam_rounded,
          onTap: () {
            Haptics.tap();
            setState(() => _camMode = !_camMode);
          },
        ),
      ),

      // Sim speed
      if (_v.simMode && !_camMode)
        Positioned(
          bottom: 8,
          left: 12,
          right: 80,
          child: _SimSpeedControl(
            speed: _v.simTargetSpeed,
            onChanged: _v.setSimSpeed,
          ),
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
          _TopStatusBar(
            outsideTemp: _s.weatherLoaded ? _s.outsideTemp : _v.outsideTemp,
            weatherLoaded: _s.weatherLoaded,
            weatherDesc: _s.weatherDesc,
            batteryLevel: _v.batteryLevel,
            range: _v.range,
            simMode: _v.simMode,
          ),
          Expanded(
            child: _mapFull
                ? Stack(
                    children: [
                      _map(),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: () {
                            Haptics.tap();
                            setState(() => _mapFull = false);
                          },
                          child: Container(
                            width: 150,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _surround(),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _Btn(Icons.fullscreen_exit_rounded, () {
                          Haptics.tap();
                          setState(() => _mapFull = false);
                        }),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: appWidget == null
                            ? _leftDefault()
                            : _AppSurface(child: appWidget),
                      ),
                      Container(width: 1, color: const Color(0xFFDDE1E6)),
                      Expanded(
                        child: Stack(
                          children: [
                            _map(),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _Btn(Icons.fullscreen_rounded, () {
                                Haptics.tap();
                                setState(() => _mapFull = true);
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          BottomBar(
            insideTemp: _v.insideTemp,
            acOn: _v.acOn,
            batteryLevel: _v.batteryLevel,
            range: _v.range,
            isParked: _v.isParked,
            simMode: _v.simMode,
            activeApp: _app,
            onToggleDrive: () {
              Haptics.medium();
              _v.toggleDrive();
            },
            onToggleAc: () {
              Haptics.tap();
              _v.toggleAc();
            },
            onToggleSim: () {
              Haptics.doubleTap();
              _v.simMode ? _v.disableSimulation() : _v.enableSimulation();
            },
            onAppSelect: (id) {
              Haptics.tap();
              setState(() => _app = id);
            },
          ),
        ],
      ),
    );
  }
}

class _AppSurface extends StatelessWidget {
  final Widget child;
  const _AppSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8EBEF),
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  final double outsideTemp;
  final bool weatherLoaded;
  final String weatherDesc;
  final double batteryLevel;
  final double range;
  final bool simMode;

  const _TopStatusBar({
    required this.outsideTemp,
    required this.weatherLoaded,
    required this.weatherDesc,
    required this.batteryLevel,
    required this.range,
    required this.simMode,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE6E8EB), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, size: 15, color: Color(0xFF3B3F45)),
          const SizedBox(width: 10),
          Icon(
            _weatherIcon(weatherDesc),
            size: 15,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 4),
          Text(
            weatherLoaded ? '${outsideTemp.toInt()}°' : '--°',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B3F45),
            ),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.person_rounded, size: 15, color: Color(0xFF6B7280)),
          const SizedBox(width: 4),
          const Text(
            'Parksik',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B3F45),
            ),
          ),
          if (simMode) ...[
            const SizedBox(width: 10),
            _StatusPill(icon: Icons.route_rounded, label: 'Sim'),
          ],
          const Spacer(),
          Icon(
            Icons.battery_std_rounded,
            size: 15,
            color: batteryLevel > 30
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 3),
          Text(
            '${batteryLevel.toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: batteryLevel > 30
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${range.toInt()} km',
            style: const TextStyle(fontSize: 11, color: Color(0xFF8B929A)),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.wifi_rounded, size: 15, color: Color(0xFF6B7280)),
          const SizedBox(width: 10),
          const Icon(
            Icons.signal_cellular_alt_rounded,
            size: 14,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B3F45),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _weatherIcon(String desc) {
    switch (desc) {
      case 'Clear':
        return Icons.wb_sunny_rounded;
      case 'Rain':
      case 'Drizzle':
      case 'Showers':
        return Icons.water_drop_rounded;
      case 'Snow':
        return Icons.ac_unit_rounded;
      default:
        return Icons.cloud_rounded;
    }
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatusPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11, color: const Color(0xFF2563EB)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
        ],
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF374151)),
    ),
  );
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 15),
    ),
  );
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
            child: const Icon(
              Icons.remove_rounded,
              color: Colors.white54,
              size: 16,
            ),
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
                min: 10,
                max: 200,
                onChanged: onChanged,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(speed + 10),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white54,
              size: 16,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${speed.toInt()}',
            style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            ' km/h',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

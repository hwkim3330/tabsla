import 'dart:math';
import 'package:flutter/material.dart';

class SensorHud extends StatelessWidget {
  final double lateralG, longitudinalG, totalG;
  final double compass;
  final double noiseDb;
  final bool micActive;
  final double roll, pitch;
  final double batteryTemp;
  final double outsideTemp;
  final double humidity;
  final double windSpeed;
  final String weatherDesc;
  final bool weatherLoaded;

  const SensorHud({
    super.key,
    required this.lateralG, required this.longitudinalG, required this.totalG,
    required this.compass, required this.noiseDb, required this.micActive,
    required this.roll, required this.pitch,
    required this.batteryTemp, required this.outsideTemp,
    required this.humidity, required this.windSpeed,
    required this.weatherDesc, required this.weatherLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // G-Force
          SizedBox(
            width: 72, height: 72,
            child: CustomPaint(painter: _GForcePainter(latG: lateralG.clamp(-2, 2), lonG: longitudinalG.clamp(-2, 2))),
          ),
          const SizedBox(height: 2),
          _Label('${totalG.toStringAsFixed(1)}G', color: totalG > 1.3 ? const Color(0xFFF59E0B) : null),
          const SizedBox(height: 10),

          // Compass
          _Row(Icons.explore_rounded, '${compass.toInt()}° ${_dir(compass)}'),

          // Tilt
          _Row(Icons.screen_rotation_rounded, '${(roll * 180 / pi).toStringAsFixed(0)}° tilt'),

          // Noise
          if (micActive)
            _Row(Icons.mic_rounded, '${noiseDb.toInt()} dB',
              color: noiseDb > 75 ? const Color(0xFFF59E0B) : null),

          const SizedBox(height: 8),
          // Divider
          Container(width: 40, height: 0.5, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 8),

          // Battery temp
          if (batteryTemp > 0)
            _Row(Icons.thermostat_rounded, '${batteryTemp.toStringAsFixed(1)}°C',
              sub: 'device', color: batteryTemp > 40 ? const Color(0xFFEF4444) : null),

          // Weather
          if (weatherLoaded) ...[
            _Row(_weatherIcon(weatherDesc), '${outsideTemp.toStringAsFixed(1)}°C', sub: 'outside'),
            _Row(Icons.water_drop_rounded, '${humidity.toInt()}%', sub: 'humid'),
            _Row(Icons.air_rounded, '${windSpeed.toStringAsFixed(0)} km/h', sub: 'wind'),
          ],
        ],
      ),
    );
  }

  String _dir(double h) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((h + 22.5) % 360 / 45).floor()];
  }

  IconData _weatherIcon(String desc) {
    switch (desc) {
      case 'Clear': return Icons.wb_sunny_rounded;
      case 'Cloudy': return Icons.cloud_rounded;
      case 'Rain': case 'Drizzle': case 'Showers': return Icons.water_drop_rounded;
      case 'Snow': return Icons.ac_unit_rounded;
      case 'Storm': return Icons.thunderstorm_rounded;
      default: return Icons.cloud_rounded;
    }
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color? color;
  const _Label(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(
      color: color ?? Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w600));
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? sub;
  final Color? color;
  const _Row(this.icon, this.value, {this.sub, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white.withValues(alpha: 0.3);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sub != null)
            Text('$sub ', style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 8)),
          Text(value, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Icon(icon, size: 11, color: c),
        ],
      ),
    );
  }
}

class _GForcePainter extends CustomPainter {
  final double latG, lonG;
  _GForcePainter({required this.latG, required this.lonG});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width / 2 - 3;

    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white.withValues(alpha: 0.04));
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = Colors.white.withValues(alpha: 0.08)..style = PaintingStyle.stroke..strokeWidth = 0.5);
    canvas.drawCircle(Offset(cx, cy), r * 0.5, Paint()
      ..color = Colors.white.withValues(alpha: 0.05)..style = PaintingStyle.stroke..strokeWidth = 0.5);

    // Crosshair
    final ch = Paint()..color = Colors.white.withValues(alpha: 0.04)..strokeWidth = 0.5;
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), ch);
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), ch);

    // Dot
    final dx = (latG / 2) * r;
    final dy = (lonG / 2) * r;
    final mag = sqrt(latG * latG + lonG * lonG);
    final dotC = mag > 0.5 ? const Color(0xFFF59E0B) : const Color(0xFF60A5FA);

    canvas.drawCircle(Offset(cx + dx, cy + dy), 5, Paint()
      ..color = dotC.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(Offset(cx + dx, cy + dy), 2.5, Paint()..color = dotC);
  }

  @override
  bool shouldRepaint(covariant _GForcePainter old) => true;
}

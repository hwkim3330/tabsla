import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/vehicle_state.dart';

class SurroundView extends StatelessWidget {
  final double speed;
  final String gear;
  final double steeringAngle;
  final List<DetectedObject> objects;
  final double animationValue;
  final double batteryLevel;
  final double range;

  const SurroundView({
    super.key,
    required this.speed, required this.gear, required this.steeringAngle,
    required this.objects, required this.animationValue,
    required this.batteryLevel, required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF0C1018), Color(0xFF141B26), Color(0xFF1A2332)],
        ),
      ),
      child: Stack(
        children: [
          // Road + lanes + detected objects
          CustomPaint(
            size: Size.infinite,
            painter: _RoadPainter(
              speed: speed, steer: steeringAngle,
              objects: objects, anim: animationValue,
            ),
          ),

          // === TOP LEFT: Speed + Gear + Speed Limit (Tesla layout) ===
          Positioned(
            top: 12, left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gear row
                Row(
                  children: ['P','R','N','D'].map((g) {
                    final active = gear == g;
                    return Container(
                      width: 22, height: 22,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(child: Text(g, style: TextStyle(
                        color: active ? const Color(0xFF0C1018) : Colors.white.withValues(alpha: 0.15),
                        fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w400, height: 1))),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                // Speed
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      speed.toInt().toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w300, height: 1, letterSpacing: -3),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text('km/h', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Speed limit sign
                if (speed > 0)
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white,
                      border: Border.all(color: const Color(0xFFDC2626), width: 2.5)),
                    child: const Center(child: Text('60', style: TextStyle(color: Color(0xFF1F2937), fontSize: 10, fontWeight: FontWeight.w800, height: 1))),
                  ),
              ],
            ),
          ),

          // === TOP RIGHT: Battery ===
          Positioned(
            top: 12, right: 14,
            child: Row(children: [
              Text('${range.toInt()} km', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11)),
              const SizedBox(width: 6),
              SizedBox(width: 32, height: 13, child: CustomPaint(painter: _BattPainter(batteryLevel / 100))),
            ]),
          ),

          // === Detection count ===
          if (objects.isNotEmpty)
            Positioned(
              top: 12, right: 14,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34D399))),
                  const SizedBox(width: 4),
                  Text('${objects.length}', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _BattPainter extends CustomPainter {
  final double lvl;
  _BattPainter(this.lvl);
  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s.width - 2, s.height), const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.12)..style = PaintingStyle.stroke..strokeWidth = 1);
    c.drawRect(Rect.fromLTWH(s.width - 2, s.height * 0.3, 2, s.height * 0.4), Paint()..color = Colors.white.withValues(alpha: 0.12));
    final col = lvl > 0.3 ? const Color(0xFF34D399) : const Color(0xFFEF4444);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(1.5, 1.5, (s.width - 5) * lvl, s.height - 3), const Radius.circular(1)), Paint()..color = col);
  }
  @override
  bool shouldRepaint(covariant _BattPainter o) => o.lvl != lvl;
}

class _RoadPainter extends CustomPainter {
  final double speed, steer, anim;
  final List<DetectedObject> objects;
  _RoadPainter({required this.speed, required this.steer, required this.objects, required this.anim});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final h = size.height * 0.15; // horizon higher up
    final b = size.height * 0.65; // road ends at 65% (car sits below)
    final vx = cx + steer * 2;

    _drawRoad(canvas, size, cx, h, b, vx);
    _drawLanes(canvas, size, cx, h, b, vx);

    // Detected objects
    final sorted = List<DetectedObject>.from(objects)..sort((a, b) => a.y.compareTo(b.y));
    for (final o in sorted) _drawVehicle(canvas, size, o, cx, h, b, vx);

    // Ego car shadow/ground indicator
    _drawEgoGround(canvas, size, cx);
  }

  void _drawRoad(Canvas c, Size s, double cx, double h, double b, double vx) {
    final wt = 60.0, wb = s.width * 0.85;
    final road = Path()
      ..moveTo(vx - wt / 2, h)..lineTo(vx + wt / 2, h)
      ..lineTo(cx + wb / 2, b)..lineTo(cx - wb / 2, b)..close();
    c.drawPath(road, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF222A36), Color(0xFF2A3342)],
    ).createShader(Rect.fromLTWH(0, h, s.width, b - h)));

    final edge = Paint()..color = Colors.white.withValues(alpha: 0.18)..strokeWidth = 1.5;
    c.drawLine(Offset(vx - wt / 2, h), Offset(cx - wb / 2, b), edge);
    c.drawLine(Offset(vx + wt / 2, h), Offset(cx + wb / 2, b), edge);
  }

  void _drawLanes(Canvas c, Size s, double cx, double h, double b, double vx) {
    for (final off in [-0.25, 0.0, 0.25]) {
      final flow = (anim * 2.5) % 1.0;
      for (int i = 0; i < 14; i++) {
        final t1 = ((i + flow) / 14).clamp(0.0, 1.0);
        final t2 = ((i + flow + 0.2) / 14).clamp(0.0, 1.0);
        if (t1 >= 1.0) continue;
        final p1 = pow(t1, 1.6).toDouble(), p2 = pow(t2, 1.6).toDouble();
        final w1 = lerpDouble(60, s.width * 0.85, p1)!;
        final w2 = lerpDouble(60, s.width * 0.85, p2)!;
        final x1 = lerpDouble(vx, cx, p1)! + off * w1 / 2;
        final y1 = lerpDouble(h, b, p1)!;
        final x2 = lerpDouble(vx, cx, p2)! + off * w2 / 2;
        final y2 = lerpDouble(h, b, p2)!;
        c.drawLine(Offset(x1, y1), Offset(x2, y2), Paint()
          ..color = Colors.white.withValues(alpha: (p1 * 0.35).clamp(0.02, 0.22))
          ..strokeWidth = 1 + p1 * 2..strokeCap = StrokeCap.round);
      }
    }
  }

  void _drawEgoGround(Canvas c, Size s, double cx) {
    // Shadow/glow on road where the 3D model overlays
    final y = s.height * 0.72;
    c.drawOval(Rect.fromCenter(center: Offset(cx, y), width: 70, height: 12),
      Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.06)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // Headlight beams going forward (upward on screen)
    final beam = Path()
      ..moveTo(cx - 18, y - 15)
      ..lineTo(cx - 40, s.height * 0.2)
      ..lineTo(cx + 40, s.height * 0.2)
      ..lineTo(cx + 18, y - 15)
      ..close();
    c.drawPath(beam, Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.02));
  }

  void _drawVehicle(Canvas c, Size s, DetectedObject o, double cx, double h, double b, double vx) {
    final p = pow(o.y, 1.6).toDouble();
    final rw = lerpDouble(60, s.width * 0.85, p)!;
    final bx = lerpDouble(vx, cx, p)!;
    final x = bx + o.x * rw;
    final y = lerpDouble(h, b, p)!;
    final sc = 0.25 + p * 0.75;

    Color col;
    switch (o.type) {
      case 'car': col = const Color(0xFF60A5FA); break;
      case 'truck': case 'bus': col = const Color(0xFFFBBF24); break;
      case 'pedestrian': col = const Color(0xFFF87171); break;
      case 'bike': col = const Color(0xFF34D399); break;
      default: col = const Color(0xFF94A3B8);
    }

    if (o.type == 'car') {
      final w = 18 * sc, vh = 28 * sc;
      final body = Path()
        ..moveTo(x - w * 0.42, y)
        ..cubicTo(x - w * 0.45, y - vh * 0.3, x - w * 0.4, y - vh * 0.7, x, y - vh)
        ..cubicTo(x + w * 0.4, y - vh * 0.7, x + w * 0.45, y - vh * 0.3, x + w * 0.42, y)
        ..close();
      c.drawPath(body, Paint()..color = col.withValues(alpha: 0.15));
      c.drawPath(body, Paint()..color = col.withValues(alpha: 0.45)..style = PaintingStyle.stroke..strokeWidth = 1);
      c.drawCircle(Offset(x - w * 0.25, y - 1), 1.2 * sc, Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.6));
      c.drawCircle(Offset(x + w * 0.25, y - 1), 1.2 * sc, Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.6));
    } else if (o.type == 'truck' || o.type == 'bus') {
      final w = 22 * sc, vh = 40 * sc;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - w / 2, y - vh, w, vh), Radius.circular(2 * sc)),
        Paint()..color = col.withValues(alpha: 0.1));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - w / 2, y - vh, w, vh), Radius.circular(2 * sc)),
        Paint()..color = col.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 1);
    } else if (o.type == 'pedestrian') {
      final ph = 16 * sc;
      final paint = Paint()..color = col.withValues(alpha: 0.55)..strokeWidth = 1.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      c.drawCircle(Offset(x, y - ph), 2.5 * sc, paint);
      c.drawLine(Offset(x, y - ph + 3 * sc), Offset(x, y - ph * 0.35), paint);
      c.drawLine(Offset(x, y - ph * 0.35), Offset(x - 3 * sc, y), paint);
      c.drawLine(Offset(x, y - ph * 0.35), Offset(x + 3 * sc, y), paint);
    } else if (o.type == 'bike') {
      final paint = Paint()..color = col.withValues(alpha: 0.55)..strokeWidth = 1.2..style = PaintingStyle.stroke;
      c.drawCircle(Offset(x, y - 2 * sc), 3 * sc, paint);
      c.drawCircle(Offset(x, y - 16 * sc), 3 * sc, paint);
      c.drawLine(Offset(x, y - 2 * sc), Offset(x, y - 16 * sc), paint);
      c.drawCircle(Offset(x, y - 20 * sc), 2.5 * sc, paint);
    }

    // Distance
    final dist = ((1 - o.y) * 80 + 5).toInt();
    final tp = TextPainter(
      text: TextSpan(text: '${dist}m', style: TextStyle(color: col.withValues(alpha: 0.35), fontSize: 6 + sc * 3, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x - tp.width / 2, y - 30 * sc - 8));
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) => true;
}

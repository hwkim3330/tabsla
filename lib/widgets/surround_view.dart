import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/vehicle_state.dart';

class SurroundView extends StatelessWidget {
  final double speed, steeringAngle, batteryLevel, range, animationValue;
  final String gear;
  final List<DetectedObject> objects;

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
          colors: [Color(0xFF080C14), Color(0xFF101824), Color(0xFF182030)],
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _DrivePainter(speed: speed, steer: steeringAngle, objects: objects, anim: animationValue),
          ),
          // HUD — Tesla layout: gear + speed top-left
          Positioned(top: 12, left: 16, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: ['P','R','N','D'].map((g) {
                final on = gear == g;
                return Container(
                  width: 24, height: 24, margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(5)),
                  child: Center(child: Text(g, style: TextStyle(
                    color: on ? const Color(0xFF080C14) : Colors.white.withValues(alpha: 0.12),
                    fontSize: 12, fontWeight: on ? FontWeight.w800 : FontWeight.w400, height: 1))),
                );
              }).toList()),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(speed.toInt().toString(), style: const TextStyle(
                  color: Colors.white, fontSize: 56, fontWeight: FontWeight.w200, height: 1, letterSpacing: -3)),
                Padding(padding: const EdgeInsets.only(bottom: 6, left: 5),
                  child: Text('km/h', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13))),
              ]),
              if (speed > 0) ...[
                const SizedBox(height: 8),
                Container(width: 30, height: 30,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                    border: Border.all(color: const Color(0xFFDC2626), width: 3)),
                  child: const Center(child: Text('60', style: TextStyle(color: Color(0xFF1F2937), fontSize: 11, fontWeight: FontWeight.w800, height: 1)))),
              ],
            ],
          )),
          Positioned(top: 12, right: 14, child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                Icon(Icons.battery_std, size: 15, color: batteryLevel > 30 ? const Color(0xFF34D399) : const Color(0xFFEF4444)),
                const SizedBox(width: 3),
                Text('${batteryLevel.toInt()}%', style: TextStyle(
                  color: batteryLevel > 30 ? const Color(0xFF34D399) : const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 2),
              Text('${range.toInt()} km', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10)),
              if (objects.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34D399))),
                  const SizedBox(width: 4),
                  Text('${objects.length}', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10)),
                ]),
              ],
            ],
          )),
        ],
      ),
    );
  }
}

class _DrivePainter extends CustomPainter {
  final double speed, steer, anim;
  final List<DetectedObject> objects;
  _DrivePainter({required this.speed, required this.steer, required this.objects, required this.anim});

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final h = s.height * 0.20;
    final re = s.height * 0.58;
    final vx = cx + steer * 2.5;
    final wt = 65.0, wb = s.width * 0.88;

    _road(c, s, cx, h, re, vx, wt, wb);
    _buildings(c, s, cx, h, re, vx, wt, wb);
    _lanes(c, s, cx, h, re, vx, wt, wb);
    if (speed > 1) _autopilot(c, s, cx, h, re, vx);

    final sorted = List<DetectedObject>.from(objects)..sort((a, b) => a.y.compareTo(b.y));
    for (final o in sorted) _vehicle(c, s, o, cx, h, re, vx, wt, wb);

    // Ego car shadow only — 3D model overlays on top
    final ey = re + s.height * 0.18;
    c.drawOval(Rect.fromCenter(center: Offset(cx, ey + 6), width: 72, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // Headlight beam
    c.drawPath(Path()..moveTo(cx - 18, ey - 45)..lineTo(cx - 45, ey - 110)
      ..lineTo(cx + 45, ey - 110)..lineTo(cx + 18, ey - 45)..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.01));
  }

  void _road(Canvas c, Size s, double cx, double h, double re, double vx, double wt, double wb) {
    // Grass
    c.drawRect(Rect.fromLTWH(0, h - 5, s.width, re - h + 10), Paint()..color = const Color(0xFF0D1A10));

    // Shoulder
    for (final side in [-1.0, 1.0]) {
      final sh = Path()
        ..moveTo(vx + side * wt / 2, h)..lineTo(vx + side * (wt / 2 + 12), h)
        ..lineTo(cx + side * (wb / 2 + 25), re)..lineTo(cx + side * wb / 2, re)..close();
      c.drawPath(sh, Paint()..color = const Color(0xFF1A2430));
    }

    // Road
    final rd = Path()..moveTo(vx - wt / 2, h)..lineTo(vx + wt / 2, h)
      ..lineTo(cx + wb / 2, re)..lineTo(cx - wb / 2, re)..close();
    c.drawPath(rd, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xFF232B38), const Color(0xFF2C3544), const Color(0xFF343E4E)],
    ).createShader(Rect.fromLTWH(0, h, s.width, re - h)));

    // Edges
    final ep = Paint()..color = Colors.white.withValues(alpha: 0.35)..strokeWidth = 2;
    c.drawLine(Offset(vx - wt / 2, h), Offset(cx - wb / 2, re), ep);
    c.drawLine(Offset(vx + wt / 2, h), Offset(cx + wb / 2, re), ep);

    // Road below car (extension)
    final belowRd = Paint()..color = const Color(0xFF343E4E);
    c.drawRect(Rect.fromLTWH(cx - wb / 2, re, wb, s.height - re), belowRd);
  }

  void _buildings(Canvas c, Size s, double cx, double h, double re, double vx, double wt, double wb) {
    final rng = Random(42);
    for (final side in [-1.0, 1.0]) {
      for (int i = 0; i < 8; i++) {
        final t = i / 8.0;
        final p = pow(t, 1.5).toDouble();
        final rw = lerpDouble(wt, wb, p)!;
        final bx = lerpDouble(vx, cx, p)!;
        final y = lerpDouble(h, re, p)!;
        final ex = bx + side * (rw / 2 + 15 + rng.nextDouble() * 20);
        final bH = (12 + rng.nextDouble() * 28) * (1 - p * 0.3);
        final bW = 6 + rng.nextDouble() * 12;
        final a = (0.08 - p * 0.04).clamp(0.01, 0.08);

        c.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(ex - bW / 2, y - bH, bW, bH), const Radius.circular(1)),
          Paint()..color = Color.fromRGBO(20, 30, 45, a));

        // Windows
        if (bH > 15) {
          for (double wy = y - bH + 3; wy < y - 2; wy += 5) {
            for (double wx = ex - bW / 3; wx <= ex + bW / 3; wx += 4) {
              if (rng.nextDouble() > 0.45) {
                c.drawRect(Rect.fromLTWH(wx, wy, 2, 2.5),
                  Paint()..color = Color.fromRGBO(80, 120, 180, a * 0.6));
              }
            }
          }
        }
        // Tree
        if (rng.nextDouble() > 0.5) {
          final tx = ex + side * (bW / 2 + 4);
          c.drawCircle(Offset(tx, y - 5 - rng.nextDouble() * 8), 2 + p * 3,
            Paint()..color = Color.fromRGBO(18, 40, 22, a * 1.5));
        }
      }
    }
  }

  void _lanes(Canvas c, Size s, double cx, double h, double re, double vx, double wt, double wb) {
    for (final off in [-0.25, 0.0, 0.25]) {
      final flow = (anim * 2.5) % 1.0;
      for (int i = 0; i < 14; i++) {
        final t1 = ((i + flow) / 14).clamp(0.0, 1.0);
        final t2 = ((i + flow + 0.2) / 14).clamp(0.0, 1.0);
        if (t1 >= 1.0) continue;
        final p1 = pow(t1, 1.6).toDouble(), p2 = pow(t2, 1.6).toDouble();
        final w1 = lerpDouble(wt, wb, p1)!, w2 = lerpDouble(wt, wb, p2)!;
        final x1 = lerpDouble(vx, cx, p1)! + off * w1 / 2;
        final y1 = lerpDouble(h, re, p1)!;
        final x2 = lerpDouble(vx, cx, p2)! + off * w2 / 2;
        final y2 = lerpDouble(h, re, p2)!;
        c.drawLine(Offset(x1, y1), Offset(x2, y2), Paint()
          ..color = Colors.white.withValues(alpha: (p1 * 0.3).clamp(0.02, 0.2))
          ..strokeWidth = 1 + p1 * 2..strokeCap = StrokeCap.round);
      }
    }
  }

  void _autopilot(Canvas c, Size s, double cx, double h, double re, double vx) {
    final path = Path();
    for (int i = 0; i <= 30; i++) {
      final t = i / 30.0;
      final p = pow(t, 1.6).toDouble();
      final bx = lerpDouble(vx, cx, p)!;
      final y = lerpDouble(h, re, p)!;
      if (i == 0) path.moveTo(bx, y); else path.lineTo(bx, y);
    }
    c.drawPath(path, Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke..strokeWidth = 20..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    c.drawPath(path, Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
  }

  void _ego(Canvas c, Size s, double cx, double re) {
    final x = cx, y = re + s.height * 0.18;
    final w = 54.0, h = 105.0;

    // Shadow
    c.drawOval(Rect.fromCenter(center: Offset(x, y + 6), width: w + 18, height: 16),
      Paint()..color = Colors.black.withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Body
    final body = Path()
      ..moveTo(x - w * 0.40, y + h * 0.06)
      ..cubicTo(x - w * 0.44, y - h * 0.05, x - w * 0.46, y - h * 0.2, x - w * 0.42, y - h * 0.35)
      ..cubicTo(x - w * 0.38, y - h * 0.5, x - w * 0.28, y - h * 0.65, x - w * 0.15, y - h * 0.78)
      ..cubicTo(x - w * 0.06, y - h * 0.87, x + w * 0.06, y - h * 0.87, x + w * 0.15, y - h * 0.78)
      ..cubicTo(x + w * 0.28, y - h * 0.65, x + w * 0.38, y - h * 0.5, x + w * 0.42, y - h * 0.35)
      ..cubicTo(x + w * 0.46, y - h * 0.2, x + w * 0.44, y - h * 0.05, x + w * 0.40, y + h * 0.06)
      ..close();

    // Body fill gradient
    c.drawPath(body, Paint()..shader = LinearGradient(
      begin: Alignment.centerLeft, end: Alignment.centerRight,
      colors: [const Color(0xFF18222E), const Color(0xFF243040), const Color(0xFF2A3850), const Color(0xFF243040), const Color(0xFF18222E)],
    ).createShader(Rect.fromCenter(center: Offset(x, y - h * 0.4), width: w, height: h)));

    // Glow outline
    c.drawPath(body, Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke..strokeWidth = 4..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    c.drawPath(body, Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // Windshield
    final ws = Path()
      ..moveTo(x - w * 0.26, y - h * 0.48)
      ..quadraticBezierTo(x, y - h * 0.57, x + w * 0.26, y - h * 0.48)
      ..lineTo(x + w * 0.23, y - h * 0.38)
      ..quadraticBezierTo(x, y - h * 0.40, x - w * 0.23, y - h * 0.38)..close();
    c.drawPath(ws, Paint()..color = const Color(0xFF4488CC).withValues(alpha: 0.1));

    // Rear window
    final rw = Path()
      ..moveTo(x - w * 0.24, y - h * 0.04)
      ..quadraticBezierTo(x, y - h * 0.11, x + w * 0.24, y - h * 0.04)
      ..lineTo(x + w * 0.22, y + h * 0.02)
      ..quadraticBezierTo(x, y + h * 0.01, x - w * 0.22, y + h * 0.02)..close();
    c.drawPath(rw, Paint()..color = const Color(0xFF4488CC).withValues(alpha: 0.06));

    // Roof
    final rf = Path()
      ..moveTo(x - w * 0.23, y - h * 0.38)..lineTo(x - w * 0.24, y - h * 0.04)
      ..quadraticBezierTo(x, y - h * 0.07, x + w * 0.24, y - h * 0.04)
      ..lineTo(x + w * 0.23, y - h * 0.38)
      ..quadraticBezierTo(x, y - h * 0.40, x - w * 0.23, y - h * 0.38)..close();
    c.drawPath(rf, Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.02));

    // Wheels
    final wp = Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.18);
    for (final p in [Offset(x - w * 0.48, y - h * 0.07), Offset(x + w * 0.48, y - h * 0.07),
                      Offset(x - w * 0.45, y - h * 0.55), Offset(x + w * 0.45, y - h * 0.55)]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 7, height: 16), const Radius.circular(3)), wp);
    }

    // Headlights
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x - w * 0.28, y - h * 0.82), width: 9, height: 3), const Radius.circular(1.5)),
      Paint()..color = Colors.white.withValues(alpha: 0.5));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + w * 0.28, y - h * 0.82), width: 9, height: 3), const Radius.circular(1.5)),
      Paint()..color = Colors.white.withValues(alpha: 0.5));

    // Tail lights
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x - w * 0.32, y + h * 0.05), width: 11, height: 2.5), const Radius.circular(1)),
      Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.5));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + w * 0.32, y + h * 0.05), width: 11, height: 2.5), const Radius.circular(1)),
      Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.5));

    // Headlight beam
    c.drawPath(Path()..moveTo(x - w * 0.2, y - h * 0.87)
      ..lineTo(x - w * 0.5, y - h * 0.87 - 65)..lineTo(x + w * 0.5, y - h * 0.87 - 65)
      ..lineTo(x + w * 0.2, y - h * 0.87)..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.012));
  }

  void _vehicle(Canvas c, Size s, DetectedObject o, double cx, double h, double re, double vx, double wt, double wb) {
    final p = pow(o.y, 1.6).toDouble();
    final rw = lerpDouble(wt, wb, p)!;
    final bx = lerpDouble(vx, cx, p)!;
    final x = bx + o.x * rw;
    final y = lerpDouble(h, re, p)!;
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
      final w = 16 * sc, vh = 26 * sc;
      final bd = Path()
        ..moveTo(x - w * 0.4, y)
        ..cubicTo(x - w * 0.45, y - vh * 0.3, x - w * 0.38, y - vh * 0.65, x, y - vh)
        ..cubicTo(x + w * 0.38, y - vh * 0.65, x + w * 0.45, y - vh * 0.3, x + w * 0.4, y)..close();
      c.drawPath(bd, Paint()..color = col.withValues(alpha: 0.1));
      c.drawPath(bd, Paint()..color = col.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 1);
      c.drawRect(Rect.fromCenter(center: Offset(x - w * 0.25, y - 1), width: 3 * sc, height: 1.5 * sc), Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.4));
      c.drawRect(Rect.fromCenter(center: Offset(x + w * 0.25, y - 1), width: 3 * sc, height: 1.5 * sc), Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.4));
    } else if (o.type == 'truck' || o.type == 'bus') {
      final w = 20 * sc, vh = 38 * sc;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - w / 2, y - vh, w, vh), Radius.circular(2 * sc)),
        Paint()..color = col.withValues(alpha: 0.08));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - w / 2, y - vh, w, vh), Radius.circular(2 * sc)),
        Paint()..color = col.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1);
    } else if (o.type == 'pedestrian') {
      final ph = 14 * sc;
      final pt = Paint()..color = col.withValues(alpha: 0.45)..strokeWidth = 1.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      c.drawCircle(Offset(x, y - ph), 2.5 * sc, pt);
      c.drawLine(Offset(x, y - ph + 3 * sc), Offset(x, y - ph * 0.35), pt);
      c.drawLine(Offset(x, y - ph * 0.35), Offset(x - 3 * sc, y), pt);
      c.drawLine(Offset(x, y - ph * 0.35), Offset(x + 3 * sc, y), pt);
    } else {
      final pt = Paint()..color = col.withValues(alpha: 0.45)..strokeWidth = 1.2..style = PaintingStyle.stroke;
      c.drawCircle(Offset(x, y - 2 * sc), 3 * sc, pt);
      c.drawLine(Offset(x, y - 2 * sc), Offset(x, y - 14 * sc), pt);
      c.drawCircle(Offset(x, y - 18 * sc), 2.5 * sc, pt);
    }

    final dist = ((1 - o.y) * 80 + 5).toInt();
    final tp = TextPainter(
      text: TextSpan(text: '${dist}m', style: TextStyle(color: col.withValues(alpha: 0.25), fontSize: 6 + sc * 3, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x - tp.width / 2, y - 28 * sc - 8));
  }

  @override
  bool shouldRepaint(covariant _DrivePainter old) => true;
}

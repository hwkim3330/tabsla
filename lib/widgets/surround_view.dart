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
          colors: [Color(0xFF0B0F16), Color(0xFF121820), Color(0xFF182030)],
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _DrivePainter(
              speed: speed, steer: steeringAngle, objects: objects, anim: animationValue,
            ),
          ),
          // Speed + Gear — top left (Tesla style)
          Positioned(top: 12, left: 16, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gear row
              Row(children: ['P','R','N','D'].map((g) {
                final on = gear == g;
                return Container(
                  width: 22, height: 22, margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: on ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(4)),
                  child: Center(child: Text(g, style: TextStyle(
                    color: on ? const Color(0xFF0B0F16) : Colors.white.withValues(alpha: 0.12),
                    fontSize: 11, fontWeight: on ? FontWeight.w800 : FontWeight.w400, height: 1))),
                );
              }).toList()),
              const SizedBox(height: 6),
              // Speed
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(speed.toInt().toString(), style: const TextStyle(
                  color: Colors.white, fontSize: 52, fontWeight: FontWeight.w300, height: 1, letterSpacing: -3)),
                Padding(padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Text('km/h', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12))),
              ]),
              const SizedBox(height: 6),
              if (speed > 0) Container(
                width: 28, height: 28,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                  border: Border.all(color: const Color(0xFFDC2626), width: 2.5)),
                child: const Center(child: Text('60', style: TextStyle(
                  color: Color(0xFF1F2937), fontSize: 10, fontWeight: FontWeight.w800, height: 1))),
              ),
            ],
          )),
          // Battery — top right
          Positioned(top: 12, right: 14, child: Row(children: [
            Text('${range.toInt()} km', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11)),
            const SizedBox(width: 6),
            SizedBox(width: 32, height: 13, child: CustomPaint(painter: _BattPainter(batteryLevel / 100))),
          ])),
          // Detection count
          if (objects.isNotEmpty)
            Positioned(top: 32, right: 14, child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34D399))),
              const SizedBox(width: 4),
              Text('${objects.length}', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10)),
            ])),
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

class _DrivePainter extends CustomPainter {
  final double speed, steer, anim;
  final List<DetectedObject> objects;
  _DrivePainter({required this.speed, required this.steer, required this.objects, required this.anim});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final horizon = size.height * 0.18;
    final roadEnd = size.height * 0.62;
    final vx = cx + steer * 2.5;

    _drawSky(canvas, size, horizon);
    _drawRoad(canvas, size, cx, horizon, roadEnd, vx);
    _drawBuildings(canvas, size, cx, horizon, roadEnd, vx);
    _drawLanes(canvas, size, cx, horizon, roadEnd, vx);
    if (speed > 1) _drawAutopilotPath(canvas, size, cx, horizon, roadEnd, vx);

    // Detected objects (far first)
    final sorted = List<DetectedObject>.from(objects)..sort((a, b) => a.y.compareTo(b.y));
    for (final o in sorted) _drawVehicle(canvas, size, o, cx, horizon, roadEnd, vx);

    // Ego car ground effects only (3D model overlays the actual car)
    _drawEgoGround(canvas, size, cx, roadEnd);
  }

  void _drawSky(Canvas c, Size s, double h) {
    // Horizon glow
    c.drawRect(Rect.fromLTWH(0, h - 20, s.width, 40),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, const Color(0xFF1A2540).withValues(alpha: 0.3), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, h - 20, s.width, 40)));
  }

  void _drawRoad(Canvas c, Size s, double cx, double h, double b, double vx) {
    final wt = 65.0, wb = s.width * 0.88;

    // Grass
    final grassPaint = Paint()..color = const Color(0xFF13201A);
    c.drawRect(Rect.fromLTWH(0, h, s.width, b - h), grassPaint);

    // Shoulder
    for (final side in [-1.0, 1.0]) {
      final shoulder = Path()
        ..moveTo(vx + side * wt / 2, h)..lineTo(vx + side * (wt / 2 + 12), h)
        ..lineTo(cx + side * (wb / 2 + 30), b)..lineTo(cx + side * wb / 2, b)..close();
      c.drawPath(shoulder, Paint()..color = const Color(0xFF1C2630));
    }

    // Road
    final road = Path()
      ..moveTo(vx - wt / 2, h)..lineTo(vx + wt / 2, h)
      ..lineTo(cx + wb / 2, b)..lineTo(cx - wb / 2, b)..close();
    c.drawPath(road, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [const Color(0xFF242C38), const Color(0xFF2C3544), const Color(0xFF333D4C)],
    ).createShader(Rect.fromLTWH(0, h, s.width, b - h)));

    // Edge lines
    final edge = Paint()..color = Colors.white.withValues(alpha: 0.35)..strokeWidth = 2;
    c.drawLine(Offset(vx - wt / 2, h), Offset(cx - wb / 2, b), edge);
    c.drawLine(Offset(vx + wt / 2, h), Offset(cx + wb / 2, b), edge);
  }

  void _drawBuildings(Canvas c, Size s, double cx, double h, double b, double vx) {
    final rng = Random(42);
    for (final side in [-1.0, 1.0]) {
      for (int i = 0; i < 7; i++) {
        final t = i / 7.0;
        final p = pow(t, 1.5).toDouble();
        final rw = lerpDouble(65, s.width * 0.88, p)!;
        final bx = lerpDouble(vx, cx, p)!;
        final y = lerpDouble(h, b, p)!;
        final edgeX = bx + side * (rw / 2 + 20 + rng.nextDouble() * 25);

        final bH = (12 + rng.nextDouble() * 30) * (1 - p * 0.4);
        final bW = 6 + rng.nextDouble() * 14;
        final alpha = (0.10 - p * 0.05).clamp(0.01, 0.10);

        c.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(edgeX - bW / 2, y - bH, bW, bH), const Radius.circular(1)),
          Paint()..color = Color.fromRGBO(25, 35, 50, alpha));

        // Tree
        if (rng.nextDouble() > 0.5) {
          final tx = edgeX + side * (bW / 2 + 4);
          c.drawCircle(Offset(tx, y - 6 - rng.nextDouble() * 8), 2.5 + p * 3,
            Paint()..color = Color.fromRGBO(20, 45, 25, alpha * 1.5));
        }
      }
    }
  }

  void _drawLanes(Canvas c, Size s, double cx, double h, double b, double vx) {
    for (final off in [-0.25, 0.0, 0.25]) {
      final flow = (anim * 2.5) % 1.0;
      for (int i = 0; i < 14; i++) {
        final t1 = ((i + flow) / 14).clamp(0.0, 1.0);
        final t2 = ((i + flow + 0.2) / 14).clamp(0.0, 1.0);
        if (t1 >= 1.0) continue;
        final p1 = pow(t1, 1.6).toDouble(), p2 = pow(t2, 1.6).toDouble();
        final w1 = lerpDouble(65, s.width * 0.88, p1)!, w2 = lerpDouble(65, s.width * 0.88, p2)!;
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

  void _drawAutopilotPath(Canvas c, Size s, double cx, double h, double b, double vx) {
    final path = Path();
    for (int i = 0; i <= 30; i++) {
      final t = i / 30.0;
      final p = pow(t, 1.6).toDouble();
      final bx = lerpDouble(vx, cx, p)!;
      final y = lerpDouble(h, b, p)!;
      if (i == 0) path.moveTo(bx, y); else path.lineTo(bx, y);
    }
    c.drawPath(path, Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke..strokeWidth = 22
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    c.drawPath(path, Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
  }

  // Ground effects under where 3D model sits
  void _drawEgoGround(Canvas c, Size s, double cx, double roadEnd) {
    final y = roadEnd + s.height * 0.15;
    // Shadow
    c.drawOval(Rect.fromCenter(center: Offset(cx, y + 10), width: 80, height: 14),
      Paint()..color = Colors.black.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // Headlight beams forward
    final beam = Path()
      ..moveTo(cx - 18, y - 40)
      ..lineTo(cx - 45, s.height * 0.18)
      ..lineTo(cx + 45, s.height * 0.18)
      ..lineTo(cx + 18, y - 40)
      ..close();
    c.drawPath(beam, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.012));
  }

  void _drawVehicle(Canvas c, Size s, DetectedObject o, double cx, double h, double b, double vx) {
    final p = pow(o.y, 1.6).toDouble();
    final rw = lerpDouble(65, s.width * 0.88, p)!;
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
      // Smaller version of ego car shape
      final w = 16 * sc, vh = 26 * sc;
      final body = Path()
        ..moveTo(x - w * 0.4, y)
        ..cubicTo(x - w * 0.45, y - vh * 0.3, x - w * 0.38, y - vh * 0.65, x, y - vh)
        ..cubicTo(x + w * 0.38, y - vh * 0.65, x + w * 0.45, y - vh * 0.3, x + w * 0.4, y)
        ..close();
      c.drawPath(body, Paint()..color = col.withValues(alpha: 0.12));
      c.drawPath(body, Paint()..color = col.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1);
      // Tail lights
      c.drawRect(Rect.fromCenter(center: Offset(x - w * 0.25, y - 1), width: 3 * sc, height: 1.5 * sc),
        Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.5));
      c.drawRect(Rect.fromCenter(center: Offset(x + w * 0.25, y - 1), width: 3 * sc, height: 1.5 * sc),
        Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.5));
    } else if (o.type == 'truck' || o.type == 'bus') {
      final w = 20 * sc, vh = 38 * sc;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - w / 2, y - vh, w, vh), Radius.circular(2 * sc)),
        Paint()..color = col.withValues(alpha: 0.1));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - w / 2, y - vh, w, vh), Radius.circular(2 * sc)),
        Paint()..color = col.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1);
    } else if (o.type == 'pedestrian') {
      final ph = 14 * sc;
      final paint = Paint()..color = col.withValues(alpha: 0.5)..strokeWidth = 1.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      c.drawCircle(Offset(x, y - ph), 2.5 * sc, paint);
      c.drawLine(Offset(x, y - ph + 3 * sc), Offset(x, y - ph * 0.35), paint);
      c.drawLine(Offset(x, y - ph * 0.35), Offset(x - 3 * sc, y), paint);
      c.drawLine(Offset(x, y - ph * 0.35), Offset(x + 3 * sc, y), paint);
    } else if (o.type == 'bike') {
      final paint = Paint()..color = col.withValues(alpha: 0.5)..strokeWidth = 1.2..style = PaintingStyle.stroke;
      c.drawCircle(Offset(x, y - 2 * sc), 3 * sc, paint);
      c.drawLine(Offset(x, y - 2 * sc), Offset(x, y - 14 * sc), paint);
      c.drawCircle(Offset(x, y - 18 * sc), 2.5 * sc, paint);
    }

    final dist = ((1 - o.y) * 80 + 5).toInt();
    final tp = TextPainter(
      text: TextSpan(text: '${dist}m', style: TextStyle(color: col.withValues(alpha: 0.3), fontSize: 6 + sc * 3, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x - tp.width / 2, y - 28 * sc - 8));
  }

  @override
  bool shouldRepaint(covariant _DrivePainter old) => true;
}

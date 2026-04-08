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
          CustomPaint(
            size: Size.infinite,
            painter: _SurroundPainter(
              speed: speed, steer: steeringAngle,
              objects: objects, anim: animationValue,
            ),
          ),
          // Speed
          Positioned(
            bottom: 44, left: 0, right: 0,
            child: Column(
              children: [
                Text(speed.toInt().toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 82, fontWeight: FontWeight.w100,
                    height: 1, letterSpacing: -5)),
                Text('km/h', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
              ],
            ),
          ),
          // Gear
          Positioned(bottom: 10, left: 14, child: _Gear(gear)),
          // Battery
          Positioned(bottom: 10, right: 14, child: _Battery(batteryLevel, range)),
          // Speed limit
          if (speed > 0)
            Positioned(top: 12, right: 12, child: _SpeedSign(60)),
          // Detection count
          if (objects.isNotEmpty)
            Positioned(top: 12, left: 12,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34D399))),
                const SizedBox(width: 5),
                Text('${objects.length}', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11)),
              ])),
        ],
      ),
    );
  }
}

class _Gear extends StatelessWidget {
  final String gear;
  const _Gear(this.gear);
  @override
  Widget build(BuildContext context) => Row(
    children: ['P','R','N','D'].map((g) => Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Text(g, style: TextStyle(
        color: gear == g ? Colors.white : Colors.white.withValues(alpha: 0.12),
        fontSize: 14, fontWeight: gear == g ? FontWeight.w700 : FontWeight.w400)),
    )).toList(),
  );
}

class _Battery extends StatelessWidget {
  final double level;
  final double range;
  const _Battery(this.level, this.range);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text('${range.toInt()} km', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11)),
    const SizedBox(width: 6),
    SizedBox(width: 32, height: 13, child: CustomPaint(painter: _BattPainter(level / 100))),
  ]);
}

class _SpeedSign extends StatelessWidget {
  final int limit;
  const _SpeedSign(this.limit);
  @override
  Widget build(BuildContext context) => Container(
    width: 30, height: 30,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
      border: Border.all(color: const Color(0xFFDC2626), width: 2.5)),
    child: Center(child: Text('$limit', style: const TextStyle(color: Color(0xFF1F2937), fontSize: 11, fontWeight: FontWeight.w800, height: 1))),
  );
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

// ============================================================
// Main painter — road, ego car, detected vehicles
// ============================================================
class _SurroundPainter extends CustomPainter {
  final double speed, steer, anim;
  final List<DetectedObject> objects;
  _SurroundPainter({required this.speed, required this.steer, required this.objects, required this.anim});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final h = size.height * 0.28;
    final b = size.height * 0.72;
    final vx = cx + steer * 2.5;

    _drawRoad(canvas, size, cx, h, b, vx);
    _drawLanes(canvas, size, cx, h, b, vx);

    // Detected objects (far first)
    final sorted = List<DetectedObject>.from(objects)..sort((a, b) => a.y.compareTo(b.y));
    for (final o in sorted) _drawVehicle(canvas, size, o, cx, h, b, vx);

    // Ego car shadow hint only (3D model overlays on top)
    _drawEgoShadow(canvas, size, cx);
  }

  void _drawRoad(Canvas c, Size s, double cx, double h, double b, double vx) {
    final wt = 80.0, wb = s.width * 0.92;
    final road = Path()
      ..moveTo(vx - wt / 2, h)..lineTo(vx + wt / 2, h)
      ..lineTo(cx + wb / 2, b)..lineTo(cx - wb / 2, b)..close();
    c.drawPath(road, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF232B38), Color(0xFF2C3545)],
    ).createShader(Rect.fromLTWH(0, h, s.width, b - h)));

    final edge = Paint()..color = Colors.white.withValues(alpha: 0.2)..strokeWidth = 1.5;
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
        final w1 = lerpDouble(80, s.width * 0.92, p1)!;
        final w2 = lerpDouble(80, s.width * 0.92, p2)!;
        final x1 = lerpDouble(vx, cx, p1)! + off * w1 / 2;
        final y1 = lerpDouble(h, b, p1)!;
        final x2 = lerpDouble(vx, cx, p2)! + off * w2 / 2;
        final y2 = lerpDouble(h, b, p2)!;
        c.drawLine(Offset(x1, y1), Offset(x2, y2), Paint()
          ..color = Colors.white.withValues(alpha: (p1 * 0.35).clamp(0.02, 0.25))
          ..strokeWidth = 1 + p1 * 2..strokeCap = StrokeCap.round);
      }
    }
  }

  // === Tesla-style ego car (top-down, detailed) ===
  void _drawEgoShadow(Canvas c, Size s, double cx) {
    // Just a subtle shadow/glow — actual car is 3D model overlay
    final bot = s.height * 0.88;
    c.drawOval(Rect.fromCenter(center: Offset(cx, bot), width: 80, height: 14),
      Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.08)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    c.drawOval(Rect.fromCenter(center: Offset(cx, bot), width: 50, height: 8),
      Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.04));

    // Headlight beams
    final beam = Path()
      ..moveTo(cx - 20, bot - 30)
      ..lineTo(cx - 50, bot - 120)
      ..lineTo(cx + 50, bot - 120)
      ..lineTo(cx + 20, bot - 30)
      ..close();
    c.drawPath(beam, Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.025));
    return;
  }

  // Keep for reference but unused now
  void _drawEgoOld(Canvas c, Size s, double cx) {
    final bot = s.height * 0.94;
    final w = 48.0, h = 90.0;
    final x = cx, y = bot - h / 2;

    // Shadow
    c.drawOval(Rect.fromCenter(center: Offset(x, bot + 2), width: w + 10, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Body outline - smooth sedan shape
    final body = Path();
    // Start from rear left
    body.moveTo(x - w * 0.42, bot);
    // Left side rear
    body.cubicTo(x - w * 0.46, bot - h * 0.15, x - w * 0.48, bot - h * 0.3, x - w * 0.44, bot - h * 0.45);
    // Left side front taper
    body.cubicTo(x - w * 0.40, bot - h * 0.6, x - w * 0.32, bot - h * 0.78, x - w * 0.18, bot - h * 0.9);
    // Front nose
    body.cubicTo(x - w * 0.08, bot - h * 0.97, x + w * 0.08, bot - h * 0.97, x + w * 0.18, bot - h * 0.9);
    // Right side front
    body.cubicTo(x + w * 0.32, bot - h * 0.78, x + w * 0.40, bot - h * 0.6, x + w * 0.44, bot - h * 0.45);
    // Right side rear
    body.cubicTo(x + w * 0.48, bot - h * 0.3, x + w * 0.46, bot - h * 0.15, x + w * 0.42, bot);
    body.close();

    // Fill
    c.drawPath(body, Paint()..color = const Color(0xFF1E2A3A));

    // Subtle gradient overlay
    c.drawPath(body, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFF2A3A50).withValues(alpha: 0.5), Colors.transparent],
      ).createShader(Rect.fromLTWH(x - w / 2, bot - h, w, h)));

    // Outline glow
    c.drawPath(body, Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Clean outline
    c.drawPath(body, Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // Windshield
    final ws = Path()
      ..moveTo(x - w * 0.28, bot - h * 0.52)
      ..quadraticBezierTo(x, bot - h * 0.60, x + w * 0.28, bot - h * 0.52)
      ..lineTo(x + w * 0.24, bot - h * 0.42)
      ..quadraticBezierTo(x, bot - h * 0.44, x - w * 0.24, bot - h * 0.42)
      ..close();
    c.drawPath(ws, Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.08));
    c.drawPath(ws, Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 0.5);

    // Rear window
    final rw = Path()
      ..moveTo(x - w * 0.26, bot - h * 0.15)
      ..quadraticBezierTo(x, bot - h * 0.2, x + w * 0.26, bot - h * 0.15)
      ..lineTo(x + w * 0.24, bot - h * 0.08)
      ..quadraticBezierTo(x, bot - h * 0.1, x - w * 0.24, bot - h * 0.08)
      ..close();
    c.drawPath(rw, Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.06));

    // Wheels (4 rounded rects)
    final wheelP = Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.25);
    final wheelR = const Radius.circular(2.5);
    for (final pos in [
      Offset(x - w * 0.5, bot - h * 0.15), Offset(x + w * 0.5, bot - h * 0.15),
      Offset(x - w * 0.47, bot - h * 0.6), Offset(x + w * 0.47, bot - h * 0.6),
    ]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pos, width: 6, height: 14), wheelR), wheelP);
    }

    // Headlight beams
    final beam = Path()
      ..moveTo(x - w * 0.15, bot - h)
      ..lineTo(x - w * 0.5, bot - h - 80)
      ..lineTo(x + w * 0.5, bot - h - 80)
      ..lineTo(x + w * 0.15, bot - h)
      ..close();
    c.drawPath(beam, Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.03));
  }

  // === Detected vehicles - Tesla style clean silhouettes ===
  void _drawVehicle(Canvas c, Size s, DetectedObject o, double cx, double h, double b, double vx) {
    final p = pow(o.y, 1.6).toDouble();
    final rw = lerpDouble(80, s.width * 0.92, p)!;
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
      _drawCarSilhouette(c, x, y, sc, col);
    } else if (o.type == 'truck' || o.type == 'bus') {
      _drawTruckSilhouette(c, x, y, sc, col);
    } else if (o.type == 'pedestrian') {
      _drawPedSilhouette(c, x, y, sc, col);
    } else if (o.type == 'bike') {
      _drawBikeSilhouette(c, x, y, sc, col);
    }

    // Distance label
    final dist = ((1 - o.y) * 80 + 5).toInt();
    final tp = TextPainter(
      text: TextSpan(text: '${dist}m', style: TextStyle(color: col.withValues(alpha: 0.4), fontSize: 6 + sc * 4, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x - tp.width / 2, y - 35 * sc - 10));
  }

  void _drawCarSilhouette(Canvas c, double x, double y, double s, Color col) {
    final w = 20 * s, h = 32 * s;

    final body = Path()
      ..moveTo(x - w * 0.42, y)
      ..cubicTo(x - w * 0.46, y - h * 0.2, x - w * 0.45, y - h * 0.5, x - w * 0.35, y - h * 0.7)
      ..cubicTo(x - w * 0.2, y - h * 0.9, x + w * 0.2, y - h * 0.9, x + w * 0.35, y - h * 0.7)
      ..cubicTo(x + w * 0.45, y - h * 0.5, x + w * 0.46, y - h * 0.2, x + w * 0.42, y)
      ..close();

    c.drawPath(body, Paint()..color = col.withValues(alpha: 0.15));
    c.drawPath(body, Paint()..color = col.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1);

    // Tail lights
    c.drawCircle(Offset(x - w * 0.3, y - 1), 1.5 * s, Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.7));
    c.drawCircle(Offset(x + w * 0.3, y - 1), 1.5 * s, Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.7));
  }

  void _drawTruckSilhouette(Canvas c, double x, double y, double s, Color col) {
    final w = 24 * s, h = 44 * s;
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x - w / 2, y - h, w, h), Radius.circular(3 * s));
    c.drawRRect(rr, Paint()..color = col.withValues(alpha: 0.12));
    c.drawRRect(rr, Paint()..color = col.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _drawPedSilhouette(Canvas c, double x, double y, double s, Color col) {
    final h = 18 * s;
    final paint = Paint()..color = col.withValues(alpha: 0.6)..strokeWidth = 1.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    c.drawCircle(Offset(x, y - h), 2.5 * s, paint);
    c.drawLine(Offset(x, y - h + 3 * s), Offset(x, y - h * 0.35), paint);
    c.drawLine(Offset(x, y - h * 0.35), Offset(x - 3.5 * s, y), paint);
    c.drawLine(Offset(x, y - h * 0.35), Offset(x + 3.5 * s, y), paint);
    c.drawLine(Offset(x, y - h * 0.65), Offset(x - 3 * s, y - h * 0.4), paint);
    c.drawLine(Offset(x, y - h * 0.65), Offset(x + 3 * s, y - h * 0.4), paint);
  }

  void _drawBikeSilhouette(Canvas c, double x, double y, double s, Color col) {
    final paint = Paint()..color = col.withValues(alpha: 0.6)..strokeWidth = 1.2..style = PaintingStyle.stroke;
    c.drawCircle(Offset(x, y - 2 * s), 3 * s, paint);
    c.drawCircle(Offset(x, y - 18 * s), 3 * s, paint);
    c.drawLine(Offset(x, y - 2 * s), Offset(x, y - 18 * s), paint);
    c.drawCircle(Offset(x, y - 22 * s), 2.5 * s, paint);
  }

  @override
  bool shouldRepaint(covariant _SurroundPainter old) => true;
}

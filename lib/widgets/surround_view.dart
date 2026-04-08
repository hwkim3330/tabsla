import 'dart:math';
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
    required this.speed,
    required this.gear,
    required this.steeringAngle,
    required this.objects,
    required this.animationValue,
    required this.batteryLevel,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F1923), Color(0xFF162029), Color(0xFF1B2838)],
        ),
      ),
      child: Stack(
        children: [
          // Road + objects
          CustomPaint(
            size: Size.infinite,
            painter: _RoadPainter(
              speed: speed,
              steeringAngle: steeringAngle,
              objects: objects,
              anim: animationValue,
            ),
          ),

          // Speed — large, centered
          Positioned(
            bottom: 48,
            left: 0, right: 0,
            child: Column(
              children: [
                Text(
                  speed.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 88,
                    fontWeight: FontWeight.w100,
                    height: 1,
                    letterSpacing: -6,
                    fontFamily: 'sans-serif',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'km/h',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),

          // Gear — bottom left, minimal
          Positioned(
            bottom: 12, left: 16,
            child: Row(
              children: ['P', 'R', 'N', 'D'].map((g) {
                final active = gear == g;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    g,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white.withValues(alpha: 0.15),
                      fontSize: 15,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Battery — bottom right
          Positioned(
            bottom: 12, right: 16,
            child: Row(
              children: [
                Text(
                  '${range.toInt()} km',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36, height: 14,
                  child: CustomPaint(
                    painter: _BatteryIconPainter(level: batteryLevel / 100),
                  ),
                ),
              ],
            ),
          ),

          // Speed limit — top right
          if (speed > 0)
            Positioned(
              top: 14, right: 14,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDC2626), width: 2.5),
                  color: Colors.white,
                ),
                child: const Center(
                  child: Text('60', style: TextStyle(color: Color(0xFF1F2937), fontSize: 12, fontWeight: FontWeight.w800, height: 1)),
                ),
              ),
            ),

          // Detected count — top left
          if (objects.isNotEmpty)
            Positioned(
              top: 14, left: 14,
              child: Row(
                children: [
                  Container(
                    width: 5, height: 5,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34D399)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${objects.length} detected',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BatteryIconPainter extends CustomPainter {
  final double level;
  _BatteryIconPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width - 3, size.height), const Radius.circular(2));
    canvas.drawRRect(r, Paint()..color = Colors.white.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 1);
    canvas.drawRect(Rect.fromLTWH(size.width - 3, size.height * 0.3, 3, size.height * 0.4),
      Paint()..color = Colors.white.withValues(alpha: 0.15));

    final color = level > 0.3 ? const Color(0xFF34D399) : const Color(0xFFEF4444);
    final fillW = (size.width - 5) * level;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(1.5, 1.5, fillW, size.height - 3), const Radius.circular(1)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryIconPainter old) => old.level != level;
}

class _RoadPainter extends CustomPainter {
  final double speed, steeringAngle, anim;
  final List<DetectedObject> objects;

  _RoadPainter({required this.speed, required this.steeringAngle, required this.objects, required this.anim});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final horizon = size.height * 0.28;
    final bottom = size.height * 0.75;
    final vx = cx + steeringAngle * 2.5;

    _drawRoad(canvas, size, cx, horizon, bottom, vx);
    _drawLanes(canvas, size, cx, horizon, bottom, vx);

    final sorted = List<DetectedObject>.from(objects)..sort((a, b) => a.y.compareTo(b.y));
    for (final o in sorted) _drawObj(canvas, size, o, cx, horizon, bottom, vx);

    _drawEgoCar(canvas, size, cx);
  }

  void _drawRoad(Canvas canvas, Size size, double cx, double h, double b, double vx) {
    final roadTop = 70.0;
    final roadBot = size.width * 0.9;

    final road = Path()
      ..moveTo(vx - roadTop / 2, h)
      ..lineTo(vx + roadTop / 2, h)
      ..lineTo(cx + roadBot / 2, b)
      ..lineTo(cx - roadBot / 2, b)
      ..close();

    canvas.drawPath(road, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFF252D38), const Color(0xFF2F3846)],
      ).createShader(Rect.fromLTWH(0, h, size.width, b - h)));

    // Soft edge lines
    final edge = Paint()..color = Colors.white.withValues(alpha: 0.25)..strokeWidth = 1.5;
    canvas.drawLine(Offset(vx - roadTop / 2, h), Offset(cx - roadBot / 2, b), edge);
    canvas.drawLine(Offset(vx + roadTop / 2, h), Offset(cx + roadBot / 2, b), edge);
  }

  void _drawLanes(Canvas canvas, Size size, double cx, double h, double b, double vx) {
    for (final offset in [-0.25, 0.0, 0.25]) {
      final n = 14;
      final flow = (anim * 2.5) % 1.0;
      for (int i = 0; i < n; i++) {
        final t1 = ((i + flow) / n).clamp(0.0, 1.0);
        final t2 = ((i + flow + 0.2) / n).clamp(0.0, 1.0);
        if (t1 >= 1.0) continue;

        final p1 = pow(t1, 1.6).toDouble();
        final p2 = pow(t2, 1.6).toDouble();
        final w1 = _lerp(70, size.width * 0.9, p1);
        final w2 = _lerp(70, size.width * 0.9, p2);

        final x1 = _lerp(vx, cx, p1) + offset * w1 / 2;
        final y1 = _lerp(h, b, p1);
        final x2 = _lerp(vx, cx, p2) + offset * w2 / 2;
        final y2 = _lerp(h, b, p2);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), Paint()
          ..color = Colors.white.withValues(alpha: (p1 * 0.4).clamp(0.03, 0.3))
          ..strokeWidth = 1 + p1 * 2
          ..strokeCap = StrokeCap.round);
      }
    }
  }

  void _drawEgoCar(Canvas canvas, Size size, double cx) {
    final bot = size.height * 0.96;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bot - 2), width: 64, height: 10),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    // Body
    final body = Path()
      ..moveTo(cx - 22, bot)
      ..cubicTo(cx - 24, bot - 12, cx - 25, bot - 28, cx - 20, bot - 50)
      ..cubicTo(cx - 14, bot - 62, cx - 6, bot - 68, cx, bot - 72)
      ..cubicTo(cx + 6, bot - 68, cx + 14, bot - 62, cx + 20, bot - 50)
      ..cubicTo(cx + 25, bot - 28, cx + 24, bot - 12, cx + 22, bot)
      ..close();

    canvas.drawPath(body, Paint()..color = const Color(0xFF1E293B));
    canvas.drawPath(body, Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);

    // Windshield
    final ws = Path()
      ..moveTo(cx - 15, bot - 44)
      ..quadraticBezierTo(cx, bot - 52, cx + 15, bot - 44)
      ..lineTo(cx + 13, bot - 36)
      ..quadraticBezierTo(cx, bot - 38, cx - 13, bot - 36)
      ..close();
    canvas.drawPath(ws, Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.15));

    // Wheels
    final wp = Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.3);
    for (final o in [Offset(cx - 26, bot - 12), Offset(cx + 26, bot - 12), Offset(cx - 24, bot - 48), Offset(cx + 24, bot - 48)]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 6, height: 12), const Radius.circular(2)), wp);
    }
  }

  void _drawObj(Canvas canvas, Size size, DetectedObject o, double cx, double h, double b, double vx) {
    final p = pow(o.y, 1.6).toDouble();
    final w = _lerp(70, size.width * 0.9, p);
    final bx = _lerp(vx, cx, p);
    final x = bx + o.x * w;
    final y = _lerp(h, b, p);
    final s = 0.2 + p * 0.8;

    Color c;
    switch (o.type) {
      case 'car': c = const Color(0xFF60A5FA); break;
      case 'truck': case 'bus': c = const Color(0xFFFBBF24); break;
      case 'pedestrian': c = const Color(0xFFF87171); break;
      case 'bike': c = const Color(0xFF34D399); break;
      default: c = const Color(0xFF9CA3AF);
    }

    if (o.type == 'car') {
      final cw = 18 * s; final ch = 30 * s;
      final path = Path()
        ..moveTo(x - cw / 2, y)
        ..cubicTo(x - cw / 2, y - ch * 0.4, x - cw / 2, y - ch * 0.7, x, y - ch)
        ..cubicTo(x + cw / 2, y - ch * 0.7, x + cw / 2, y - ch * 0.4, x + cw / 2, y)
        ..close();
      canvas.drawPath(path, Paint()..color = c.withValues(alpha: 0.2));
      canvas.drawPath(path, Paint()..color = c.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1);
    } else if (o.type == 'truck' || o.type == 'bus') {
      final tw = 22 * s; final th = 42 * s;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - tw / 2, y - th, tw, th), Radius.circular(2 * s)),
        Paint()..color = c.withValues(alpha: 0.15));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - tw / 2, y - th, tw, th), Radius.circular(2 * s)),
        Paint()..color = c.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1);
    } else if (o.type == 'pedestrian') {
      final ph = 16 * s;
      final sp = Paint()..color = c.withValues(alpha: 0.7)..strokeWidth = 1.2..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(x, y - ph), 2.5 * s, sp);
      canvas.drawLine(Offset(x, y - ph + 3 * s), Offset(x, y - ph * 0.3), sp);
      canvas.drawLine(Offset(x, y - ph * 0.3), Offset(x - 3 * s, y), sp);
      canvas.drawLine(Offset(x, y - ph * 0.3), Offset(x + 3 * s, y), sp);
    } else if (o.type == 'bike') {
      final bh = 18 * s;
      final sp = Paint()..color = c.withValues(alpha: 0.7)..strokeWidth = 1.2..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(x, y - 2 * s), 3 * s, sp);
      canvas.drawLine(Offset(x, y - 2 * s), Offset(x, y - bh + 4 * s), sp);
      canvas.drawCircle(Offset(x, y - bh), 2.5 * s, sp);
    }

    // Distance
    final dist = ((1 - o.y) * 80 + 5).toInt();
    final tp = TextPainter(
      text: TextSpan(text: '${dist}m', style: TextStyle(color: c.withValues(alpha: 0.5), fontSize: 7 + s * 3, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - (o.type == 'car' ? 30 * s : 20 * s) - 10));
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _RoadPainter old) => true;
}

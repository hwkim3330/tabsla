import 'dart:math';
import 'package:flutter/material.dart';

class Vehicle3DViewer extends StatefulWidget {
  final bool leftDoorOpen;
  final bool rightDoorOpen;
  final bool trunkOpen;
  final bool frunkOpen;

  const Vehicle3DViewer({
    super.key,
    required this.leftDoorOpen,
    required this.rightDoorOpen,
    required this.trunkOpen,
    required this.frunkOpen,
  });

  @override
  State<Vehicle3DViewer> createState() => _Vehicle3DViewerState();
}

class _Vehicle3DViewerState extends State<Vehicle3DViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _rotationY = 0;
  double _rotationX = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotationY += details.delta.dx * 0.01;
          _rotationX += details.delta.dy * 0.01;
          _rotationX = _rotationX.clamp(-0.3, 0.3);
        });
      },
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: _VehiclePainter(
              rotationY: _rotationY + _rotationController.value * 0.3,
              rotationX: _rotationX,
              leftDoorOpen: widget.leftDoorOpen,
              rightDoorOpen: widget.rightDoorOpen,
              trunkOpen: widget.trunkOpen,
              frunkOpen: widget.frunkOpen,
            ),
          );
        },
      ),
    );
  }
}

class _VehiclePainter extends CustomPainter {
  final double rotationY;
  final double rotationX;
  final bool leftDoorOpen;
  final bool rightDoorOpen;
  final bool trunkOpen;
  final bool frunkOpen;

  _VehiclePainter({
    required this.rotationY,
    required this.rotationX,
    required this.leftDoorOpen,
    required this.rightDoorOpen,
    required this.trunkOpen,
    required this.frunkOpen,
  });

  Offset project(double x, double y, double z, Size size) {
    // Simple 3D projection
    final cosY = cos(rotationY);
    final sinY = sin(rotationY);
    final cosX = cos(rotationX);
    final sinX = sin(rotationX);

    // Rotate Y
    final rx = x * cosY - z * sinY;
    final rz = x * sinY + z * cosY;
    // Rotate X
    final ry = y * cosX - rz * sinX;
    final rz2 = y * sinX + rz * cosX;

    final scale = 300 / (300 + rz2);
    return Offset(
      size.width / 2 + rx * scale,
      size.height / 2 + ry * scale,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;

    final edgePaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final glowPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final doorPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final s = 1.0; // scale factor

    // Car body vertices (simplified sedan shape)
    // Bottom rectangle
    final bl1 = project(-80 * s, 30 * s, -40 * s, size);
    final bl2 = project(80 * s, 30 * s, -40 * s, size);
    final bl3 = project(80 * s, 30 * s, 40 * s, size);
    final bl4 = project(-80 * s, 30 * s, 40 * s, size);

    // Top of body
    final bm1 = project(-75 * s, 5 * s, -38 * s, size);
    final bm2 = project(75 * s, 5 * s, -38 * s, size);
    final bm3 = project(75 * s, 5 * s, 38 * s, size);
    final bm4 = project(-75 * s, 5 * s, 38 * s, size);

    // Roof
    final rt1 = project(-30 * s, -20 * s, -34 * s, size);
    final rt2 = project(30 * s, -20 * s, -34 * s, size);
    final rt3 = project(30 * s, -20 * s, 34 * s, size);
    final rt4 = project(-30 * s, -20 * s, 34 * s, size);

    // Front
    final f1 = project(-85 * s, 20 * s, -35 * s, size);
    final f2 = project(-85 * s, 20 * s, 35 * s, size);
    final f3 = project(-85 * s, 5 * s, -35 * s, size);
    final f4 = project(-85 * s, 5 * s, 35 * s, size);

    // Draw body panels
    void drawPanel(List<Offset> points) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();
      canvas.drawPath(path, bodyPaint);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, edgePaint);
    }

    // Bottom
    drawPanel([bl1, bl2, bl3, bl4]);

    // Side panels
    drawPanel([bl1, bl2, bm2, bm1]);
    drawPanel([bl3, bl4, bm4, bm3]);

    // Hood / top body
    drawPanel([bm1, bm2, bm3, bm4]);

    // Windshield areas
    drawPanel([bm1, rt1, rt2, bm2]);
    drawPanel([bm3, rt3, rt4, bm4]);

    // Roof
    drawPanel([rt1, rt2, rt3, rt4]);

    // Front face
    drawPanel([f1, f2, f4, f3]);

    // Windshield front
    drawPanel([bm1, bm4, rt4, rt1]);

    // Rear windshield
    drawPanel([bm2, bm3, rt3, rt2]);

    // Headlights
    final headlightPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..style = PaintingStyle.fill;

    final hl1 = project(-86 * s, 12 * s, -28 * s, size);
    final hl2 = project(-86 * s, 12 * s, 28 * s, size);
    canvas.drawCircle(hl1, 4, headlightPaint);
    canvas.drawCircle(hl2, 4, headlightPaint);

    // Tail lights
    final tailPaint = Paint()
      ..color = const Color(0xFFFF4444)
      ..style = PaintingStyle.fill;

    final tl1 = project(82 * s, 12 * s, -36 * s, size);
    final tl2 = project(82 * s, 12 * s, 36 * s, size);
    canvas.drawCircle(tl1, 3, tailPaint);
    canvas.drawCircle(tl2, 3, tailPaint);

    // Wheels
    final wheelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final w1 = project(-55 * s, 32 * s, -42 * s, size);
    final w2 = project(55 * s, 32 * s, -42 * s, size);
    final w3 = project(-55 * s, 32 * s, 42 * s, size);
    final w4 = project(55 * s, 32 * s, 42 * s, size);
    for (final w in [w1, w2, w3, w4]) {
      canvas.drawCircle(w, 12, wheelPaint);
    }

    // Door indicators
    if (leftDoorOpen) {
      final d1 = project(-20 * s, 5 * s, -42 * s, size);
      final d2 = project(-20 * s, -10 * s, -55 * s, size);
      canvas.drawLine(d1, d2, doorPaint);
      final d3 = project(10 * s, 5 * s, -42 * s, size);
      final d4 = project(10 * s, -10 * s, -55 * s, size);
      canvas.drawLine(d3, d4, doorPaint);
    }
    if (rightDoorOpen) {
      final d1 = project(-20 * s, 5 * s, 42 * s, size);
      final d2 = project(-20 * s, -10 * s, 55 * s, size);
      canvas.drawLine(d1, d2, doorPaint);
      final d3 = project(10 * s, 5 * s, 42 * s, size);
      final d4 = project(10 * s, -10 * s, 55 * s, size);
      canvas.drawLine(d3, d4, doorPaint);
    }
    if (trunkOpen) {
      final t1 = project(70 * s, 5 * s, -30 * s, size);
      final t2 = project(85 * s, -15 * s, -30 * s, size);
      final t3 = project(85 * s, -15 * s, 30 * s, size);
      final t4 = project(70 * s, 5 * s, 30 * s, size);
      drawPanel([t1, t2, t3, t4]);
    }
    if (frunkOpen) {
      final fr1 = project(-75 * s, 5 * s, -30 * s, size);
      final fr2 = project(-90 * s, -15 * s, -30 * s, size);
      final fr3 = project(-90 * s, -15 * s, 30 * s, size);
      final fr4 = project(-75 * s, 5 * s, 30 * s, size);
      drawPanel([fr1, fr2, fr3, fr4]);
    }

    // Ground shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final sh = Path();
    final s1 = project(-90 * s, 40 * s, -45 * s, size);
    final s2 = project(90 * s, 40 * s, -45 * s, size);
    final s3 = project(90 * s, 40 * s, 45 * s, size);
    final s4 = project(-90 * s, 40 * s, 45 * s, size);
    sh.moveTo(s1.dx, s1.dy);
    sh.lineTo(s2.dx, s2.dy);
    sh.lineTo(s3.dx, s3.dy);
    sh.lineTo(s4.dx, s4.dy);
    sh.close();
    canvas.drawPath(sh, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _VehiclePainter oldDelegate) => true;
}

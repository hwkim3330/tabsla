import 'dart:math';
import 'package:flutter/material.dart';

class Speedometer extends StatelessWidget {
  final double speed;
  final double maxSpeed;
  final String gear;

  const Speedometer({
    super.key,
    required this.speed,
    this.maxSpeed = 200,
    required this.gear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: _SpeedometerPainter(
          speed: speed,
          maxSpeed: maxSpeed,
          gear: gear,
        ),
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final String gear;

  _SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    required this.gear,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const startAngle = 0.75 * pi;
    const sweepAngle = 1.5 * pi;
    final fraction = (speed / maxSpeed).clamp(0.0, 1.0);

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Progress arc with gradient
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: const [
          Color(0xFF00D4FF),
          Color(0xFF0088FF),
          Color(0xFFFF4444),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * fraction,
      false,
      progressPaint,
    );

    // Speed ticks
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (int i = 0; i <= 20; i++) {
      final angle = startAngle + (sweepAngle * i / 20);
      final outerPoint = Offset(
        center.dx + (radius + 12) * cos(angle),
        center.dy + (radius + 12) * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius + (i % 5 == 0 ? 4 : 8)) * cos(angle),
        center.dy + (radius + (i % 5 == 0 ? 4 : 8)) * sin(angle),
      );
      canvas.drawLine(outerPoint, innerPoint, tickPaint);
    }

    // Speed text
    final speedText = TextPainter(
      text: TextSpan(
        text: speed.toInt().toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 72,
          fontWeight: FontWeight.w200,
          letterSpacing: -2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    speedText.paint(
      canvas,
      Offset(center.dx - speedText.width / 2, center.dy - speedText.height / 2 - 10),
    );

    // Unit text
    final unitText = TextPainter(
      text: const TextSpan(
        text: 'km/h',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    unitText.paint(
      canvas,
      Offset(center.dx - unitText.width / 2, center.dy + 30),
    );

    // Gear indicator
    final gearText = TextPainter(
      text: TextSpan(
        text: gear,
        style: TextStyle(
          color: gear == 'D' ? const Color(0xFF00D4FF) : Colors.white54,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    gearText.paint(
      canvas,
      Offset(center.dx - gearText.width / 2, center.dy + 55),
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) =>
      oldDelegate.speed != speed || oldDelegate.gear != gear;
}

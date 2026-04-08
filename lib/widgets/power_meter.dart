import 'dart:math';
import 'package:flutter/material.dart';

class PowerMeter extends StatelessWidget {
  final double power; // kW

  const PowerMeter({super.key, required this.power});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Power',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '${power.toInt()} kW',
            style: TextStyle(
              color: power < 0 ? const Color(0xFF00FF88) : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: CustomPaint(
              size: const Size(double.infinity, 40),
              painter: _PowerBarPainter(power: power),
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerBarPainter extends CustomPainter {
  final double power;

  _PowerBarPainter({required this.power});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final barHeight = 6.0;
    final y = size.height / 2;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, y - barHeight / 2, size.width, barHeight),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );

    // Center line
    canvas.drawLine(
      Offset(centerX, y - 12),
      Offset(centerX, y + 12),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // Power bar
    final maxPower = 200.0;
    final fraction = (power.abs() / maxPower).clamp(0.0, 1.0);
    final barWidth = (size.width / 2) * fraction;

    final Color barColor;
    final double startX;
    if (power >= 0) {
      barColor = const Color(0xFF00D4FF);
      startX = centerX;
    } else {
      barColor = const Color(0xFF00FF88);
      startX = centerX - barWidth;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, y - barHeight / 2, barWidth, barHeight),
        const Radius.circular(3),
      ),
      Paint()..color = barColor,
    );

    // Labels
    final regenText = TextPainter(
      text: TextSpan(
        text: 'REGEN',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    regenText.paint(canvas, Offset(4, y + 10));

    final accelText = TextPainter(
      text: TextSpan(
        text: 'ACCEL',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    accelText.paint(canvas, Offset(size.width - accelText.width - 4, y + 10));
  }

  @override
  bool shouldRepaint(covariant _PowerBarPainter oldDelegate) =>
      oldDelegate.power != power;
}

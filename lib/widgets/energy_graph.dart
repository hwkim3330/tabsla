import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';

class EnergyGraph extends StatefulWidget {
  final double power;
  final double batteryLevel;
  final double speed;
  final VoidCallback onClose;

  const EnergyGraph({super.key, required this.power, required this.batteryLevel, required this.speed, required this.onClose});

  @override
  State<EnergyGraph> createState() => _EnergyGraphState();
}

class _EnergyGraphState extends State<EnergyGraph> {
  final _powerHistory = Queue<double>();
  final _batteryHistory = Queue<double>();
  static const _maxPoints = 120;

  @override
  void didUpdateWidget(EnergyGraph old) {
    super.didUpdateWidget(old);
    _powerHistory.addLast(widget.power);
    _batteryHistory.addLast(widget.batteryLevel);
    if (_powerHistory.length > _maxPoints) _powerHistory.removeFirst();
    if (_batteryHistory.length > _maxPoints) _batteryHistory.removeFirst();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111318),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Energy', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(onTap: widget.onClose, child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20)),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _Stat('Power', '${widget.power.toInt()} kW', const Color(0xFF3B82F6)),
              _Stat('Battery', '${widget.batteryLevel.toInt()}%', const Color(0xFF22C55E)),
              _Stat('Efficiency', widget.speed > 5 ? '${(widget.power / widget.speed * 100).toStringAsFixed(0)} Wh/km' : '—', const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 16),
          // Power graph
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _GraphPainter(
                data: _powerHistory.toList(),
                color: const Color(0xFF3B82F6),
                minVal: -30, maxVal: 80,
                label: 'Power (kW)',
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Battery graph
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _GraphPainter(
                data: _batteryHistory.toList(),
                color: const Color(0xFF22C55E),
                minVal: 0, maxVal: 100,
                label: 'Battery (%)',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
        ],
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minVal, maxVal;
  final String label;

  _GraphPainter({required this.data, required this.color, required this.minVal, required this.maxVal, required this.label});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)),
      Paint()..color = Colors.white.withValues(alpha: 0.03),
    );

    if (data.isEmpty) return;

    // Grid lines
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.04)..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Label
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(6, 4));

    // Line
    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i / max(data.length - 1, 1) * size.width;
      final norm = ((data[i] - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
      final y = size.height - norm * size.height;
      if (i == 0) { path.moveTo(x, y); fillPath.moveTo(x, size.height); fillPath.lineTo(x, y); }
      else { path.lineTo(x, y); fillPath.lineTo(x, y); }
    }

    // Fill
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Stroke
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) => true;
}

import 'package:flutter/material.dart';

class BatteryGauge extends StatelessWidget {
  final double level;
  final double temperature;
  final double range;

  const BatteryGauge({
    super.key,
    required this.level,
    required this.temperature,
    required this.range,
  });

  Color get _batteryColor {
    if (level > 60) return const Color(0xFF00D4FF);
    if (level > 30) return const Color(0xFFFFAA00);
    return const Color(0xFFFF4444);
  }

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
          Row(
            children: [
              Icon(Icons.battery_charging_full, color: _batteryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '${level.toInt()}%',
                style: TextStyle(
                  color: _batteryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Battery bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              width: double.infinity,
              child: LinearProgressIndicator(
                value: level / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(_batteryColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Range', value: '${range.toInt()} km'),
          const SizedBox(height: 4),
          _InfoRow(label: 'Battery temp', value: '${temperature.toStringAsFixed(1)}°C'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class ClimateWidget extends StatelessWidget {
  final double insideTemp;
  final double outsideTemp;

  const ClimateWidget({
    super.key,
    required this.insideTemp,
    required this.outsideTemp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.thermostat, color: Color(0xFF00D4FF), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${insideTemp.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Outside ${outsideTemp.toStringAsFixed(1)}°C',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.ac_unit, color: Color(0xFF00D4FF), size: 14),
                SizedBox(width: 4),
                Text(
                  'AUTO',
                  style: TextStyle(color: Color(0xFF00D4FF), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

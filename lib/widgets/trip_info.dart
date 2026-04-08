import 'package:flutter/material.dart';

class TripInfo extends StatelessWidget {
  final double distance;
  final double energy;
  final DateTime tripStart;

  const TripInfo({
    super.key,
    required this.distance,
    required this.energy,
    required this.tripStart,
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(tripStart);
    final minutes = elapsed.inMinutes;
    final efficiency = distance > 0 ? (energy / distance * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TripItem(
            label: 'DIST',
            value: '${distance.toStringAsFixed(1)} km',
          ),
          _Divider(),
          _TripItem(
            label: 'TIME',
            value: '${minutes}m',
          ),
          _Divider(),
          _TripItem(
            label: 'EFFICIENCY',
            value: '${efficiency.toStringAsFixed(0)} Wh/km',
          ),
        ],
      ),
    );
  }
}

class _TripItem extends StatelessWidget {
  final String label;
  final String value;

  const _TripItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}

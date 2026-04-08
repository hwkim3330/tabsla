import 'package:flutter/material.dart';

class VehicleControls extends StatelessWidget {
  final bool leftDoorOpen;
  final bool rightDoorOpen;
  final bool trunkOpen;
  final bool frunkOpen;
  final VoidCallback onToggleLeftDoor;
  final VoidCallback onToggleRightDoor;
  final VoidCallback onToggleTrunk;
  final VoidCallback onToggleFrunk;

  const VehicleControls({
    super.key,
    required this.leftDoorOpen,
    required this.rightDoorOpen,
    required this.trunkOpen,
    required this.frunkOpen,
    required this.onToggleLeftDoor,
    required this.onToggleRightDoor,
    required this.onToggleTrunk,
    required this.onToggleFrunk,
  });

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
            'Controls',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ControlButton(
                icon: Icons.sensor_door,
                label: 'L Door',
                isActive: leftDoorOpen,
                onTap: onToggleLeftDoor,
              ),
              const SizedBox(width: 8),
              _ControlButton(
                icon: Icons.sensor_door,
                label: 'R Door',
                isActive: rightDoorOpen,
                onTap: onToggleRightDoor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ControlButton(
                icon: Icons.archive_outlined,
                label: 'Frunk',
                isActive: frunkOpen,
                onTap: onToggleFrunk,
              ),
              const SizedBox(width: 8),
              _ControlButton(
                icon: Icons.luggage,
                label: 'Trunk',
                isActive: trunkOpen,
                onTap: onToggleTrunk,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF00D4FF).withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF00D4FF).withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF00D4FF) : Colors.white38,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFF00D4FF) : Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

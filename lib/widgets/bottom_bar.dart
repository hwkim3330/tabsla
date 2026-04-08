import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  final double insideTemp;
  final bool acOn;
  final double batteryLevel;
  final double range;
  final bool isParked;
  final bool simMode;
  final String? activeApp;
  final VoidCallback onToggleDrive;
  final VoidCallback onToggleAc;
  final VoidCallback onToggleSim;
  final ValueChanged<String?> onAppSelect;

  const BottomBar({
    super.key,
    required this.insideTemp, required this.acOn, required this.batteryLevel,
    required this.range, required this.isParked, required this.simMode,
    required this.activeApp,
    required this.onToggleDrive, required this.onToggleAc, required this.onToggleSim,
    required this.onAppSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFEAEAEA), width: 0.5)),
      ),
      child: Row(
        children: [
          // Drive
          _Btn(isParked ? Icons.play_arrow_rounded : Icons.pause_rounded,
            isParked ? 'Drive' : 'Park', !isParked,
            isParked ? const Color(0xFF3B82F6) : const Color(0xFFEF4444), onToggleDrive),
          _Sep(),
          // Sim
          _Btn(Icons.route_rounded, 'Sim', simMode, const Color(0xFFF59E0B), onToggleSim),
          _Sep(),
          // AC
          GestureDetector(
            onTap: onToggleAc,
            child: Row(children: [
              Icon(Icons.ac_unit_rounded, size: 15, color: acOn ? const Color(0xFF3B82F6) : const Color(0xFFBBB)),
              const SizedBox(width: 4),
              Text('${insideTemp.toInt()}°', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333))),
            ]),
          ),
          _Sep(),

          // App shortcuts
          _AppIcon(Icons.music_note_rounded, 'music', activeApp, onAppSelect),
          _AppIcon(Icons.show_chart_rounded, 'energy', activeApp, onAppSelect),
          _AppIcon(Icons.videocam_rounded, 'dashcam', activeApp, onAppSelect),
          _AppIcon(Icons.directions_car_rounded, 'car', activeApp, onAppSelect),
          _AppIcon(Icons.brush_rounded, 'sketch', activeApp, onAppSelect),
          _AppIcon(Icons.sports_esports_rounded, 'game', activeApp, onAppSelect),
          _AppIcon(Icons.settings_rounded, 'settings', activeApp, onAppSelect),

          const Spacer(),
          // Time
          Text(_time(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF999))),
        ],
      ),
    );
  }

  String _time() { final n = DateTime.now(); return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}'; }
}

class _Btn extends StatelessWidget {
  final IconData icon; final String label; final bool active; final Color color; final VoidCallback onTap;
  const _Btn(this.icon, this.label, this.active, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: [
          Icon(icon, size: 16, color: active ? color : const Color(0xFFBBB)),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? color : const Color(0xFFBBB))),
        ]),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final IconData icon; final String id; final String? activeApp; final ValueChanged<String?> onSelect;
  const _AppIcon(this.icon, this.id, this.activeApp, this.onSelect);
  @override
  Widget build(BuildContext context) {
    final active = activeApp == id;
    return GestureDetector(
      onTap: () => onSelect(active ? null : id),
      child: Container(
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B82F6).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: active ? const Color(0xFF3B82F6) : const Color(0xFFBBBBBB)),
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 18, margin: const EdgeInsets.symmetric(horizontal: 6), color: const Color(0xFFE8E8E8));
  }
}

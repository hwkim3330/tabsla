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
    required this.insideTemp,
    required this.acOn,
    required this.batteryLevel,
    required this.range,
    required this.isParked,
    required this.simMode,
    required this.activeApp,
    required this.onToggleDrive,
    required this.onToggleAc,
    required this.onToggleSim,
    required this.onAppSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8F8),
        border: Border(top: BorderSide(color: Color(0xFFE4E6E8), width: 0.5)),
      ),
      child: Row(
        children: [
          _LauncherButton(
            onTap: () =>
                onAppSelect(activeApp == 'settings' ? null : 'settings'),
          ),
          const SizedBox(width: 12),
          _ClimateButton(temp: insideTemp, active: acOn, onTap: onToggleAc),
          const SizedBox(width: 10),
          _SeatButton(active: acOn),
          const SizedBox(width: 6),
          _DefrostButton(active: false),
          const SizedBox(width: 14),
          _Hairline(),
          const SizedBox(width: 14),
          _DriveButton(
            isParked: isParked,
            simMode: simMode,
            onToggleDrive: onToggleDrive,
            onToggleSim: onToggleSim,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AppIcon(
                      Icons.map_rounded,
                      null,
                      activeApp,
                      onAppSelect,
                      tooltip: 'Drive view',
                    ),
                    _AppIcon(
                      Icons.music_note_rounded,
                      'music',
                      activeApp,
                      onAppSelect,
                      tooltip: 'Media',
                    ),
                    _AppIcon(
                      Icons.show_chart_rounded,
                      'energy',
                      activeApp,
                      onAppSelect,
                      tooltip: 'Energy',
                    ),
                    _AppIcon(
                      Icons.videocam_rounded,
                      'dashcam',
                      activeApp,
                      onAppSelect,
                      tooltip: 'Dashcam',
                    ),
                    _AppIcon(
                      Icons.directions_car_rounded,
                      'car',
                      activeApp,
                      onAppSelect,
                      tooltip: 'Vehicle',
                    ),
                    _AppIcon(
                      Icons.brush_rounded,
                      'sketch',
                      activeApp,
                      onAppSelect,
                      tooltip: 'Sketchpad',
                    ),
                    _AppIcon(
                      Icons.sports_esports_rounded,
                      'game',
                      activeApp,
                      onAppSelect,
                      tooltip: 'Arcade',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _Hairline(),
          const SizedBox(width: 12),
          _RecentApp(activeApp: activeApp, onAppSelect: onAppSelect),
          const SizedBox(width: 10),
          Icon(Icons.volume_up_rounded, size: 19, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}

class _LauncherButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LauncherButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Controls',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFECEFF3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.apps_rounded,
            size: 21,
            color: Color(0xFF2F343A),
          ),
        ),
      ),
    );
  }
}

class _ClimateButton extends StatelessWidget {
  final double temp;
  final bool active;
  final VoidCallback onTap;

  const _ClimateButton({
    required this.temp,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEAF2FF) : const Color(0xFFECEFF3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.remove_rounded, size: 17, color: Colors.grey.shade500),
            const SizedBox(width: 7),
            Icon(
              Icons.ac_unit_rounded,
              size: 16,
              color: active ? const Color(0xFF2F80ED) : Colors.grey.shade500,
            ),
            const SizedBox(width: 5),
            Text(
              '${temp.toInt()}°',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF20242A),
              ),
            ),
            const SizedBox(width: 7),
            Icon(Icons.add_rounded, size: 17, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

class _SeatButton extends StatelessWidget {
  final bool active;
  const _SeatButton({required this.active});

  @override
  Widget build(BuildContext context) {
    return _IconButton(
      icon: Icons.event_seat_rounded,
      active: active,
      activeColor: const Color(0xFFF97316),
      tooltip: 'Seat heater',
    );
  }
}

class _DefrostButton extends StatelessWidget {
  final bool active;
  const _DefrostButton({required this.active});

  @override
  Widget build(BuildContext context) {
    return _IconButton(
      icon: Icons.air_rounded,
      active: active,
      activeColor: const Color(0xFF2F80ED),
      tooltip: 'Defrost',
    );
  }
}

class _DriveButton extends StatelessWidget {
  final bool isParked;
  final bool simMode;
  final VoidCallback onToggleDrive;
  final VoidCallback onToggleSim;

  const _DriveButton({
    required this.isParked,
    required this.simMode,
    required this.onToggleDrive,
    required this.onToggleSim,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: isParked ? 'Drive' : 'Park',
          child: GestureDetector(
            onTap: onToggleDrive,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isParked
                    ? const Color(0xFFECEFF3)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isParked ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 18,
                    color: isParked
                        ? const Color(0xFF2F343A)
                        : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isParked ? 'Drive' : 'Park',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isParked
                          ? const Color(0xFF2F343A)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: 'Simulation',
          child: GestureDetector(
            onTap: onToggleSim,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: simMode
                    ? const Color(0xFFFFF3D9)
                    : const Color(0xFFECEFF3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.route_rounded,
                size: 18,
                color: simMode
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF717982),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final String tooltip;

  const _IconButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.12)
              : const Color(0xFFECEFF3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? activeColor : const Color(0xFF717982),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final IconData icon;
  final String? id;
  final String? activeApp;
  final ValueChanged<String?> onSelect;
  final String tooltip;

  const _AppIcon(
    this.icon,
    this.id,
    this.activeApp,
    this.onSelect, {
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final active = id == null ? activeApp == null : activeApp == id;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => onSelect(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 34,
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEAF2FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 19,
            color: active ? const Color(0xFF2F80ED) : const Color(0xFF9AA1AA),
          ),
        ),
      ),
    );
  }
}

class _RecentApp extends StatelessWidget {
  final String? activeApp;
  final ValueChanged<String?> onAppSelect;

  const _RecentApp({required this.activeApp, required this.onAppSelect});

  @override
  Widget build(BuildContext context) {
    final icon = switch (activeApp) {
      'music' => Icons.music_note_rounded,
      'energy' => Icons.show_chart_rounded,
      'dashcam' => Icons.videocam_rounded,
      'car' => Icons.directions_car_rounded,
      'sketch' => Icons.brush_rounded,
      'game' => Icons.sports_esports_rounded,
      'settings' => Icons.settings_rounded,
      _ => Icons.navigation_rounded,
    };
    return Tooltip(
      message: 'Recent app',
      child: GestureDetector(
        onTap: () => onAppSelect(activeApp),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFECEFF3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF717982)),
        ),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: const Color(0xFFE0E3E7));
  }
}

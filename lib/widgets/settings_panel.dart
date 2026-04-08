import 'package:flutter/material.dart';

class SettingsPanel extends StatefulWidget {
  final bool simMode;
  final bool acOn;
  final double insideTemp;
  final int fanSpeed;
  final double batteryLevel;
  final VoidCallback onToggleSimMode;
  final VoidCallback onToggleAc;
  final ValueChanged<double> onTempChanged;
  final ValueChanged<int> onFanChanged;
  final VoidCallback onClose;

  const SettingsPanel({
    super.key,
    required this.simMode, required this.acOn, required this.insideTemp,
    required this.fanSpeed, required this.batteryLevel,
    required this.onToggleSimMode, required this.onToggleAc,
    required this.onTempChanged, required this.onFanChanged, required this.onClose,
  });

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  bool _autoPilot = false;
  bool _sentryMode = false;
  bool _speedLimitMode = false;
  int _followDist = 3;
  bool _regen = true;
  bool _steeringAssist = true;
  bool _blindSpot = true;
  bool _laneDeparture = true;
  bool _autoHighBeam = true;
  int _brightness = 7;
  String _displayMode = 'Dark';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F7),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.settings_rounded, color: Color(0xFF374151), size: 20),
                const SizedBox(width: 8),
                const Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const Spacer(),
                GestureDetector(onTap: widget.onClose,
                  child: Container(padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF6B7280)))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // === Driving ===
                _Section('Driving'),
                _Card(children: [
                  _Toggle('Autopilot', 'Autosteer & Traffic-Aware Cruise', Icons.auto_mode_rounded, _autoPilot,
                    (v) => setState(() => _autoPilot = v)),
                  const _Divider(),
                  _Toggle('Speed Limit Warning', 'Alert when exceeding limit', Icons.speed_rounded, _speedLimitMode,
                    (v) => setState(() => _speedLimitMode = v)),
                  const _Divider(),
                  _SliderRow('Follow Distance', '$_followDist', Icons.social_distance_rounded,
                    _followDist.toDouble(), 1, 7, 6, (v) => setState(() => _followDist = v.round())),
                  const _Divider(),
                  _Toggle('Regenerative Braking', 'Standard regeneration', Icons.battery_saver_rounded, _regen,
                    (v) => setState(() => _regen = v)),
                ]),

                const SizedBox(height: 16),
                _Section('Autopilot Safety'),
                _Card(children: [
                  _Toggle('Steering Assist', 'Lane keeping assistance', Icons.swap_horiz_rounded, _steeringAssist,
                    (v) => setState(() => _steeringAssist = v)),
                  const _Divider(),
                  _Toggle('Blind Spot Warning', 'Camera-based BSD', Icons.visibility_rounded, _blindSpot,
                    (v) => setState(() => _blindSpot = v)),
                  const _Divider(),
                  _Toggle('Lane Departure', 'Alert on unintended departure', Icons.add_road_rounded, _laneDeparture,
                    (v) => setState(() => _laneDeparture = v)),
                  const _Divider(),
                  _Toggle('Auto High Beam', 'Automatic headlight control', Icons.highlight_rounded, _autoHighBeam,
                    (v) => setState(() => _autoHighBeam = v)),
                ]),

                const SizedBox(height: 16),
                _Section('Climate'),
                _Card(children: [
                  _Toggle('A/C', 'Air conditioning', Icons.ac_unit_rounded, widget.acOn, (_) => widget.onToggleAc()),
                  const _Divider(),
                  _SliderRow('Temperature', '${widget.insideTemp.toInt()}°C', Icons.thermostat_rounded,
                    widget.insideTemp, 16, 30, 14, widget.onTempChanged),
                  const _Divider(),
                  _SliderRow('Fan Speed', '${widget.fanSpeed}', Icons.air_rounded,
                    widget.fanSpeed.toDouble(), 1, 5, 4, (v) => widget.onFanChanged(v.round())),
                ]),

                const SizedBox(height: 16),
                _Section('Display'),
                _Card(children: [
                  _SliderRow('Brightness', '$_brightness', Icons.brightness_6_rounded,
                    _brightness.toDouble(), 1, 10, 9, (v) => setState(() => _brightness = v.round())),
                  const _Divider(),
                  _OptionRow('Display Mode', _displayMode, Icons.dark_mode_rounded,
                    ['Dark', 'Light', 'Auto'], (v) => setState(() => _displayMode = v)),
                ]),

                const SizedBox(height: 16),
                _Section('Security'),
                _Card(children: [
                  _Toggle('Sentry Mode', 'Camera security while parked', Icons.shield_rounded, _sentryMode,
                    (v) => setState(() => _sentryMode = v)),
                ]),

                const SizedBox(height: 16),
                _Section('Simulation'),
                _Card(children: [
                  _Toggle('Simulation Mode', widget.simMode ? 'Virtual driving active' : 'Using real GPS',
                    Icons.route_rounded, widget.simMode, (_) => widget.onToggleSimMode(),
                    activeColor: const Color(0xFFF59E0B)),
                ]),

                const SizedBox(height: 16),
                _Section('Vehicle Info'),
                _Card(children: [
                  _InfoRow('Battery', '${widget.batteryLevel.toInt()}%', widget.batteryLevel > 30 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                  const _Divider(),
                  _InfoRow('Software', 'v2026.14.2', const Color(0xFF3B82F6)),
                  const _Divider(),
                  _InfoRow('Tires', '36 PSI (All)', const Color(0xFF22C55E)),
                  const _Divider(),
                  _InfoRow('Odometer', '12,847 km', const Color(0xFF6B7280)),
                  const _Divider(),
                  _InfoRow('Model', 'Tabsla Pro AWD', const Color(0xFF6B7280)),
                ]),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String t;
  const _Section(this.t);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
    child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
  );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
    child: Column(children: children),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
  );
}

class _Toggle extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _Toggle(this.title, this.subtitle, this.icon, this.value, this.onChanged, {this.activeColor = const Color(0xFF3B82F6)});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: value ? activeColor : const Color(0xFFBBBBBB)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: activeColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ],
    ),
  );
}

class _SliderRow extends StatelessWidget {
  final String title, valueStr;
  final IconData icon;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderRow(this.title, this.valueStr, this.icon, this.value, this.min, this.max, this.divisions, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(children: [
      Row(children: [
        Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
        const Spacer(),
        Text(valueStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6))),
      ]),
      SliderTheme(
        data: SliderThemeData(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          activeTrackColor: const Color(0xFF3B82F6), inactiveTrackColor: const Color(0xFFE5E7EB),
          thumbColor: Colors.white, overlayShape: SliderComponentShape.noOverlay),
        child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
      ),
    ]),
  );
}

class _OptionRow extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _OptionRow(this.title, this.value, this.icon, this.options, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Icon(icon, size: 20, color: const Color(0xFF6B7280)),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
      const Spacer(),
      ...options.map((o) => GestureDetector(
        onTap: () => onChanged(o),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: value == o ? const Color(0xFF3B82F6) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6)),
          child: Text(o, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: value == o ? Colors.white : const Color(0xFF6B7280))),
        ),
      )),
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoRow(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ],
    ),
  );
}

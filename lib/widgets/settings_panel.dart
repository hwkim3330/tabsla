import 'package:flutter/material.dart';

class SettingsPanel extends StatelessWidget {
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
    required this.simMode,
    required this.acOn,
    required this.insideTemp,
    required this.fanSpeed,
    required this.batteryLevel,
    required this.onToggleSimMode,
    required this.onToggleAc,
    required this.onTempChanged,
    required this.onFanChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.settings, color: Color(0xFF6B7280), size: 20),
                const SizedBox(width: 8),
                const Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Driving Mode
                _SectionTitle('Driving Mode'),
                _SettingCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: simMode ? const Color(0xFFF59E0B).withValues(alpha: 0.1) : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          simMode ? Icons.videogame_asset : Icons.gps_fixed,
                          color: simMode ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(simMode ? 'Simulation' : 'Real GPS', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(
                              simMode ? 'Virtual driving in Seoul' : 'Using device GPS',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: simMode,
                        onChanged: (_) => onToggleSimMode(),
                        activeColor: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                _SectionTitle('Climate Control'),

                // AC toggle
                _SettingCard(
                  child: Row(
                    children: [
                      Icon(Icons.ac_unit, color: acOn ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF), size: 20),
                      const SizedBox(width: 12),
                      const Text('Air Conditioning', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Switch(
                        value: acOn,
                        onChanged: (_) => onToggleAc(),
                        activeColor: const Color(0xFF3B82F6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Temperature
                _SettingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.thermostat, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 12),
                          const Text('Temperature', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text('${insideTemp.toInt()}°C', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        ],
                      ),
                      Slider(
                        value: insideTemp,
                        min: 16, max: 30, divisions: 14,
                        activeColor: const Color(0xFF3B82F6),
                        onChanged: onTempChanged,
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('16°C', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                          Text('30°C', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Fan speed
                _SettingCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.air, color: Color(0xFF6B7280), size: 20),
                          const SizedBox(width: 12),
                          const Text('Fan Speed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text('$fanSpeed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (i) {
                          final level = i + 1;
                          final active = level <= fanSpeed;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => onFanChanged(level),
                              child: Container(
                                height: 32,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: active ? const Color(0xFF3B82F6) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text('$level', style: TextStyle(
                                    color: active ? Colors.white : const Color(0xFF9CA3AF),
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                  )),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                _SectionTitle('Vehicle Info'),
                _SettingCard(
                  child: Column(
                    children: [
                      _InfoRow('Battery', '${batteryLevel.toInt()}%', batteryLevel > 30 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                      const Divider(height: 16),
                      _InfoRow('Software', 'v2026.12.1', const Color(0xFF22C55E)),
                      const Divider(height: 16),
                      _InfoRow('Model', 'Dashboard Pro', const Color(0xFF3B82F6)),
                      const Divider(height: 16),
                      _InfoRow('Tires', '36 PSI (All)', const Color(0xFF22C55E)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  const _SettingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class CarModelViewer extends StatefulWidget {
  final double batteryLevel;
  final double range;
  final VoidCallback onClose;
  const CarModelViewer({super.key, required this.batteryLevel, required this.range, required this.onClose});

  @override
  State<CarModelViewer> createState() => _CarModelViewerState();
}

class _CarModelViewerState extends State<CarModelViewer> {
  final _carCtrl = Flutter3DController();
  final _seatCtrl = Flutter3DController();
  int _tab = 0;
  bool _carLoaded = false;
  bool _seatLoaded = false;
  String? _carError;
  String? _seatError;
  double _carProgress = 0;
  double _seatProgress = 0;

  @override
  void initState() {
    super.initState();
    _carCtrl.onModelLoaded.addListener(() {
      if (_carCtrl.onModelLoaded.value) {
        _carCtrl.startRotation(rotationSpeed: 10);
      }
    });
    _seatCtrl.onModelLoaded.addListener(() {
      if (_seatCtrl.onModelLoaded.value) {
        _seatCtrl.startRotation(rotationSpeed: 15);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F9FA), Color(0xFFEEEFF1)],
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                _TabBtn('Exterior', 0, _tab, (i) => setState(() => _tab = i)),
                const SizedBox(width: 6),
                _TabBtn('Seat', 1, _tab, (i) => setState(() => _tab = i)),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF888)),
                  ),
                ),
              ],
            ),
          ),

          // 3D viewers
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                // Car model
                Stack(
                  children: [
                    Flutter3DViewer(
                      activeGestureInterceptor: true,
                      progressBarColor: const Color(0xFF3B82F6),
                      enableTouch: true,
                      controller: _carCtrl,
                      src: 'https://hwkim3330.github.io/tabsla/models/ferrari.glb',
                      onProgress: (v) => setState(() => _carProgress = v),
                      onLoad: (_) => setState(() => _carLoaded = true),
                      onError: (e) => setState(() => _carError = e),
                    ),
                    if (!_carLoaded && _carError == null)
                      Center(child: _Loading('Car', _carProgress)),
                    if (_carError != null)
                      Center(child: _Error(_carError!)),
                  ],
                ),
                // Seat model
                Stack(
                  children: [
                    Flutter3DViewer(
                      activeGestureInterceptor: true,
                      progressBarColor: const Color(0xFF3B82F6),
                      enableTouch: true,
                      controller: _seatCtrl,
                      src: 'https://hwkim3330.github.io/tabsla/models/car-seat.glb',
                      onProgress: (v) => setState(() => _seatProgress = v),
                      onLoad: (_) => setState(() => _seatLoaded = true),
                      onError: (e) => setState(() => _seatError = e),
                    ),
                    if (!_seatLoaded && _seatError == null)
                      Center(child: _Loading('Seat', _seatProgress)),
                    if (_seatError != null)
                      Center(child: _Error(_seatError!)),
                  ],
                ),
              ],
            ),
          ),

          // Info cards
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                _Card(Icons.battery_charging_full_rounded, '${widget.batteryLevel.toInt()}%',
                    widget.batteryLevel > 30 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                const SizedBox(width: 6),
                _Card(Icons.speed_rounded, '${widget.range.toInt()} km', const Color(0xFF3B82F6)),
                const SizedBox(width: 6),
                _Card(Icons.lock_rounded, 'Locked', const Color(0xFF22C55E)),
                const SizedBox(width: 6),
                _Card(Icons.tire_repair_rounded, '36 PSI', const Color(0xFF6B7280)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  final String label;
  final double progress;
  const _Loading(this.label, this.progress);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32, height: 32,
          child: CircularProgressIndicator(
            value: progress > 0 ? progress : null,
            strokeWidth: 2.5,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          progress > 0 ? '$label ${(progress * 100).toInt()}%' : 'Loading $label...',
          style: const TextStyle(color: Color(0xFF999), fontSize: 11),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  final String error;
  const _Error(this.error);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 32),
        const SizedBox(height: 6),
        Text(error, style: const TextStyle(color: Color(0xFF999), fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  const _TabBtn(this.label, this.index, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B82F6) : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(
          color: active ? Colors.white : const Color(0xFF888),
          fontSize: 12, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _Card(this.icon, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

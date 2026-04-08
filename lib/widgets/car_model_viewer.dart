import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../data/haptics.dart';

class CarModelViewer extends StatefulWidget {
  final double batteryLevel;
  final double range;
  final VoidCallback onClose;
  const CarModelViewer({super.key, required this.batteryLevel, required this.range, required this.onClose});

  @override
  State<CarModelViewer> createState() => _CarModelViewerState();
}

class _CarModelViewerState extends State<CarModelViewer> {
  late final WebViewController _wv;
  bool _loaded = false;
  bool _error = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _wv = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF0F0F2))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loaded = true),
        onWebResourceError: (_) => setState(() => _error = true),
      ))
      ..loadRequest(Uri.parse('https://hwkim3330.github.io/tabsla/'));
  }

  void _switchTab(int tab) {
    Haptics.tap();
    setState(() => _tab = tab);
    _wv.runJavaScript("loadModel('${tab == 0 ? 'car' : 'seat'}')");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F0F2),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                _TabBtn('Exterior', 0 == _tab, () => _switchTab(0)),
                const SizedBox(width: 6),
                _TabBtn('Seat', 1 == _tab, () => _switchTab(1)),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF666)),
                  ),
                ),
              ],
            ),
          ),

          // WebView
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _wv),
                if (!_loaded && !_error)
                  const Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF3B82F6))),
                      SizedBox(height: 8),
                      Text('Loading 3D...', style: TextStyle(color: Color(0xFF999), fontSize: 11)),
                    ],
                  )),
                if (_error)
                  Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Color(0xFFCCC), size: 36),
                      const SizedBox(height: 6),
                      const Text('Failed to load', style: TextStyle(color: Color(0xFF999), fontSize: 12)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() => _error = false);
                          _wv.loadRequest(Uri.parse('https://hwkim3330.github.io/tabsla/'));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  )),
              ],
            ),
          ),

          // Info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                _Info(Icons.battery_charging_full_rounded, '${widget.batteryLevel.toInt()}%',
                  widget.batteryLevel > 30 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                const SizedBox(width: 16),
                _Info(Icons.speed_rounded, '${widget.range.toInt()} km', const Color(0xFF3B82F6)),
                const SizedBox(width: 16),
                _Info(Icons.lock_rounded, 'Locked', const Color(0xFF22C55E)),
                const SizedBox(width: 16),
                _Info(Icons.tire_repair_rounded, '36 PSI', const Color(0xFF6B7280)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B82F6) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(
          color: active ? Colors.white : const Color(0xFF666),
          fontSize: 12, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _Info(this.icon, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CarModelViewer extends StatefulWidget {
  final double batteryLevel;
  final VoidCallback onClose;
  const CarModelViewer({super.key, required this.batteryLevel, required this.onClose});

  @override
  State<CarModelViewer> createState() => _CarModelViewerState();
}

class _CarModelViewerState extends State<CarModelViewer> {
  late final WebViewController _controller;
  bool _loaded = false;

  static const _pageUrl = 'https://hwkim3330.github.io/tabsla/';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF111318))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loaded = true),
      ))
      ..loadRequest(Uri.parse(_pageUrl));
  }

  void _switchModel(String name) {
    _controller.runJavaScript("loadModel('$name')");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111318),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _Tab('Exterior', true, () => _switchModel('exterior')),
                const SizedBox(width: 8),
                _Tab('Seat', false, () => _switchModel('seat')),
                const SizedBox(width: 8),
                _Tab('Low-Poly', false, () => _switchModel('lowpoly')),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20),
                ),
              ],
            ),
          ),
          // WebView
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (!_loaded)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6))),
                        SizedBox(height: 8),
                        Text('Loading 3D model...', style: TextStyle(color: Colors.white24, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Info(Icons.battery_charging_full_rounded,
                    '${widget.batteryLevel.toInt()}%',
                    widget.batteryLevel > 30 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                _Info(Icons.lock_rounded, 'Locked', const Color(0xFF22C55E)),
                _Info(Icons.tire_repair_rounded, '36 PSI', const Color(0xFF22C55E)),
                _Info(Icons.update_rounded, 'v2026.12', const Color(0xFF3B82F6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool initial;
  final VoidCallback onTap;
  const _Tab(this.label, this.initial, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w500)),
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
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}

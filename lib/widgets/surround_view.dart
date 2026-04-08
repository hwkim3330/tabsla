import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../data/vehicle_state.dart';

class SurroundView extends StatefulWidget {
  final double speed, steeringAngle, batteryLevel, range;
  final String gear;
  final List<DetectedObject> objects;
  final double animationValue;

  const SurroundView({
    super.key,
    required this.speed, required this.gear, required this.steeringAngle,
    required this.objects, required this.animationValue,
    required this.batteryLevel, required this.range,
  });

  @override
  State<SurroundView> createState() => _SurroundViewState();
}

class _SurroundViewState extends State<SurroundView> {
  late final WebViewController _wv;
  bool _loaded = false;

  // HTML is hosted on GitHub Pages — loadHtmlString blocks CDN scripts on Android WebView

  @override
  void initState() {
    super.initState();
    _wv = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0C1018))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loaded = true),
      ))
      ..loadRequest(Uri.parse('https://hwkim3330.github.io/tabsla/drive.html'));
  }

  @override
  void didUpdateWidget(SurroundView old) {
    super.didUpdateWidget(old);
    if (_loaded) {
      final objs = widget.objects.map((o) => {'x': o.x, 'y': o.y, 'type': o.type}).toList();
      _wv.runJavaScript("updateDrive(${widget.speed.toStringAsFixed(1)},${widget.steeringAngle.toStringAsFixed(1)},${jsonEncode(objs)})");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0C1018),
      child: Stack(
        children: [
          WebViewWidget(controller: _wv),
          if (!_loaded) const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6))),

          // HUD — speed, gear, battery
          Positioned(top: 12, left: 16, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: ['P','R','N','D'].map((g) {
                final on = widget.gear == g;
                return Container(
                  width: 22, height: 22, margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(4)),
                  child: Center(child: Text(g, style: TextStyle(
                    color: on ? const Color(0xFF0C1018) : Colors.white.withValues(alpha: 0.15),
                    fontSize: 11, fontWeight: on ? FontWeight.w800 : FontWeight.w400, height: 1))),
                );
              }).toList()),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(widget.speed.toInt().toString(), style: const TextStyle(
                  color: Colors.white, fontSize: 48, fontWeight: FontWeight.w300, height: 1, letterSpacing: -3,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)])),
                Padding(padding: const EdgeInsets.only(bottom: 5, left: 4),
                  child: Text('km/h', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12))),
              ]),
              const SizedBox(height: 6),
              if (widget.speed > 0) Container(
                width: 28, height: 28,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                  border: Border.all(color: const Color(0xFFDC2626), width: 2.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)]),
                child: const Center(child: Text('60', style: TextStyle(color: Color(0xFF1F2937), fontSize: 10, fontWeight: FontWeight.w800, height: 1))),
              ),
            ],
          )),
          Positioned(top: 12, right: 14, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
            child: Row(children: [
              Text('${widget.range.toInt()} km', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
              const SizedBox(width: 6),
              Icon(Icons.battery_std, size: 14, color: widget.batteryLevel > 30 ? const Color(0xFF34D399) : const Color(0xFFEF4444)),
              Text(' ${widget.batteryLevel.toInt()}%', style: TextStyle(
                color: widget.batteryLevel > 30 ? const Color(0xFF34D399) : const Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          )),
          if (widget.objects.isNotEmpty)
            Positioned(top: 36, right: 14, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34D399))),
                const SizedBox(width: 4),
                Text('${widget.objects.length} detected', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
              ]),
            )),
        ],
      ),
    );
  }
}

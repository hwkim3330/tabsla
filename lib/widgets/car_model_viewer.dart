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
  late WebViewController _wv;
  bool _loaded = false;
  int _tab = 0; // 0=exterior, 1=4seats

  static const _carGlb = 'https://hwkim3330.github.io/tabsla/models/ferrari.glb';
  static const _seatPage = 'https://hwkim3330.github.io/car-seat/four-seats-tablet.html';

  String get _carHtml => '''
<!DOCTYPE html><html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=no">
<script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.4.0/model-viewer.min.js"></script>
<style>*{margin:0;padding:0}body{background:#f0f0f2;overflow:hidden}
model-viewer{width:100vw;height:100vh;--poster-color:#f0f0f2;--progress-bar-color:#3B82F6}</style>
</head><body>
<model-viewer src="$_carGlb" alt="Car" auto-rotate auto-rotate-delay="0"
  rotation-per-second="8deg" camera-controls touch-action="pan-y"
  shadow-intensity="1" shadow-softness="0.8" exposure="2"
  tone-mapping="commerce" environment-image="neutral"
  camera-orbit="30deg 65deg 3m" field-of-view="30deg"
  style="background-color:#f0f0f2"></model-viewer>
</body></html>''';

  @override
  void initState() {
    super.initState();
    _initWv(_carHtml, isHtml: true);
  }

  void _initWv(String src, {bool isHtml = false}) {
    _wv = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF0F0F2))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) { if (mounted) setState(() => _loaded = true); },
      ));

    if (isHtml) {
      _wv.loadHtmlString(src);
    } else {
      _wv.loadRequest(Uri.parse(src));
    }
  }

  void _switchTab(int tab) {
    if (tab == _tab) return;
    Haptics.tap();
    setState(() { _tab = tab; _loaded = false; });

    if (tab == 0) {
      _initWv(_carHtml, isHtml: true);
    } else {
      _initWv(_seatPage);
    }
    setState(() {});
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
                _TabBtn('Exterior', _tab == 0, () => _switchTab(0)),
                const SizedBox(width: 6),
                _TabBtn('4 Seats', _tab == 1, () => _switchTab(1)),
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
                if (!_loaded)
                  const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF3B82F6))),
              ],
            ),
          ),

          // Bottom info
          if (_tab == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  _Info(Icons.battery_charging_full_rounded, '${widget.batteryLevel.toInt()}%',
                    widget.batteryLevel > 30 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                  const SizedBox(width: 16),
                  _Info(Icons.speed_rounded, '${widget.range.toInt()} km', const Color(0xFF3B82F6)),
                  const SizedBox(width: 16),
                  _Info(Icons.lock_rounded, 'Locked', const Color(0xFF22C55E)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _TabBtn(this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF3B82F6) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: active ? Colors.white : const Color(0xFF666), fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}

class _Info extends StatelessWidget {
  final IconData icon; final String value; final Color color;
  const _Info(this.icon, this.value, this.color);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: color),
    const SizedBox(width: 4),
    Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
  ]);
}

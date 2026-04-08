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
  int _tab = 0; // 0=car, 1=seats

  static const _base = 'https://hwkim3330.github.io/tabsla/models';
  static const _seatPage = 'https://hwkim3330.github.io/car-seat/four-seats-tablet.html';

  static const _cars = [
    _Car('Ferrari', 'ferrari.glb', '30deg 65deg 3m'),
    _Car('Lambo', 'lambo.glb', '30deg 65deg 4m'),
    _Car('Low-Poly', 'lowpoly_car.glb', '30deg 65deg 2.5m'),
  ];

  int _carIdx = 0;
  int _colorIdx = 0;

  static const _colors = [
    _PaintColor('Default', null),
    _PaintColor('Red', '0.8 0.1 0.1'),
    _PaintColor('Blue', '0.1 0.2 0.8'),
    _PaintColor('White', '0.95 0.95 0.95'),
    _PaintColor('Black', '0.08 0.08 0.08'),
    _PaintColor('Green', '0.1 0.6 0.3'),
    _PaintColor('Orange', '0.9 0.5 0.1'),
  ];

  String get _carHtml => '''
<!DOCTYPE html><html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=no">
<script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.4.0/model-viewer.min.js"></script>
<style>
*{margin:0;padding:0}body{background:#e8e8ec;overflow:hidden}
model-viewer{width:100vw;height:100vh;--poster-color:#e8e8ec;--progress-bar-color:#3B82F6}
</style>
</head><body>
<model-viewer id="mv"
  src="$_base/${_cars[_carIdx].file}"
  alt="Car" auto-rotate auto-rotate-delay="0"
  rotation-per-second="6deg" camera-controls touch-action="pan-y"
  shadow-intensity="0.8" shadow-softness="1"
  exposure="1.2"
  tone-mapping="commerce"
  environment-image="neutral"
  camera-orbit="${_cars[_carIdx].orbit}"
  min-camera-orbit="auto auto 1m"
  max-camera-orbit="auto auto 10m"
  field-of-view="30deg"
  style="background-color:#e8e8ec"
></model-viewer>
<script>
const mv=document.getElementById('mv');

function changeCar(file, orbit){
  mv.src='$_base/'+file;
  mv.cameraOrbit=orbit;
}

function changeColor(r,g,b){
  mv.addEventListener('load',function onL(){
    try{
      for(const m of mv.model.materials){
        m.pbrMetallicRoughness.setBaseColorFactor([r,g,b,1]);
      }
    }catch(e){}
    mv.removeEventListener('load',onL);
  });
  // Also apply immediately if already loaded
  try{
    if(mv.model){
      for(const m of mv.model.materials){
        m.pbrMetallicRoughness.setBaseColorFactor([r,g,b,1]);
      }
    }
  }catch(e){}
}

function resetColor(){
  // Reload model to reset materials
  const src=mv.src;
  mv.src='';
  setTimeout(()=>{mv.src=src},50);
}
</script>
</body></html>''';

  @override
  void initState() {
    super.initState();
    _loadCar();
  }

  void _loadCar() {
    setState(() => _loaded = false);
    _wv = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE8E8EC))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) { if (mounted) setState(() => _loaded = true); },
      ))
      ..loadHtmlString(_carHtml);
  }

  void _loadSeats() {
    setState(() => _loaded = false);
    _wv = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF5F5F7))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) { if (mounted) setState(() => _loaded = true); },
      ))
      ..loadRequest(Uri.parse(_seatPage));
  }

  void _switchTab(int tab) {
    if (tab == _tab) return;
    Haptics.tap();
    setState(() => _tab = tab);
    if (tab == 0) _loadCar(); else _loadSeats();
  }

  void _selectCar(int idx) {
    Haptics.tap();
    setState(() { _carIdx = idx; _colorIdx = 0; });
    _wv.runJavaScript("changeCar('${_cars[idx].file}','${_cars[idx].orbit}')");
  }

  void _selectColor(int idx) {
    Haptics.tap();
    setState(() => _colorIdx = idx);
    final c = _colors[idx];
    if (c.rgb == null) {
      _wv.runJavaScript("resetColor()");
    } else {
      final parts = c.rgb!.split(' ');
      _wv.runJavaScript("changeColor(${parts[0]},${parts[1]},${parts[2]})");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8E8EC),
      child: Column(
        children: [
          // Header tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(7)),
                    child: const Icon(Icons.close_rounded, size: 17, color: Color(0xFF666)),
                  ),
                ),
              ],
            ),
          ),

          // Car selector (only on exterior tab)
          if (_tab == 0)
            Container(
              height: 36,
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: List.generate(_cars.length, (i) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => _selectCar(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _carIdx == i ? const Color(0xFF3B82F6) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Text(_cars[i].name, style: TextStyle(
                        color: _carIdx == i ? Colors.white : const Color(0xFF888),
                        fontSize: 11, fontWeight: FontWeight.w600))),
                    ),
                  ),
                )),
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

          // Color picker + info (only on exterior tab)
          if (_tab == 0)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  // Color dots
                  Row(
                    children: [
                      const Text('Color', style: TextStyle(fontSize: 10, color: Color(0xFF999), fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      ...List.generate(_colors.length, (i) {
                        Color dotColor;
                        if (_colors[i].rgb == null) {
                          dotColor = const Color(0xFFCCCCCC);
                        } else {
                          final p = _colors[i].rgb!.split(' ').map((s) => (double.parse(s) * 255).toInt()).toList();
                          dotColor = Color.fromARGB(255, p[0], p[1], p[2]);
                        }
                        return GestureDetector(
                          onTap: () => _selectColor(i),
                          child: Container(
                            width: 22, height: 22,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _colorIdx == i ? const Color(0xFF3B82F6) : const Color(0xFFDDD),
                                width: _colorIdx == i ? 2.5 : 1),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Info row
                  Row(
                    children: [
                      _Info(Icons.battery_charging_full_rounded, '${widget.batteryLevel.toInt()}%',
                        widget.batteryLevel > 30 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                      const SizedBox(width: 14),
                      _Info(Icons.speed_rounded, '${widget.range.toInt()} km', const Color(0xFF3B82F6)),
                      const SizedBox(width: 14),
                      _Info(Icons.lock_rounded, 'Locked', const Color(0xFF22C55E)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Car {
  final String name, file, orbit;
  const _Car(this.name, this.file, this.orbit);
}

class _PaintColor {
  final String name;
  final String? rgb; // "r g b" in 0-1 range, null = default
  const _PaintColor(this.name, this.rgb);
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
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 3),
    Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  ]);
}

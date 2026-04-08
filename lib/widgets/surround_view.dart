import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../data/vehicle_state.dart';

class SurroundView extends StatefulWidget {
  final double speed, steeringAngle, batteryLevel, range, animationValue;
  final String gear;
  final List<DetectedObject> objects;

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

  static const _html = r'''
<!DOCTYPE html><html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=no">
<script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.4.0/model-viewer.min.js"></script>
<style>
*{margin:0;padding:0;overflow:hidden}
body{background:#0C1018;width:100vw;height:100vh;position:relative}

/* Road perspective via CSS */
.road-scene{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center}

/* Sky */
.sky{flex:0 0 18%;background:linear-gradient(180deg,#080C14 0%,#101820 60%,#1A2332 100%);width:100%}

/* Road area */
.road-area{flex:1;width:100%;position:relative;overflow:hidden}

/* Road surface - perspective trapezoid */
.road-surface{
  position:absolute;left:50%;top:0;
  width:30%;height:100%;
  transform:translateX(-50%) perspective(300px) rotateX(2deg);
  background:linear-gradient(180deg,#222A36 0%,#2C3544 50%,#343E4E 100%);
}

/* Road edges */
.road-edge-l,.road-edge-r{
  position:absolute;top:0;height:100%;width:2px;
  background:rgba(255,255,255,0.25);
}
.road-edge-l{left:35%}.road-edge-r{right:35%}

/* Grass sides */
.grass-l,.grass-r{position:absolute;top:0;height:100%;background:#0D1A10}
.grass-l{left:0;right:66%}.grass-r{left:66%;right:0}

/* Shoulder */
.shoulder-l,.shoulder-r{position:absolute;top:0;height:100%;background:#1A2430;width:2%}
.shoulder-l{left:34%}.shoulder-r{right:34%}

/* Lane dashes - animated */
.lane{position:absolute;left:50%;width:2px;transform:translateX(-50%)}
.lane.l1{margin-left:-8%}.lane.l2{margin-left:0}.lane.l3{margin-left:8%}
.dash{width:2px;height:20px;background:rgba(255,255,255,0.15);margin-bottom:25px;border-radius:1px}

@keyframes flow{from{transform:translateY(0)}to{transform:translateY(45px)}}
.lane-scroll{animation:flow 0.8s linear infinite}

/* Autopilot blue glow */
.ap-path{position:absolute;left:50%;transform:translateX(-50%);top:0;height:100%;width:6%;
  background:linear-gradient(180deg,rgba(59,130,246,0.02),rgba(59,130,246,0.08));
  border-radius:50%;filter:blur(8px);pointer-events:none}

/* model-viewer sits on top */
model-viewer{
  position:absolute;bottom:0;left:50%;transform:translateX(-50%);
  width:80%;height:55%;
  --poster-color:transparent;
  z-index:5;
}

/* Detected vehicle boxes */
.det{position:absolute;border:1.5px solid;border-radius:3px;z-index:4;
  display:flex;align-items:flex-end;justify-content:center;padding-bottom:2px;
  font-size:8px;font-weight:600;transition:all 0.3s ease}
</style>
</head>
<body>
<div class="road-scene">
  <div class="sky"></div>
  <div class="road-area">
    <div class="grass-l"></div>
    <div class="grass-r"></div>
    <div class="shoulder-l"></div>
    <div class="shoulder-r"></div>
    <div class="road-surface"></div>
    <div class="road-edge-l"></div>
    <div class="road-edge-r"></div>
    <div class="lane l1"><div class="lane-scroll" id="ls1"></div></div>
    <div class="lane l2"><div class="lane-scroll" id="ls2"></div></div>
    <div class="lane l3"><div class="lane-scroll" id="ls3"></div></div>
    <div class="ap-path"></div>
    <div id="detLayer"></div>
  </div>
</div>

<model-viewer id="mv"
  src="https://hwkim3330.github.io/tabsla/models/lowpoly_car.glb"
  alt="car"
  camera-controls
  camera-orbit="180deg 55deg 2.2m"
  min-camera-orbit="auto 20deg 1m"
  max-camera-orbit="auto 80deg 5m"
  field-of-view="25deg"
  exposure="1.4"
  shadow-intensity="0.8"
  shadow-softness="1"
  environment-image="neutral"
  tone-mapping="commerce"
  interaction-prompt="none"
  style="background:transparent"
></model-viewer>

<script>
const mv = document.getElementById('mv');
const detLayer = document.getElementById('detLayer');
const laneScrolls = [document.getElementById('ls1'),document.getElementById('ls2'),document.getElementById('ls3')];

// Fill lane dashes
laneScrolls.forEach(ls=>{
  for(let i=0;i<15;i++){
    const d=document.createElement('div');
    d.className='dash';
    ls.appendChild(d);
  }
});

let speed = 0;

function setSpeed(s) {
  speed = s;
  const dur = s > 5 ? Math.max(0.15, 3/s) : 99;
  laneScrolls.forEach(ls => ls.style.animationDuration = dur + 's');
}

function setSteer(deg) {
  mv.cameraOrbit = (180 + deg * -0.8) + 'deg 55deg 2.2m';
}

const detColors = {car:'59,130,246',truck:'251,191,36',bus:'251,191,36',pedestrian:'248,113,113',bike:'52,211,153'};

function setDetected(objs) {
  detLayer.innerHTML = '';
  if (!objs) return;
  const arr = typeof objs === 'string' ? JSON.parse(objs) : objs;
  const area = detLayer.parentElement;
  const aw = area.offsetWidth, ah = area.offsetHeight;

  arr.forEach(o => {
    const col = detColors[o.type] || '148,163,184';
    const x = aw * (0.5 + o.x * 0.3);
    const y = ah * (o.y * 0.7);
    const scale = 0.4 + o.y * 0.6;
    const w = (o.type==='truck'||o.type==='bus' ? 35 : o.type==='pedestrian' ? 15 : 25) * scale;
    const h = (o.type==='truck'||o.type==='bus' ? 50 : o.type==='pedestrian' ? 35 : 30) * scale;
    const dist = Math.round((1-o.y)*80+5);

    const el = document.createElement('div');
    el.className = 'det';
    el.style.cssText = `left:${x-w/2}px;top:${y-h}px;width:${w}px;height:${h}px;
      border-color:rgba(${col},0.5);background:rgba(${col},0.08);color:rgba(${col},0.6)`;
    el.textContent = dist+'m';
    detLayer.appendChild(el);
  });
}

window.updateDrive = function(spd, str, objs) {
  setSpeed(spd);
  setSteer(str);
  setDetected(objs);
};
</script>
</body></html>
''';

  @override
  void initState() {
    super.initState();
    _wv = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0C1018))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loaded = true),
      ))
      ..loadHtmlString(_html);
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

          // HUD overlay
          Positioned(top: 12, left: 16, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: ['P','R','N','D'].map((g) {
                final on = widget.gear == g;
                return Container(
                  width: 24, height: 24, margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(5)),
                  child: Center(child: Text(g, style: TextStyle(
                    color: on ? const Color(0xFF0C1018) : Colors.white.withValues(alpha: 0.12),
                    fontSize: 12, fontWeight: on ? FontWeight.w800 : FontWeight.w400, height: 1))),
                );
              }).toList()),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(widget.speed.toInt().toString(), style: const TextStyle(
                  color: Colors.white, fontSize: 56, fontWeight: FontWeight.w200, height: 1, letterSpacing: -3,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)])),
                Padding(padding: const EdgeInsets.only(bottom: 6, left: 5),
                  child: Text('km/h', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13))),
              ]),
              if (widget.speed > 0) ...[
                const SizedBox(height: 8),
                Container(width: 30, height: 30,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                    border: Border.all(color: const Color(0xFFDC2626), width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4)]),
                  child: const Center(child: Text('60', style: TextStyle(color: Color(0xFF1F2937), fontSize: 11, fontWeight: FontWeight.w800, height: 1)))),
              ],
            ],
          )),
          Positioned(top: 12, right: 14, child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                Icon(Icons.battery_std, size: 15, color: widget.batteryLevel > 30 ? const Color(0xFF34D399) : const Color(0xFFEF4444)),
                const SizedBox(width: 3),
                Text('${widget.batteryLevel.toInt()}%', style: TextStyle(
                  color: widget.batteryLevel > 30 ? const Color(0xFF34D399) : const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4)])),
              ]),
              Text('${widget.range.toInt()} km', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10)),
            ],
          )),
        ],
      ),
    );
  }
}

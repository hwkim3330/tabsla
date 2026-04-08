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
body{background:#0C1018;width:100vw;height:100vh}

/* Entire scene rotates together on touch */
.scene{
  position:absolute;inset:0;
  transform-origin:50% 70%;
  transition:transform 0.1s ease-out;
  transform:perspective(800px) rotateY(0deg) rotateX(0deg);
}

.sky{position:absolute;top:0;left:0;right:0;height:20%;
  background:linear-gradient(180deg,#080C14,#101820 60%,#182030)}

.road-wrap{position:absolute;top:18%;bottom:0;left:0;right:0;overflow:hidden}

/* Road with CSS perspective */
.road{position:absolute;left:35%;right:35%;top:0;bottom:0;
  background:linear-gradient(180deg,#222A36,#2C3544 50%,#363F50)}

/* Grass */
.grass-l{position:absolute;left:0;right:66%;top:0;bottom:0;background:#0D1A10}
.grass-r{position:absolute;left:66%;right:0;top:0;bottom:0;background:#0D1A10}

/* Shoulders */
.sh-l{position:absolute;left:33%;width:2%;top:0;bottom:0;background:#1A2630}
.sh-r{position:absolute;right:33%;width:2%;top:0;bottom:0;background:#1A2630}

/* Edge lines */
.edge{position:absolute;top:0;bottom:0;width:2px;background:rgba(255,255,255,0.3)}
.edge-l{left:35%}.edge-r{right:35%}

/* Lane dashes */
.lane{position:absolute;left:50%;width:2px;transform:translateX(-50%)}
.lane.a{margin-left:-7.5%}.lane.b{margin-left:0}.lane.c{margin-left:7.5%}
.dash{width:2px;height:18px;background:rgba(255,255,255,0.12);margin-bottom:24px;border-radius:1px}
@keyframes flow{from{transform:translateY(0)}to{transform:translateY(42px)}}
.ls{animation:flow 0.8s linear infinite}

/* Blue AP path */
.ap{position:absolute;left:48.5%;width:3%;top:0;bottom:0;
  background:linear-gradient(180deg,rgba(59,130,246,0.01),rgba(59,130,246,0.06));
  filter:blur(6px);pointer-events:none}

/* Car model */
model-viewer{
  position:absolute;bottom:-5%;left:50%;transform:translateX(-50%);
  width:75%;height:50%;--poster-color:transparent;z-index:5;
  pointer-events:none;
}

/* Detected objects */
.det{position:absolute;border:1.5px solid;border-radius:3px;z-index:4;
  display:flex;align-items:flex-end;justify-content:center;padding-bottom:2px;
  font-size:8px;font-weight:600}
</style>
</head>
<body>
<div class="scene" id="scene">
  <div class="sky"></div>
  <div class="road-wrap">
    <div class="grass-l"></div><div class="grass-r"></div>
    <div class="sh-l"></div><div class="sh-r"></div>
    <div class="road"></div>
    <div class="edge edge-l"></div><div class="edge edge-r"></div>
    <div class="lane a"><div class="ls" id="l1"></div></div>
    <div class="lane b"><div class="ls" id="l2"></div></div>
    <div class="lane c"><div class="ls" id="l3"></div></div>
    <div class="ap"></div>
    <div id="dets"></div>
  </div>
  <model-viewer id="mv"
    src="https://hwkim3330.github.io/tabsla/models/lowpoly_car.glb"
    alt="car"
    camera-orbit="180deg 55deg 2.2m"
    field-of-view="25deg"
    exposure="1.4"
    shadow-intensity="0.8"
    shadow-softness="1"
    environment-image="neutral"
    tone-mapping="commerce"
    interaction-prompt="none"
    style="background:transparent"
  ></model-viewer>
</div>

<script>
const sc = document.getElementById('scene');
const mv = document.getElementById('mv');
const detsEl = document.getElementById('dets');
const lanes = ['l1','l2','l3'].map(id=>document.getElementById(id));

// Fill dashes
lanes.forEach(l=>{for(let i=0;i<15;i++){const d=document.createElement('div');d.className='dash';l.appendChild(d)}});

// Touch rotate — entire scene
let touchX=0, touchY=0, rotY=0, rotX=0;
document.addEventListener('touchstart',e=>{
  const t=e.touches[0]; touchX=t.clientX; touchY=t.clientY;
},{passive:true});
document.addEventListener('touchmove',e=>{
  const t=e.touches[0];
  rotY += (t.clientX - touchX) * 0.15;
  rotX += (t.clientY - touchY) * 0.08;
  rotY = Math.max(-25, Math.min(25, rotY));
  rotX = Math.max(-10, Math.min(15, rotX));
  touchX = t.clientX; touchY = t.clientY;
  sc.style.transform = `perspective(800px) rotateY(${rotY}deg) rotateX(${rotX}deg)`;
},{passive:true});
document.addEventListener('touchend',()=>{
  // Slowly return to center
  const ret = setInterval(()=>{
    rotY *= 0.9; rotX *= 0.9;
    if(Math.abs(rotY)<0.3 && Math.abs(rotX)<0.3){rotY=0;rotX=0;clearInterval(ret)}
    sc.style.transform = `perspective(800px) rotateY(${rotY}deg) rotateX(${rotX}deg)`;
  },30);
});

let speed=0;
const CC={car:'59,130,246',truck:'251,191,36',bus:'251,191,36',pedestrian:'248,113,113',bike:'52,211,153'};

window.updateDrive = function(spd, str, objs) {
  speed = spd;
  // Lane speed
  const dur = spd > 5 ? Math.max(0.15, 2.5/spd) : 99;
  lanes.forEach(l=>l.style.animationDuration=dur+'s');

  // Steer — camera orbit + slight scene shift
  mv.cameraOrbit = (180 + str*-0.6)+'deg 55deg 2.2m';

  // Detected
  detsEl.innerHTML='';
  if(!objs) return;
  const arr = typeof objs==='string' ? JSON.parse(objs) : objs;
  const wrap = detsEl.parentElement;
  const W=wrap.offsetWidth, H=wrap.offsetHeight;
  arr.forEach(o=>{
    const col=CC[o.type]||'148,163,184';
    const x=W*(0.5+o.x*0.28);
    const y=H*o.y*0.75;
    const s=0.4+o.y*0.6;
    const w=(o.type==='truck'||o.type==='bus'?32:o.type==='pedestrian'?14:24)*s;
    const h=(o.type==='truck'||o.type==='bus'?48:o.type==='pedestrian'?32:28)*s;
    const d=Math.round((1-o.y)*80+5);
    const el=document.createElement('div');
    el.className='det';
    el.style.cssText=`left:${x-w/2}px;top:${y-h}px;width:${w}px;height:${h}px;border-color:rgba(${col},.45);background:rgba(${col},.06);color:rgba(${col},.5)`;
    el.textContent=d+'m';
    detsEl.appendChild(el);
  });
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

          // HUD
          Positioned(top: 12, left: 16, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: ['P','R','N','D'].map((g) {
                final on = widget.gear == g;
                return Container(width: 24, height: 24, margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(5)),
                  child: Center(child: Text(g, style: TextStyle(
                    color: on ? const Color(0xFF0C1018) : Colors.white.withValues(alpha: 0.12),
                    fontSize: 12, fontWeight: on ? FontWeight.w800 : FontWeight.w400, height: 1))));
              }).toList()),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(widget.speed.toInt().toString(), style: const TextStyle(
                  color: Colors.white, fontSize: 56, fontWeight: FontWeight.w200, height: 1, letterSpacing: -3,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)])),
                Padding(padding: const EdgeInsets.only(bottom: 6, left: 5),
                  child: Text('km/h', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13))),
              ]),
              if (widget.speed > 0) ...[const SizedBox(height: 8),
                Container(width: 30, height: 30,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                    border: Border.all(color: const Color(0xFFDC2626), width: 3)),
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
                  color: widget.batteryLevel > 30 ? const Color(0xFF34D399) : const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
              Text('${widget.range.toInt()} km', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10)),
            ],
          )),
        ],
      ),
    );
  }
}

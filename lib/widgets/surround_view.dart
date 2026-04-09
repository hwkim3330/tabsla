import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../data/vehicle_state.dart';

class SurroundView extends StatefulWidget {
  final double speed, steeringAngle, batteryLevel, range, animationValue;
  final String gear, carModel, navInstruction;
  final double navDistToTurn, navTotalRemaining;
  final List<DetectedObject> objects;

  const SurroundView({
    super.key,
    required this.speed, required this.gear, required this.steeringAngle,
    required this.objects, required this.animationValue,
    required this.batteryLevel, required this.range,
    required this.carModel, required this.navInstruction,
    required this.navDistToTurn, required this.navTotalRemaining,
  });

  @override
  State<SurroundView> createState() => _SurroundViewState();
}

class _SurroundViewState extends State<SurroundView> {
  late WebViewController _wv;
  bool _loaded = false;
  String _currentModel = '';

  static String _html(String modelUrl) => '''
<!DOCTYPE html><html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=no">
<style>*{margin:0;padding:0}body{background:#141C28;overflow:hidden;touch-action:none}</style>
</head><body>
<script type="importmap">
{"imports":{
  "three":"https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.js",
  "three/addons/":"https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/"
}}
</script>
<script type="module">
import * as THREE from 'three';
import {OrbitControls} from 'three/addons/controls/OrbitControls.js';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x141C28);
scene.fog = new THREE.FogExp2(0x141C28, 0.008);

const camera = new THREE.PerspectiveCamera(50, innerWidth/innerHeight, 0.1, 500);
camera.position.set(0, 5, 9);

const R = new THREE.WebGLRenderer({antialias:true});
R.setSize(innerWidth, innerHeight);
R.setPixelRatio(Math.min(devicePixelRatio, 2));
R.toneMapping = THREE.ACESFilmicToneMapping;
R.toneMappingExposure = 2.0;
document.body.appendChild(R.domElement);

const ctrl = new OrbitControls(camera, R.domElement);
ctrl.enableDamping = true; ctrl.dampingFactor = 0.05;
ctrl.target.set(0, 0.3, -2);
ctrl.maxPolarAngle = Math.PI*0.42; ctrl.minPolarAngle = Math.PI*0.08;
ctrl.minDistance = 4; ctrl.maxDistance = 16; ctrl.enablePan = false;

// Bright lighting
scene.add(new THREE.AmbientLight(0x8899bb, 1.5));
const sun = new THREE.DirectionalLight(0xaabbdd, 1.2);
sun.position.set(-3, 12, 8); scene.add(sun);
scene.add(new THREE.DirectionalLight(0x556688, 0.6).translateX(5).translateY(6).translateZ(-5));
scene.add(new THREE.HemisphereLight(0x8899cc, 0x1a2030, 0.5));

// Headlights
for(const x of [-0.5, 0.5]){
  const hl = new THREE.SpotLight(0xffeedd, 2.5, 40, Math.PI*0.14, 0.5);
  hl.position.set(x, 0.5, -1.5);
  const t = new THREE.Object3D(); t.position.set(x*2, 0, -20);
  scene.add(t); hl.target = t; scene.add(hl);
}

// Ground
scene.add(Object.assign(new THREE.Mesh(new THREE.PlaneGeometry(200,200),
  new THREE.MeshStandardMaterial({color:0x162018, roughness:0.9})),
  {rotation:{x:-Math.PI/2}, position:{y:-0.01}}));

// Road
const RW=8, RL=200;
const rd = new THREE.Mesh(new THREE.PlaneGeometry(RW, RL),
  new THREE.MeshStandardMaterial({color:0x3a4250, roughness:0.75}));
rd.rotation.x=-Math.PI/2; rd.position.set(0, 0.005, -RL/2+10); scene.add(rd);

// Edges
for(const x of [-RW/2, RW/2]){
  const e = new THREE.Mesh(new THREE.PlaneGeometry(0.15, RL),
    new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.4}));
  e.rotation.x=-Math.PI/2; e.position.set(x, 0.01, -RL/2+10); scene.add(e);
}

// Dashes
const dG = new THREE.Group();
for(let l=-1;l<=1;l++) for(let i=0;i<40;i++){
  const d = new THREE.Mesh(new THREE.PlaneGeometry(0.1, 2),
    new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.25}));
  d.rotation.x=-Math.PI/2; d.position.set(l*RW/4, 0.01, -i*5); dG.add(d);
}
scene.add(dG);

// Blue AP path
const bp = new THREE.Mesh(new THREE.PlaneGeometry(1.8, RL),
  new THREE.MeshBasicMaterial({color:0x3B82F6, transparent:true, opacity:0.07}));
bp.rotation.x=-Math.PI/2; bp.position.set(0, 0.007, -RL/2+10); scene.add(bp);

// Ego car
let ego = null;
const loader = new GLTFLoader();
loader.load('$modelUrl', g=>{
  ego = g.scene; ego.scale.set(1.2, 1.2, 1.2);
  ego.position.set(0, 0.05, 0); ego.rotation.y = Math.PI;
  ego.traverse(c=>{if(c.isMesh){c.material=c.material.clone(); c.material.envMapIntensity=1.5}});
  scene.add(ego);
});

// Detected — clone from template
let carTpl = null;
loader.load('https://hwkim3330.github.io/tabsla/models/lowpoly_car.glb', g=>{
  carTpl = g.scene; carTpl.scale.set(1.0, 1.0, 1.0); carTpl.rotation.y = Math.PI;
});

const dets = [];
function mkDet(type, x, z){
  let m;
  if(carTpl && (type==='car'||type==='truck')){
    m = carTpl.clone();
    const s = type==='truck' ? 1.3 : 1.0;
    m.scale.set(s, type==='truck'?1.2:1, s);
    const colors = {car:0x6688AA, truck:0x889AAA};
    m.traverse(c=>{if(c.isMesh){
      c.material = c.material.clone();
      c.material.color.set(colors[type]||0x888888);
      c.material.opacity = 0.8; c.material.transparent = true;
    }});
  } else {
    const col = type==='pedestrian'?0xCC9977:0x77AA88;
    const mat = new THREE.MeshStandardMaterial({color:col, transparent:true, opacity:0.7});
    m = new THREE.Group();
    if(type==='pedestrian'){
      m.add(Object.assign(new THREE.Mesh(new THREE.CylinderGeometry(0.12,0.12,0.7),mat),{position:new THREE.Vector3(0,0.9,0)}));
      m.add(Object.assign(new THREE.Mesh(new THREE.SphereGeometry(0.13),mat),{position:new THREE.Vector3(0,1.4,0)}));
    } else {
      m.add(Object.assign(new THREE.Mesh(new THREE.BoxGeometry(0.4,1,1.3),mat),{position:new THREE.Vector3(0,0.5,0)}));
    }
  }
  m.position.set(x, 0, z); scene.add(m); return m;
}

let speed=0, dOff=0;
window.updateDrive = function(spd, str, objs){
  speed = spd;
  if(ego) ego.rotation.y = Math.PI + THREE.MathUtils.degToRad(str * -0.5);
  dets.forEach(d=>scene.remove(d)); dets.length=0;
  if(objs) try{
    (typeof objs==='string'?JSON.parse(objs):objs).forEach(o=>{
      dets.push(mkDet(o.type, o.x*4, -(1-o.y)*60-5));
    });
  }catch(e){}
};

window.changeModel = function(url){
  if(ego){scene.remove(ego); ego=null}
  loader.load(url, g=>{
    ego = g.scene; ego.scale.set(1.2, 1.2, 1.2);
    ego.position.set(0, 0.05, 0); ego.rotation.y = Math.PI;
    ego.traverse(c=>{if(c.isMesh){c.material=c.material.clone();c.material.envMapIntensity=1.5}});
    scene.add(ego);
  });
};

const clk = new THREE.Clock();
(function anim(){
  requestAnimationFrame(anim);
  const dt = clk.getDelta();
  dOff += speed*dt*0.15;
  dG.children.forEach((d,i)=>{
    d.position.z=((-(Math.floor(i/3))*5+dOff)%200)-100;
    d.position.x=((i%3)-1)*RW/4;
  });
  ctrl.update(); R.render(scene, camera);
})();

addEventListener('resize',()=>{camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();R.setSize(innerWidth,innerHeight)});
</script>
</body></html>
''';

  static const _models = {
    'lowpoly': 'https://hwkim3330.github.io/tabsla/models/lowpoly_car.glb',
    'ferrari': 'https://hwkim3330.github.io/tabsla/models/ferrari.glb',
    'lambo': 'https://hwkim3330.github.io/tabsla/models/lambo.glb',
  };

  void _initWv(String model) {
    _currentModel = model;
    _loaded = false;
    _wv = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF141C28))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) { if (mounted) setState(() => _loaded = true); },
      ))
      ..loadHtmlString(_html(_models[model] ?? _models['lowpoly']!));
  }

  @override
  void initState() {
    super.initState();
    _initWv(widget.carModel);
  }

  @override
  void didUpdateWidget(SurroundView old) {
    super.didUpdateWidget(old);
    // Model changed
    if (widget.carModel != _currentModel && _loaded) {
      final url = _models[widget.carModel];
      if (url != null) {
        _wv.runJavaScript("changeModel('$url')");
        _currentModel = widget.carModel;
      }
    }
    // Update drive data
    if (_loaded) {
      final objs = widget.objects.map((o) => {'x': o.x, 'y': o.y, 'type': o.type}).toList();
      _wv.runJavaScript("updateDrive(${widget.speed.toStringAsFixed(1)},${widget.steeringAngle.toStringAsFixed(1)},${jsonEncode(objs)})");
    }
  }

  IconData _navIcon(String inst) {
    switch (inst) {
      case 'turn_left': return Icons.turn_left_rounded;
      case 'turn_right': return Icons.turn_right_rounded;
      case 'slight_left': return Icons.turn_slight_left_rounded;
      case 'slight_right': return Icons.turn_slight_right_rounded;
      case 'arrive': return Icons.flag_rounded;
      default: return Icons.arrow_upward_rounded;
    }
  }

  String _distStr(double m) => m > 1000 ? '${(m/1000).toStringAsFixed(1)}km' : '${m.toInt()}m';

  @override
  Widget build(BuildContext context) {
    final hasNav = widget.navInstruction.isNotEmpty && widget.navInstruction != 'straight';
    final eta = widget.speed > 3 ? (widget.navTotalRemaining / (widget.speed / 3.6)).round() : 0;
    final etaMin = (eta / 60).round();

    return Container(
      color: const Color(0xFF141C28),
      child: Stack(
        children: [
          WebViewWidget(controller: _wv),
          if (!_loaded) const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6))),

          // === Nav turn instruction (top center) ===
          if (hasNav || widget.navTotalRemaining > 10)
            Positioned(top: 10, left: 0, right: 0, child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(8)),
                    child: Icon(_navIcon(widget.navInstruction), color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(_distStr(widget.navDistToTurn),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1)),
                    if (widget.navTotalRemaining > 100)
                      Text('${_distStr(widget.navTotalRemaining)} · ${etaMin > 0 ? "${etaMin}min" : "<1min"}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                  ]),
                ]),
              ),
            )),

          // === Gear + Speed (top left, Tesla style) ===
          Positioned(top: hasNav ? 60 : 12, left: 16, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: ['P','R','N','D'].map((g) {
                final on = widget.gear == g;
                return Container(width: 24, height: 24, margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(5)),
                  child: Center(child: Text(g, style: TextStyle(
                    color: on ? const Color(0xFF141C28) : Colors.white.withValues(alpha: 0.12),
                    fontSize: 12, fontWeight: on ? FontWeight.w800 : FontWeight.w400, height: 1))));
              }).toList()),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(widget.speed.toInt().toString(), style: const TextStyle(
                  color: Colors.white, fontSize: 52, fontWeight: FontWeight.w200, height: 1, letterSpacing: -3,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)])),
                Padding(padding: const EdgeInsets.only(bottom: 5, left: 5),
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

          // === Battery (top right) ===
          Positioned(top: hasNav ? 60 : 12, right: 14, child: Column(
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

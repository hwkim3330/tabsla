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

  // Three.js via ES modules (type="module") — works with loadHtmlString on Android
  static const _html = r'''
<!DOCTYPE html><html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=no">
<style>*{margin:0;padding:0}body{background:#0C1018;overflow:hidden;touch-action:none}</style>
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
scene.background = new THREE.Color(0x0C1018);
scene.fog = new THREE.FogExp2(0x0C1018, 0.012);

const camera = new THREE.PerspectiveCamera(50, innerWidth/innerHeight, 0.1, 500);
camera.position.set(0, 5, 9);
camera.lookAt(0, 0, -5);

const R = new THREE.WebGLRenderer({antialias:true});
R.setSize(innerWidth, innerHeight);
R.setPixelRatio(Math.min(devicePixelRatio, 2));
R.shadowMap.enabled = true;
R.shadowMap.type = THREE.PCFSoftShadowMap;
R.toneMapping = THREE.ACESFilmicToneMapping;
R.toneMappingExposure = 1.3;
document.body.appendChild(R.domElement);

const ctrl = new OrbitControls(camera, R.domElement);
ctrl.enableDamping = true; ctrl.dampingFactor = 0.05;
ctrl.target.set(0, 0.3, -2);
ctrl.maxPolarAngle = Math.PI*0.42; ctrl.minPolarAngle = Math.PI*0.08;
ctrl.minDistance = 4; ctrl.maxDistance = 16; ctrl.enablePan = false;

// Lighting
scene.add(new THREE.AmbientLight(0x334466, 0.7));
const sun = new THREE.DirectionalLight(0x6688bb, 0.7);
sun.position.set(-5, 15, 10); sun.castShadow = true;
sun.shadow.mapSize.set(1024,1024);
sun.shadow.camera.left=-25; sun.shadow.camera.right=25;
sun.shadow.camera.top=25; sun.shadow.camera.bottom=-25;
scene.add(sun);
scene.add(new THREE.DirectionalLight(0x223344, 0.3).translateX(5).translateY(8).translateZ(-5));

// Headlights
for(const x of [-0.5, 0.5]){
  const hl = new THREE.SpotLight(0xffeedd, 2, 35, Math.PI*0.14, 0.5);
  hl.position.set(x, 0.5, -1.5);
  const tgt = new THREE.Object3D(); tgt.position.set(x*2, 0, -20);
  scene.add(tgt); hl.target = tgt; scene.add(hl);
}

// Ground
const gnd = new THREE.Mesh(new THREE.PlaneGeometry(200,200),
  new THREE.MeshStandardMaterial({color:0x0a130a, roughness:0.95}));
gnd.rotation.x=-Math.PI/2; gnd.position.y=-0.01; gnd.receiveShadow=true; scene.add(gnd);

// Road
const RW=8, RL=200;
const rd = new THREE.Mesh(new THREE.PlaneGeometry(RW, RL),
  new THREE.MeshStandardMaterial({color:0x282e38, roughness:0.85}));
rd.rotation.x=-Math.PI/2; rd.position.set(0, 0.005, -RL/2+10); rd.receiveShadow=true; scene.add(rd);

// Edges
for(const x of [-RW/2, RW/2]){
  const e = new THREE.Mesh(new THREE.PlaneGeometry(0.12, RL),
    new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.35}));
  e.rotation.x=-Math.PI/2; e.position.set(x, 0.01, -RL/2+10); scene.add(e);
}

// Dashes
const dG = new THREE.Group();
for(let l=-1;l<=1;l++) for(let i=0;i<40;i++){
  const d = new THREE.Mesh(new THREE.PlaneGeometry(0.1, 2),
    new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.2}));
  d.rotation.x=-Math.PI/2; d.position.set(l*RW/4, 0.01, -i*5); dG.add(d);
}
scene.add(dG);

// Blue path
const bp = new THREE.Mesh(new THREE.PlaneGeometry(1.5, RL),
  new THREE.MeshBasicMaterial({color:0x3B82F6, transparent:true, opacity:0.06}));
bp.rotation.x=-Math.PI/2; bp.position.set(0, 0.007, -RL/2+10); scene.add(bp);

// Buildings
const bMat = new THREE.MeshStandardMaterial({color:0x141c28, roughness:0.9});
const wMat = new THREE.MeshBasicMaterial({color:0x2a4060, transparent:true, opacity:0.25});
let seed=42; const rn=()=>{seed=(seed*1103515245+12345)&0x7fffffff;return seed/0x7fffffff};
for(let sd=-1;sd<=1;sd+=2) for(let i=0;i<25;i++){
  const h=3+rn()*12, w=2+rn()*4, d=2+rn()*3;
  const b=new THREE.Mesh(new THREE.BoxGeometry(w,h,d), bMat);
  const x=sd*(RW/2+3+rn()*8), z=-i*8+rn()*3;
  b.position.set(x, h/2, z); b.castShadow=true; scene.add(b);
  // Windows
  if(h>5) for(let wy=1.5;wy<h-1;wy+=1.8) for(let wx=-w/3;wx<=w/3;wx+=1.2)
    if(rn()>0.4){
      const wn=new THREE.Mesh(new THREE.PlaneGeometry(0.5,0.6), wMat);
      wn.position.set(x+(sd>0?-w/2-0.01:w/2+0.01), wy, z+wx);
      wn.rotation.y=sd>0?Math.PI/2:-Math.PI/2; scene.add(wn);
    }
  // Trees
  if(rn()>0.5){
    const th=1.5+rn()*2;
    scene.add(new THREE.Mesh(new THREE.CylinderGeometry(0.08,0.12,th),
      new THREE.MeshStandardMaterial({color:0x3a2a1a})).translateX(sd*(RW/2+1.5)).translateY(th/2).translateZ(z+2));
    scene.add(new THREE.Mesh(new THREE.SphereGeometry(0.7+rn()*0.5,6,6),
      new THREE.MeshStandardMaterial({color:0x1a3a1a})).translateX(sd*(RW/2+1.5)).translateY(th+0.3).translateZ(z+2));
  }
}

// Ego car
let ego = null;
new GLTFLoader().load('https://hwkim3330.github.io/tabsla/models/lowpoly_car.glb', g=>{
  ego = g.scene; ego.scale.set(1.2, 1.2, 1.2);
  ego.position.set(0, 0.05, 0); ego.rotation.y = Math.PI;
  ego.traverse(c=>{if(c.isMesh){c.castShadow=true; c.receiveShadow=true}});
  scene.add(ego);
});

// Detected vehicles — reuse meshes
const detPool = [];
const detColors = {car:0x3B82F6, truck:0xFBBF24, bus:0xFBBF24, pedestrian:0xF87171, bike:0x34D399};

function getDet(type, x, z){
  const col = detColors[type]||0x888888;
  const mat = new THREE.MeshStandardMaterial({color:col, transparent:true, opacity:0.5, roughness:0.4});
  let m;
  if(type==='car'){
    m = new THREE.Group();
    m.add(new THREE.Mesh(new THREE.BoxGeometry(1.5, 0.55, 3.2), mat).translateY(0.47));
    m.add(new THREE.Mesh(new THREE.BoxGeometry(1.2, 0.35, 1.6), mat).translateY(0.9).translateZ(-0.2));
    // Tail lights
    const tl = new THREE.MeshBasicMaterial({color:0xff3333});
    m.add(new THREE.Mesh(new THREE.BoxGeometry(0.18, 0.08, 0.04), tl).translateX(-0.55).translateY(0.48).translateZ(1.61));
    m.add(new THREE.Mesh(new THREE.BoxGeometry(0.18, 0.08, 0.04), tl).translateX(0.55).translateY(0.48).translateZ(1.61));
  } else if(type==='truck'||type==='bus'){
    m = new THREE.Group();
    m.add(new THREE.Mesh(new THREE.BoxGeometry(1.8, 2.2, 4.5), mat).translateY(1.3));
  } else if(type==='pedestrian'){
    m = new THREE.Group();
    m.add(new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.12, 0.7), mat).translateY(0.9));
    m.add(new THREE.Mesh(new THREE.SphereGeometry(0.13), mat).translateY(1.4));
  } else {
    m = new THREE.Mesh(new THREE.BoxGeometry(0.4, 1, 1.3), mat);
    m.position.y = 0.5;
  }
  m.position.set(x, 0, z);
  scene.add(m);
  return m;
}

let speed=0, dOff=0;
const dets = [];

window.updateDrive = function(spd, str, objs){
  speed = spd;
  if(ego) ego.rotation.y = Math.PI + THREE.MathUtils.degToRad(str * -0.5);

  // Remove old detected
  dets.forEach(d => {d.traverse(c=>{if(c.geometry)c.geometry.dispose()}); scene.remove(d)});
  dets.length = 0;

  if(objs) try{
    const arr = typeof objs==='string' ? JSON.parse(objs) : objs;
    arr.forEach(o=>{
      const lx = o.x * 4;
      const dz = -(1-o.y)*60 - 5;
      dets.push(getDet(o.type, lx, dz));
    });
  }catch(e){}
};

// Animate
const clk = new THREE.Clock();
(function anim(){
  requestAnimationFrame(anim);
  const dt = clk.getDelta();
  dOff += speed * dt * 0.15;
  dG.children.forEach((d,i)=>{
    d.position.z = ((-(Math.floor(i/3))*5 + dOff) % 200) - 100;
    d.position.x = ((i%3)-1) * RW/4;
  });
  ctrl.update();
  R.render(scene, camera);
})();

addEventListener('resize',()=>{
  camera.aspect = innerWidth/innerHeight;
  camera.updateProjectionMatrix();
  R.setSize(innerWidth, innerHeight);
});
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

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

  static const _modelBase = 'https://hwkim3330.github.io/tabsla/models';

  // Embed HTML directly — no GitHub Pages dependency for the page itself
  static const _driveHtml = r'''
<!DOCTYPE html><html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=no">
<style>*{margin:0;padding:0}body{background:#0C1018;overflow:hidden;touch-action:none}canvas{display:block}</style>
</head><body>
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r152/three.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.152.0/examples/js/controls/OrbitControls.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.152.0/examples/js/loaders/GLTFLoader.js"></script>
<script>
const MODEL_BASE = "%%MODEL_BASE%%";

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0C1018);
scene.fog = new THREE.FogExp2(0x0C1018, 0.012);

const camera = new THREE.PerspectiveCamera(50, innerWidth/innerHeight, 0.1, 500);
camera.position.set(0, 4.5, 8);
camera.lookAt(0, 0.5, -5);

const R = new THREE.WebGLRenderer({antialias:true});
R.setSize(innerWidth, innerHeight);
R.setPixelRatio(Math.min(devicePixelRatio, 2));
R.shadowMap.enabled = true;
R.shadowMap.type = THREE.PCFSoftShadowMap;
R.toneMapping = THREE.ACESFilmicToneMapping;
R.toneMappingExposure = 1.2;
document.body.appendChild(R.domElement);

const ctrl = new THREE.OrbitControls(camera, R.domElement);
ctrl.enableDamping = true; ctrl.dampingFactor = 0.05;
ctrl.target.set(0, 0.5, -2);
ctrl.maxPolarAngle = Math.PI*0.45; ctrl.minPolarAngle = Math.PI*0.1;
ctrl.minDistance = 4; ctrl.maxDistance = 15; ctrl.enablePan = false;

// Lighting
scene.add(new THREE.AmbientLight(0x334466, 0.8));
const ml = new THREE.DirectionalLight(0x6688bb, 0.6);
ml.position.set(-5, 15, 10); ml.castShadow = true;
ml.shadow.mapSize.set(1024,1024);
ml.shadow.camera.left=-20;ml.shadow.camera.right=20;ml.shadow.camera.top=20;ml.shadow.camera.bottom=-20;
scene.add(ml);
scene.add(Object.assign(new THREE.DirectionalLight(0x223344,0.3),{position:new THREE.Vector3(5,8,-5)}));

const hlL = new THREE.SpotLight(0xffeedd,2,30,Math.PI*0.15,0.5);
hlL.position.set(-0.5,0.5,-1.5); hlL.target.position.set(-1,0,-15);
scene.add(hlL); scene.add(hlL.target);
const hlR = new THREE.SpotLight(0xffeedd,2,30,Math.PI*0.15,0.5);
hlR.position.set(0.5,0.5,-1.5); hlR.target.position.set(1,0,-15);
scene.add(hlR); scene.add(hlR.target);

// Ground
const gnd = new THREE.Mesh(new THREE.PlaneGeometry(200,200),new THREE.MeshStandardMaterial({color:0x0a120a,roughness:0.95}));
gnd.rotation.x=-Math.PI/2; gnd.position.y=-0.01; gnd.receiveShadow=true; scene.add(gnd);

// Road
const RW=8, RL=200;
const rd = new THREE.Mesh(new THREE.PlaneGeometry(RW,RL),new THREE.MeshStandardMaterial({color:0x2a2e36,roughness:0.85}));
rd.rotation.x=-Math.PI/2; rd.position.set(0,0.005,-RL/2+10); rd.receiveShadow=true; scene.add(rd);

// Edge lines
[-RW/2,RW/2].forEach(x=>{
  const m=new THREE.Mesh(new THREE.PlaneGeometry(0.12,RL),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:0.4}));
  m.rotation.x=-Math.PI/2; m.position.set(x,0.01,-RL/2+10); scene.add(m);
});

// Dashes
const dG = new THREE.Group();
for(let l=-1;l<=1;l++) for(let i=0;i<40;i++){
  const d=new THREE.Mesh(new THREE.PlaneGeometry(0.1,2),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:0.25}));
  d.rotation.x=-Math.PI/2; d.position.set(l*RW/4,0.01,-i*5); dG.add(d);
}
scene.add(dG);

// Blue path
const bp=new THREE.Mesh(new THREE.PlaneGeometry(1.5,RL),new THREE.MeshBasicMaterial({color:0x3B82F6,transparent:true,opacity:0.08}));
bp.rotation.x=-Math.PI/2; bp.position.set(0,0.008,-RL/2+10); scene.add(bp);

// Buildings
const bm=new THREE.MeshStandardMaterial({color:0x151d28,roughness:0.9});
const wm=new THREE.MeshBasicMaterial({color:0x334466,transparent:true,opacity:0.3});
const S=(function(){let s=42;return{n:function(){s=(s*1103515245+12345)&0x7fffffff;return s/0x7fffffff}}})();
for(let sd=-1;sd<=1;sd+=2) for(let i=0;i<25;i++){
  const h=3+S.n()*12, w=2+S.n()*4, d=2+S.n()*3;
  const b=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),bm);
  const x=sd*(RW/2+3+S.n()*8), z=-i*8+S.n()*3;
  b.position.set(x,h/2,z); b.castShadow=true; scene.add(b);
  if(h>5) for(let wy=1.5;wy<h-1;wy+=1.8) for(let wx=-w/3;wx<=w/3;wx+=1.2)
    if(S.n()>0.4){
      const wn=new THREE.Mesh(new THREE.PlaneGeometry(0.5,0.6),wm);
      wn.position.set(x+(sd>0?-w/2-0.01:w/2+0.01),wy,z+wx);
      wn.rotation.y=sd>0?Math.PI/2:-Math.PI/2; scene.add(wn);
    }
  if(S.n()>0.5){
    const th=1.5+S.n()*2;
    const tk=new THREE.Mesh(new THREE.CylinderGeometry(0.08,0.12,th),new THREE.MeshStandardMaterial({color:0x3a2a1a}));
    tk.position.set(sd*(RW/2+1.5),th/2,z+2); scene.add(tk);
    const cr=new THREE.Mesh(new THREE.SphereGeometry(0.8+S.n()*0.5,6,6),new THREE.MeshStandardMaterial({color:0x1a3a1a}));
    cr.position.set(sd*(RW/2+1.5),th+0.3,z+2); scene.add(cr);
  }
}

// Ego car
let ego=null;
new THREE.GLTFLoader().load(MODEL_BASE+"/lowpoly_car.glb",g=>{
  ego=g.scene; ego.scale.set(1.5,1.5,1.5);
  ego.position.set(0,0.05,0); ego.rotation.y=Math.PI;
  ego.traverse(c=>{if(c.isMesh){c.castShadow=true;c.receiveShadow=true}});
  scene.add(ego);
});

// Detected
const dets=[];
const CC={car:0x3B82F6,truck:0xFBBF24,pedestrian:0xF87171,bike:0x34D399};
function mkDet(type,x,z){
  const c=CC[type]||0x888888;
  const mt=new THREE.MeshStandardMaterial({color:c,transparent:true,opacity:0.6,roughness:0.5});
  let m;
  if(type==='car'){
    m=new THREE.Group();
    const bd=new THREE.Mesh(new THREE.BoxGeometry(1.6,0.6,3.5),mt); bd.position.y=0.5; m.add(bd);
    const rf=new THREE.Mesh(new THREE.BoxGeometry(1.3,0.4,1.8),mt); rf.position.set(0,0.95,-0.2); m.add(rf);
    const tl=new THREE.MeshBasicMaterial({color:0xff3333});
    const t1=new THREE.Mesh(new THREE.BoxGeometry(0.2,0.1,0.05),tl); t1.position.set(-0.6,0.5,1.76); m.add(t1);
    const t2=t1.clone(); t2.position.x=0.6; m.add(t2);
  } else if(type==='truck'){
    m=new THREE.Group();
    const bd=new THREE.Mesh(new THREE.BoxGeometry(2,2.5,5),mt); bd.position.y=1.5; m.add(bd);
  } else if(type==='pedestrian'){
    m=new THREE.Group();
    m.add(Object.assign(new THREE.Mesh(new THREE.CylinderGeometry(0.15,0.15,0.8),mt),{position:new THREE.Vector3(0,1,0)}));
    m.add(Object.assign(new THREE.Mesh(new THREE.SphereGeometry(0.15),mt),{position:new THREE.Vector3(0,1.55,0)}));
  } else {
    m=new THREE.Mesh(new THREE.BoxGeometry(0.5,1.2,1.5),mt); m.position.y=0.6;
  }
  m.position.set(x,0,z); scene.add(m); return m;
}

let speed=0, steer=0, dOff=0;
window.updateDrive=function(sp,st,objs){
  speed=sp; steer=st;
  dets.forEach(c=>{if(c.parent)c.parent.remove(c)});
  dets.length=0;
  if(objs) try{
    (typeof objs==='string'?JSON.parse(objs):objs).forEach(o=>{
      dets.push(mkDet(o.type, o.x*4, -(1-o.y)*60-5));
    });
  }catch(e){}
};

const clk=new THREE.Clock();
function anim(){
  requestAnimationFrame(anim);
  const dt=clk.getDelta();
  dOff+=speed*dt*0.15;
  dG.children.forEach((d,i)=>{
    d.position.z=((-(Math.floor(i/3))*5+dOff)%200)-100;
    d.position.x=((i%3)-1)*RW/4;
  });
  if(ego) ego.rotation.y=Math.PI+THREE.MathUtils.degToRad(steer*-0.5);
  ctrl.target.lerp(new THREE.Vector3(steer*0.02,0.5,-2),0.05);
  ctrl.update(); R.render(scene,camera);
}
anim();
addEventListener('resize',()=>{camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();R.setSize(innerWidth,innerHeight)});
</script>
</body></html>
''';

  @override
  void initState() {
    super.initState();
    // Embed HTML with model URL injected
    final html = _driveHtml.replaceAll('%%MODEL_BASE%%', _modelBase);
    _wv = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0C1018))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loaded = true),
      ))
      ..loadHtmlString(html);
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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/vehicle_state.dart';

class CameraSurroundView extends StatefulWidget {
  final double speed;
  final String gear;
  final double steeringAngle;
  final List<DetectedObject> objects;
  final double batteryLevel;
  final double range;
  final double power;

  const CameraSurroundView({
    super.key,
    required this.speed,
    required this.gear,
    required this.steeringAngle,
    required this.objects,
    required this.batteryLevel,
    required this.range,
    required this.power,
  });

  @override
  State<CameraSurroundView> createState() => _CameraSurroundViewState();
}

class _CameraSurroundViewState extends State<CameraSurroundView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _cameraReady = false;
  String _status = 'Requesting camera...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestAndInit();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
      setState(() => _cameraReady = false);
    } else if (state == AppLifecycleState.resumed) {
      _requestAndInit();
    }
  }

  Future<void> _requestAndInit() async {
    // Request camera permission explicitly
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _status = 'Camera permission denied. Tap to retry.');
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _status = 'No cameras available');
        return;
      }

      final backCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _cameraReady = true;
          _status = 'Camera active';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Camera error: ${e.toString().substring(0, min(50, e.toString().length))}');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera or fallback
          if (_cameraReady && _controller != null && _controller!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            )
          else
            GestureDetector(
              onTap: _requestAndInit,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam, color: Colors.white24, size: 48),
                    const SizedBox(height: 8),
                    Text(_status, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text('Tap to retry', style: TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),
              ),
            ),

          // Vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.3,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.25)],
              ),
            ),
          ),

          // Top/bottom gradients
          Positioned(
            top: 0, left: 0, right: 0, height: 70,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0, height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                ),
              ),
            ),
          ),

          // Detection bounding boxes
          CustomPaint(
            size: Size.infinite,
            painter: _DetectionPainter(objects: widget.objects),
          ),

          // ---- HUD ----

          // Top center - status
          Positioned(
            top: 10, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _cameraReady ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        boxShadow: _cameraReady
                            ? [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.6), blurRadius: 6)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _cameraReady ? 'LIVE' : 'OFFLINE',
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.sensors, color: Colors.white.withValues(alpha: 0.3), size: 13),
                    const SizedBox(width: 3),
                    Text('${widget.objects.length}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),

          // Speed - bottom center
          Positioned(
            bottom: 45, left: 0, right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.speed.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.white, fontSize: 76, fontWeight: FontWeight.w200,
                      height: 1, letterSpacing: -4,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                  const Text('km/h', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          ),

          // Gear - bottom left
          Positioned(
            bottom: 10, left: 12,
            child: _GearBadge(gear: widget.gear),
          ),

          // Speed limit - bottom right
          Positioned(
            bottom: 10, right: 12,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.white,
                border: Border.all(color: const Color(0xFFEF4444), width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
              ),
              child: const Center(child: Text('60', style: TextStyle(color: Color(0xFF111827), fontSize: 14, fontWeight: FontWeight.w800))),
            ),
          ),

          // Battery - top left
          Positioned(
            top: 10, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.battery_std, color: widget.batteryLevel > 30 ? const Color(0xFF22C55E) : const Color(0xFFEF4444), size: 14),
                  const SizedBox(width: 4),
                  Text('${widget.batteryLevel.toInt()}%', style: TextStyle(color: widget.batteryLevel > 30 ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text('${widget.range.toInt()} km', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          ),

          // Power - top right
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: widget.power < 0 ? const Color(0xFF22C55E) : const Color(0xFF3B82F6), size: 14),
                  const SizedBox(width: 4),
                  Text('${widget.power.toInt()} kW', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GearBadge extends StatelessWidget {
  final String gear;
  const _GearBadge({required this.gear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['P', 'R', 'N', 'D'].map((g) {
          final isActive = gear == g;
          return Container(
            width: 26, height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(g, style: TextStyle(
                color: isActive ? Colors.black : Colors.white30,
                fontSize: 12, fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              )),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<DetectedObject> objects;
  _DetectionPainter({required this.objects});

  @override
  void paint(Canvas canvas, Size size) {
    for (final obj in objects) {
      final x = size.width * (0.5 + obj.x);
      final y = size.height * (0.2 + obj.y * 0.55);
      final scale = 0.3 + obj.y * 0.7;

      Color color;
      double w, h;
      String label;

      switch (obj.type) {
        case 'car': color = const Color(0xFF3B82F6); w = 60 * scale; h = 45 * scale; label = 'Car'; break;
        case 'truck': case 'bus': color = const Color(0xFFF59E0B); w = 70 * scale; h = 55 * scale; label = obj.type == 'bus' ? 'Bus' : 'Truck'; break;
        case 'pedestrian': color = const Color(0xFFEF4444); w = 30 * scale; h = 60 * scale; label = 'Person'; break;
        case 'bike': color = const Color(0xFF22C55E); w = 35 * scale; h = 50 * scale; label = 'Bike'; break;
        default: continue;
      }

      final rect = Rect.fromCenter(center: Offset(x, y), width: w, height: h);

      // Box
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = color.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );

      // Corners
      final cl = 8.0 * scale;
      final cp = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;
      canvas.drawLine(rect.topLeft, Offset(rect.left + cl, rect.top), cp);
      canvas.drawLine(rect.topLeft, Offset(rect.left, rect.top + cl), cp);
      canvas.drawLine(rect.topRight, Offset(rect.right - cl, rect.top), cp);
      canvas.drawLine(rect.topRight, Offset(rect.right, rect.top + cl), cp);
      canvas.drawLine(rect.bottomLeft, Offset(rect.left + cl, rect.bottom), cp);
      canvas.drawLine(rect.bottomLeft, Offset(rect.left, rect.bottom - cl), cp);
      canvas.drawLine(rect.bottomRight, Offset(rect.right - cl, rect.bottom), cp);
      canvas.drawLine(rect.bottomRight, Offset(rect.right, rect.bottom - cl), cp);

      // Label
      final dist = ((1 - obj.y) * 80 + 5).toInt();
      final tp = TextPainter(
        text: TextSpan(text: '$label ${dist}m', style: TextStyle(color: Colors.white, fontSize: 7 + scale * 3, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      final lr = Rect.fromLTWH(rect.left, rect.top - tp.height - 4, tp.width + 8, tp.height + 2);
      canvas.drawRRect(RRect.fromRectAndRadius(lr, const Radius.circular(2)), Paint()..color = color.withValues(alpha: 0.8));
      tp.paint(canvas, Offset(lr.left + 4, lr.top + 1));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) => true;
}

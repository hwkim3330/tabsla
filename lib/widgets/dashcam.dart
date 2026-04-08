import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class Dashcam extends StatefulWidget {
  final VoidCallback onClose;
  const Dashcam({super.key, required this.onClose});

  @override
  State<Dashcam> createState() => _DashcamState();
}

class _DashcamState extends State<Dashcam> {
  CameraController? _cam;
  bool _ready = false;
  bool _recording = false;
  String _status = 'Initializing...';
  int _seconds = 0;

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    await Permission.camera.request();
    final cams = await availableCameras();
    if (cams.isEmpty) { setState(() => _status = 'No camera'); return; }
    _cam = CameraController(
      cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cams.first),
      ResolutionPreset.high, enableAudio: true,
    );
    await _cam!.initialize();
    if (mounted) setState(() { _ready = true; _status = 'Ready'; });
  }

  Future<void> _toggleRecord() async {
    if (!_ready || _cam == null) return;
    if (_recording) {
      final file = await _cam!.stopVideoRecording();
      setState(() { _recording = false; _status = 'Saved: ${file.path.split('/').last}'; _seconds = 0; });
    } else {
      await _cam!.startVideoRecording();
      setState(() { _recording = true; _status = 'Recording...'; });
      _tick();
    }
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_recording && mounted) {
        setState(() => _seconds++);
        _tick();
      }
    });
  }

  @override
  void dispose() { _cam?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready && _cam != null)
            FittedBox(
              fit: BoxFit.cover, clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _cam!.value.previewSize!.height,
                height: _cam!.value.previewSize!.width,
                child: CameraPreview(_cam!),
              ),
            )
          else
            Center(child: Text(_status, style: const TextStyle(color: Colors.white30, fontSize: 12))),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.black.withValues(alpha: 0.4),
              child: Row(
                children: [
                  if (_recording) Container(
                    width: 8, height: 8, margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444)),
                  ),
                  Text(
                    _recording ? 'REC ${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}' : 'DASHCAM',
                    style: TextStyle(color: _recording ? const Color(0xFFEF4444) : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(onTap: widget.onClose, child: const Icon(Icons.close_rounded, color: Colors.white38, size: 20)),
                ],
              ),
            ),
          ),

          // Record button
          Positioned(
            bottom: 20, left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _toggleRecord,
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _recording ? 20 : 42, height: _recording ? 20 : 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(_recording ? 4 : 21),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class MiniGame extends StatefulWidget {
  final VoidCallback onClose;
  const MiniGame({super.key, required this.onClose});

  @override
  State<MiniGame> createState() => _MiniGameState();
}

class _MiniGameState extends State<MiniGame> {
  static const _cols = 10, _rows = 20;
  late List<List<Color?>> _grid;
  List<Offset> _current = [];
  Color _currentColor = Colors.blue;
  int _score = 0;
  bool _gameOver = false;
  Timer? _timer;
  double _carX = 0.5;
  int _carScore = 0;
  bool _carMode = true; // Simple car dodge game
  final _rng = Random();
  final _obstacles = <_Obstacle>[];

  @override
  void initState() {
    super.initState();
    _startCarGame();
  }

  void _startCarGame() {
    _carScore = 0; _carX = 0.5; _obstacles.clear(); _gameOver = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_gameOver) return;
      setState(() {
        _carScore++;
        // Add obstacles
        if (_rng.nextDouble() < 0.03) {
          _obstacles.add(_Obstacle(x: _rng.nextDouble() * 0.8 + 0.1, y: -0.05));
        }
        // Move obstacles
        for (final o in _obstacles) o.y += 0.015;
        _obstacles.removeWhere((o) => o.y > 1.1);
        // Collision
        for (final o in _obstacles) {
          if ((o.x - _carX).abs() < 0.08 && (o.y - 0.85).abs() < 0.05) {
            _gameOver = true;
          }
        }
      });
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111318),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text('Arcade', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Text('Score: $_carScore', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (_gameOver)
                  GestureDetector(
                    onTap: () => setState(() => _startCarGame()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(onTap: widget.onClose, child: const Icon(Icons.close_rounded, color: Colors.white30, size: 20)),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onPanUpdate: (d) {
                final box = context.findRenderObject() as RenderBox;
                setState(() => _carX = (d.localPosition.dx / box.size.width).clamp(0.05, 0.95));
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _CarGamePainter(carX: _carX, obstacles: _obstacles, gameOver: _gameOver),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Obstacle { double x, y; _Obstacle({required this.x, required this.y}); }

class _CarGamePainter extends CustomPainter {
  final double carX;
  final List<_Obstacle> obstacles;
  final bool gameOver;
  _CarGamePainter({required this.carX, required this.obstacles, required this.gameOver});

  @override
  void paint(Canvas canvas, Size size) {
    // Road
    canvas.drawRect(Rect.fromLTWH(size.width * 0.1, 0, size.width * 0.8, size.height),
      Paint()..color = const Color(0xFF1E2430));

    // Lane lines
    for (int i = 1; i < 4; i++) {
      final x = size.width * (0.1 + 0.8 * i / 4);
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 15),
          Paint()..color = Colors.white.withValues(alpha: 0.1)..strokeWidth = 1);
      }
    }

    // Obstacles
    for (final o in obstacles) {
      final ox = o.x * size.width;
      final oy = o.y * size.height;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(ox, oy), width: 30, height: 40), const Radius.circular(4)),
        Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.7),
      );
    }

    // Player car
    final cx = carX * size.width;
    final cy = size.height * 0.85;
    final carPath = Path()
      ..moveTo(cx - 14, cy + 18)
      ..cubicTo(cx - 15, cy + 5, cx - 12, cy - 10, cx, cy - 20)
      ..cubicTo(cx + 12, cy - 10, cx + 15, cy + 5, cx + 14, cy + 18)
      ..close();
    canvas.drawPath(carPath, Paint()..color = const Color(0xFF3B82F6));
    canvas.drawPath(carPath, Paint()..color = const Color(0xFF60A5FA)..style = PaintingStyle.stroke..strokeWidth = 1);

    if (gameOver) {
      final tp = TextPainter(
        text: const TextSpan(text: 'GAME OVER', style: TextStyle(color: Color(0xFFEF4444), fontSize: 24, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _CarGamePainter old) => true;
}

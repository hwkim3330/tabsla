import 'package:flutter/material.dart';

class Sketchpad extends StatefulWidget {
  final VoidCallback onClose;
  const Sketchpad({super.key, required this.onClose});

  @override
  State<Sketchpad> createState() => _SketchpadState();
}

class _SketchpadState extends State<Sketchpad> {
  final _lines = <_Line>[];
  Color _color = Colors.white;
  double _width = 3;

  final _colors = [Colors.white, const Color(0xFF3B82F6), const Color(0xFFEF4444),
    const Color(0xFF22C55E), const Color(0xFFF59E0B), const Color(0xFFEC4899)];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111318),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text('Sketch', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _lines.clear()),
                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20)),
                ),
                const SizedBox(width: 8),
                GestureDetector(onTap: widget.onClose, child: const Icon(Icons.close_rounded, color: Colors.white30, size: 20)),
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: GestureDetector(
              onPanStart: (d) => setState(() => _lines.add(_Line([d.localPosition], _color, _width))),
              onPanUpdate: (d) => setState(() => _lines.last.points.add(d.localPosition)),
              child: CustomPaint(
                size: Size.infinite,
                painter: _SketchPainter(_lines),
              ),
            ),
          ),
          // Color + width picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ..._colors.map((c) => GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 24, height: 24, margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: c,
                      border: _color == c ? Border.all(color: Colors.white54, width: 2) : null,
                    ),
                  ),
                )),
                const Spacer(),
                ...[2.0, 4.0, 8.0].map((w) => GestureDetector(
                  onTap: () => setState(() => _width = w),
                  child: Container(
                    width: 28, height: 28, margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: _width == w ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                    ),
                    child: Center(child: Container(
                      width: w + 2, height: w + 2,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.5)),
                    )),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line {
  final List<Offset> points;
  final Color color;
  final double width;
  _Line(this.points, this.color, this.width);
}

class _SketchPainter extends CustomPainter {
  final List<_Line> lines;
  _SketchPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      if (line.points.length < 2) continue;
      final paint = Paint()..color = line.color..strokeWidth = line.width..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
      final path = Path()..moveTo(line.points.first.dx, line.points.first.dy);
      for (int i = 1; i < line.points.length; i++) path.lineTo(line.points[i].dx, line.points[i].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SketchPainter old) => true;
}

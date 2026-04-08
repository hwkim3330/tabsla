import 'dart:async';
import 'package:flutter/material.dart';
import '../data/haptics.dart';

class MediaPlayer extends StatefulWidget {
  final VoidCallback onClose;
  const MediaPlayer({super.key, required this.onClose});

  @override
  State<MediaPlayer> createState() => _MediaPlayerState();
}

class _MediaPlayerState extends State<MediaPlayer> {
  bool _playing = false;
  int _currentTrack = 0;
  double _progress = 0;
  Timer? _timer;

  final _tracks = [
    _Track('Midnight Drive', 'Synthwave FM', '3:42', const Color(0xFF6366F1)),
    _Track('Neon Highway', 'RetroWave', '4:15', const Color(0xFFEC4899)),
    _Track('Electric Dreams', 'Future Bass', '3:28', const Color(0xFF14B8A6)),
    _Track('Starlight Cruise', 'Lo-Fi Beats', '5:01', const Color(0xFFF59E0B)),
    _Track('Autopilot', 'Ambient', '6:33', const Color(0xFF3B82F6)),
  ];

  void _togglePlay() {
    Haptics.tap();
    setState(() => _playing = !_playing);
    if (_playing) {
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        setState(() {
          _progress += 0.005;
          if (_progress >= 1) { _progress = 0; _nextTrack(); }
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  void _nextTrack() {
    Haptics.tap();
    setState(() { _currentTrack = (_currentTrack + 1) % _tracks.length; _progress = 0; });
  }

  void _prevTrack() {
    Haptics.tap();
    setState(() { _currentTrack = (_currentTrack - 1 + _tracks.length) % _tracks.length; _progress = 0; });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = _tracks[_currentTrack];
    return Container(
      color: const Color(0xFF111318),
      child: Column(
        children: [
          _header('Music', widget.onClose),
          const Spacer(),
          // Album art
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [t.color, t.color.withValues(alpha: 0.5)],
              ),
              boxShadow: [BoxShadow(color: t.color.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 60),
          ),
          const SizedBox(height: 20),
          Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(t.artist, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          const SizedBox(height: 20),
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _progress, minHeight: 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(t.color),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatTime(_progress, t.duration), style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
                    Text(t.duration, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: _prevTrack, icon: const Icon(Icons.skip_previous_rounded), color: Colors.white70, iconSize: 32),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: t.color),
                  child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(onPressed: _nextTrack, icon: const Icon(Icons.skip_next_rounded), color: Colors.white70, iconSize: 32),
            ],
          ),
          const Spacer(),
          // Track list
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tracks.length,
              itemBuilder: (_, i) {
                final tr = _tracks[i];
                final active = i == _currentTrack;
                return GestureDetector(
                  onTap: () { Haptics.tap(); setState(() { _currentTrack = i; _progress = 0; }); },
                  child: Container(
                    width: 110, margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: active ? tr.color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: active ? Border.all(color: tr.color.withValues(alpha: 0.3)) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tr.title, style: TextStyle(color: active ? tr.color : Colors.white54, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                        Text(tr.artist, style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 9)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _formatTime(double progress, String total) {
    final parts = total.split(':');
    final totalSec = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final cur = (totalSec * progress).toInt();
    return '${cur ~/ 60}:${(cur % 60).toString().padLeft(2, '0')}';
  }
}

class _Track {
  final String title, artist, duration;
  final Color color;
  const _Track(this.title, this.artist, this.duration, this.color);
}

Widget _header(String title, VoidCallback onClose) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  child: Row(
    children: [
      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
      const Spacer(),
      GestureDetector(onTap: onClose, child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20)),
    ],
  ),
);

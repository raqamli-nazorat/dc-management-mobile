import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class NoiseGradientBackground extends StatefulWidget {
  final Widget child;

  const NoiseGradientBackground({super.key, required this.child});

  @override
  State<NoiseGradientBackground> createState() =>
      _NoiseGradientBackgroundState();
}

class _NoiseGradientBackgroundState extends State<NoiseGradientBackground> {
  ui.Image? _noiseImage;

  @override
  void initState() {
    super.initState();
    _generateNoise();
  }

  Future<void> _generateNoise() async {
    const tileSize = 256;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final random = Random(7);
    final paint = Paint()..isAntiAlias = false;

    for (int x = 0; x < tileSize; x++) {
      for (int y = 0; y < tileSize; y++) {
        final v = random.nextInt(255);
        final a = random.nextInt(22) + 4;
        paint.color = Color.fromARGB(a, v, v, v);
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
          paint,
        );
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(tileSize, tileSize);
    if (mounted) setState(() => _noiseImage = image);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NoisePainter(_noiseImage),
      child: widget.child,
    );
  }
}

class _NoisePainter extends CustomPainter {
  final ui.Image? noiseImage;

  _NoisePainter(this.noiseImage);

  static const _colors = [
    Color(0xFFE6ECFF),
    Color(0xFFA5B4FC),
    Color(0xFF526ED3),
    Color(0xFF3B4DDB),
    Color(0xFF1F2A7A),
  ];

  static const _stops = [0.0, 0.25, 0.55, 0.75, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Gradient layer
    final gradPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _colors,
        stops: _stops,
      ).createShader(rect);
    canvas.drawRect(rect, gradPaint);

    // Noise overlay
    if (noiseImage != null) {
      final matrix = Matrix4.identity().storage;
      final shader = ImageShader(
        noiseImage!,
        TileMode.repeated,
        TileMode.repeated,
        matrix,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = shader
          ..blendMode = BlendMode.softLight,
      );
    }
  }

  @override
  bool shouldRepaint(_NoisePainter old) => old.noiseImage != noiseImage;
}

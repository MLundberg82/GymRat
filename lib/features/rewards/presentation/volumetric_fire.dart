import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A mobile-sized CC0 fluid-fire atlas with additive optical blending.
class VolumetricFire extends StatefulWidget {
  const VolumetricFire({super.key, required this.progress, this.intensity = 1});

  static const asset = 'assets/effects/volumetric_fire_cc0.png';
  static const columns = 8;
  static const rows = 4;
  static const frameCount = 32;

  final double progress;
  final double intensity;

  static int frameIndexFor(double progress) {
    final value = progress.clamp(0.0, 1.0).toDouble();
    if (value >= 1) return frameCount - 1;
    final loop = (value * 3.4) % 1;
    return (loop * frameCount).floor().clamp(0, frameCount - 1);
  }

  @override
  State<VolumetricFire> createState() => _VolumetricFireState();
}

class _VolumetricFireState extends State<VolumetricFire> {
  static Future<ui.Image>? _sharedImage;

  late final Future<ui.Image> _image;

  @override
  void initState() {
    super.initState();
    _image = _sharedImage ??= _decode();
  }

  static Future<ui.Image> _decode() async {
    final data = await rootBundle.load(VolumetricFire.asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    return image;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress.clamp(0.0, 1.0).toDouble();
    final entrance = Curves.easeOutCubic.transform((p / .18).clamp(0.0, 1.0));
    final exit =
        1 - Curves.easeInCubic.transform(((p - .88) / .12).clamp(0.0, 1.0));
    final opacity = (entrance * exit * widget.intensity * .72).clamp(0.0, 1.0);
    return FutureBuilder<ui.Image>(
      future: _image,
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) return const SizedBox.expand();
        return IgnorePointer(
          child: CustomPaint(
            painter: _VolumetricFirePainter(
              image: image,
              frameIndex: VolumetricFire.frameIndexFor(p),
              opacity: opacity,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _VolumetricFirePainter extends CustomPainter {
  const _VolumetricFirePainter({
    required this.image,
    required this.frameIndex,
    required this.opacity,
  });

  final ui.Image image;
  final int frameIndex;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;
    final frameWidth = image.width / VolumetricFire.columns;
    final frameHeight = image.height / VolumetricFire.rows;
    for (var layer = 0; layer < 2; layer++) {
      final plumeCount = layer == 0 ? 6 : 5;
      for (var plume = 0; plume < plumeCount; plume++) {
        final seed = _noise(plume * 47 + layer * 101);
        final offsetFrame =
            (frameIndex + plume * 3 + layer * 11) % VolumetricFire.frameCount;
        final offsetColumn = offsetFrame % VolumetricFire.columns;
        final offsetRow = offsetFrame ~/ VolumetricFire.columns;
        final offsetSource = Rect.fromLTWH(
          offsetColumn * frameWidth,
          offsetRow * frameHeight,
          frameWidth,
          frameHeight,
        );
        final width =
            size.width * (.19 + seed * .075) * (layer == 0 ? .82 : 1.0);
        final height = width * (1.92 + seed * .36);
        final centerX =
            size.width * ((plume + .5) / plumeCount) +
            (seed - .5) * size.width * .055;
        final destination = Rect.fromLTWH(
          centerX - width * .5,
          size.height - height + 8 + seed * 16,
          width,
          height,
        );
        canvas.drawImageRect(
          image,
          offsetSource,
          destination,
          Paint()
            ..filterQuality = FilterQuality.high
            ..color = Colors.white.withValues(
              alpha: opacity * (layer == 0 ? .42 : .78),
            )
            ..maskFilter = layer == 0
                ? const MaskFilter.blur(BlurStyle.normal, 2.2)
                : null,
        );
      }
    }
  }

  double _noise(int value) {
    final raw = value * 0.7548776662466927;
    return raw - raw.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _VolumetricFirePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.frameIndex != frameIndex ||
      oldDelegate.opacity != opacity;
}

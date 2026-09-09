import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A compact photo-realistic fire dome played from one RGBA sprite atlas.
///
/// The expensive image decode is shared for the lifetime of the process. The
/// surrounding reward painters add sparks, smoke, light and shockwaves while
/// this layer supplies the volumetric combustion that vector rays cannot fake.
class VolumetricExplosion extends StatefulWidget {
  const VolumetricExplosion({
    super.key,
    required this.progress,
    this.start = 0,
    this.end = 1,
    this.alignment = Alignment.center,
    this.scale = 1,
    this.opacity = 1,
  }) : assert(start < end);

  static const asset = 'assets/effects/volumetric_explosion_cc_by.png';
  static const columns = 10;
  static const rows = 8;
  static const frameCount = 74;

  final double progress;
  final double start;
  final double end;
  final Alignment alignment;
  final double scale;
  final double opacity;

  static int frameIndexFor(double progress) {
    final value = progress.clamp(0.0, 1.0).toDouble();
    return (value * (frameCount - 1)).floor();
  }

  @override
  State<VolumetricExplosion> createState() => _VolumetricExplosionState();
}

class _VolumetricExplosionState extends State<VolumetricExplosion> {
  static Future<ui.Image>? _sharedImage;

  late final Future<ui.Image> _image;

  @override
  void initState() {
    super.initState();
    _image = _sharedImage ??= _decode();
  }

  static Future<ui.Image> _decode() async {
    final data = await rootBundle.load(VolumetricExplosion.asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    return image;
  }

  @override
  Widget build(BuildContext context) {
    final local =
        ((widget.progress - widget.start) / (widget.end - widget.start))
            .clamp(0.0, 1.0)
            .toDouble();
    if (widget.progress < widget.start || widget.progress > widget.end) {
      return const SizedBox.expand();
    }

    final attack = Curves.easeOutCubic.transform((local / .12).clamp(0.0, 1.0));
    final release =
        1 - Curves.easeInCubic.transform(((local - .68) / .32).clamp(0.0, 1.0));
    final envelope = attack * release;
    return FutureBuilder<ui.Image>(
      future: _image,
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) return const SizedBox.expand();
        return IgnorePointer(
          child: CustomPaint(
            painter: _VolumetricExplosionPainter(
              image: image,
              frameIndex: VolumetricExplosion.frameIndexFor(local),
              alignment: widget.alignment,
              scale: widget.scale,
              opacity: (widget.opacity * envelope).clamp(0.0, 1.0),
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _VolumetricExplosionPainter extends CustomPainter {
  const _VolumetricExplosionPainter({
    required this.image,
    required this.frameIndex,
    required this.alignment,
    required this.scale,
    required this.opacity,
  });

  final ui.Image image;
  final int frameIndex;
  final Alignment alignment;
  final double scale;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;
    final frameWidth = image.width / VolumetricExplosion.columns;
    final frameHeight = image.height / VolumetricExplosion.rows;
    final column = frameIndex % VolumetricExplosion.columns;
    final row = frameIndex ~/ VolumetricExplosion.columns;
    final source = Rect.fromLTWH(
      column * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );
    final width = size.shortestSide * .94 * scale;
    final height = width * frameHeight / frameWidth;
    final anchor = alignment.alongSize(size);
    final destination = Rect.fromCenter(
      center: anchor,
      width: width,
      height: height,
    );

    canvas.drawCircle(
      anchor,
      width * .34,
      Paint()
        ..color = const Color(0xFFFF5A00).withValues(alpha: opacity * .36)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * .11),
    );
    canvas.drawImageRect(
      image,
      source,
      destination,
      Paint()
        ..filterQuality = FilterQuality.high
        ..color = Colors.white.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _VolumetricExplosionPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.frameIndex != frameIndex ||
      oldDelegate.alignment != alignment ||
      oldDelegate.scale != scale ||
      oldDelegate.opacity != opacity;
}

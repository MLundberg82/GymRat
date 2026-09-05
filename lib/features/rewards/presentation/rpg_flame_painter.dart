import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A deterministic, allocation-light fire and ember layer for reward scenes.
///
/// The painter deliberately uses no random state so captured reward frames and
/// widget tests remain stable across platforms.
class RpgFlamePainter extends CustomPainter {
  const RpgFlamePainter({
    required this.progress,
    required this.intensity,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final double intensity;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final p = progress.clamp(0.0, 1.0).toDouble();
    final entrance = Curves.easeOutCubic.transform(
      (p / .22).clamp(0.0, 1.0).toDouble(),
    );
    final exit = 1 - ((p - .90) / .10).clamp(0.0, 1.0).toDouble();
    final strength = (entrance * exit * intensity).clamp(0.0, 1.8);
    if (strength <= 0) return;

    _paintGroundGlow(canvas, size, strength);
    _paintFlames(canvas, size, p, strength);
    _paintEmbers(canvas, size, p, strength);
  }

  void _paintGroundGlow(Canvas canvas, Size size, double strength) {
    final glow = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomCenter,
        radius: .72,
        colors: <Color>[
          secondary.withValues(alpha: .24 * strength.clamp(0, 1)),
          primary.withValues(alpha: .10 * strength.clamp(0, 1)),
          Colors.transparent,
        ],
        stops: const <double>[0, .48, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);
  }

  void _paintFlames(Canvas canvas, Size size, double p, double strength) {
    const count = 13;
    final maxHeight = size.height * (.19 + .04 * strength.clamp(0, 1));
    for (var index = 0; index < count; index++) {
      final fraction = (index + .5) / count;
      final wave = math.sin(p * math.pi * 7 + index * 1.71);
      final width = size.width / count * (1.05 + (index % 3) * .12);
      final height = maxHeight * (.43 + (index % 5) * .10) * (1 + wave * .16);
      final centerX = size.width * fraction + wave * width * .14;
      final baseY = size.height + 3;
      final path = Path()
        ..moveTo(centerX - width * .58, baseY)
        ..cubicTo(
          centerX - width * .62,
          baseY - height * .30,
          centerX - width * .10,
          baseY - height * .55,
          centerX + wave * width * .20,
          baseY - height,
        )
        ..cubicTo(
          centerX + width * .11,
          baseY - height * .56,
          centerX + width * .66,
          baseY - height * .31,
          centerX + width * .58,
          baseY,
        )
        ..close();
      final rect = Rect.fromLTWH(
        centerX - width,
        baseY - height,
        width * 2,
        height,
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[
              primary.withValues(alpha: (.52 * strength).clamp(0, .82)),
              secondary.withValues(alpha: (.46 * strength).clamp(0, .76)),
              secondary.withValues(alpha: 0),
            ],
            stops: const <double>[0, .42, 1],
          ).createShader(rect),
      );
    }
  }

  void _paintEmbers(Canvas canvas, Size size, double p, double strength) {
    const count = 24;
    for (var index = 0; index < count; index++) {
      final seed = (index * 37 % 101) / 101;
      final cycle = (p * (1.25 + (index % 4) * .18) + seed) % 1;
      final x = size.width * (.05 + .90 * ((index * 53 % 97) / 97));
      final drift = math.sin(p * math.pi * 5 + index) * 12;
      final y = size.height * (1.02 - cycle * (.54 + (index % 3) * .10));
      final fade = math.sin(cycle * math.pi).clamp(0.0, 1.0);
      final radius = 1.1 + (index % 4) * .55;
      canvas.drawCircle(
        Offset(x + drift, y),
        radius,
        Paint()
          ..color = Color.lerp(
            primary,
            secondary,
            index.isEven ? .3 : .8,
          )!.withValues(alpha: (.70 * fade * strength).clamp(0, .92)),
      );
    }
  }

  @override
  bool shouldRepaint(RpgFlamePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary;
}

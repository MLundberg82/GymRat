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
    _paintSmoke(canvas, size, p, strength);
    _paintEmbers(canvas, size, p, strength);
  }

  void _paintGroundGlow(Canvas canvas, Size size, double strength) {
    final bounds = Offset.zero & size;
    final glow = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomCenter,
        radius: .62,
        colors: <Color>[
          const Color(0xFFFFF2C4).withValues(alpha: .18 * strength.clamp(0, 1)),
          primary.withValues(alpha: .25 * strength.clamp(0, 1)),
          const Color(0xFF5A1200).withValues(alpha: .12 * strength.clamp(0, 1)),
          Colors.transparent,
        ],
        stops: const <double>[0, .27, .58, 1],
      ).createShader(bounds);
    canvas.drawRect(bounds, glow);

    final reflection = Rect.fromCenter(
      center: Offset(size.width * .5, size.height * .985),
      width: size.width * .88,
      height: size.height * .075,
    );
    canvas.drawOval(
      reflection,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFC04D)
                .withValues(alpha: .30 * strength.clamp(0, 1)),
            primary.withValues(alpha: .10 * strength.clamp(0, 1)),
            Colors.transparent,
          ],
        ).createShader(reflection)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  void _paintSmoke(Canvas canvas, Size size, double p, double strength) {
    const count = 15;
    for (var index = 0; index < count; index++) {
      final seed = _noise(index * 67 + 19);
      final cycle = (p * (.42 + seed * .20) + seed) % 1;
      final drift = math.sin(p * math.pi * 3.2 + index * 1.37);
      final point = Offset(
        size.width * (.08 + seed * .84) + drift * (12 + 20 * cycle),
        size.height * (1.01 - cycle * .63),
      );
      final radius = size.shortestSide * (.018 + cycle * .045);
      final fade = math.sin(cycle * math.pi).clamp(0.0, 1.0);
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF2B211C),
            const Color(0xFF81746A),
            cycle * .38,
          )!.withValues(alpha: (.12 * fade * strength).clamp(0.0, .17))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * .72),
      );
    }
  }

  void _paintEmbers(Canvas canvas, Size size, double p, double strength) {
    const count = 38;
    for (var index = 0; index < count; index++) {
      final seed = _noise(index * 43 + 7);
      final depth = .36 + _noise(index * 71 + 3) * .64;
      final cycle = (p * (.72 + seed * .48) + seed) % 1;
      final x = size.width * (.04 + .92 * _noise(index * 53 + 11));
      final drift = math.sin(p * math.pi * 5 + index) * (8 + depth * 17);
      final y = size.height * (1.02 - cycle * (.52 + depth * .24));
      final fade = math.sin(cycle * math.pi).clamp(0.0, 1.0);
      final point = Offset(x + drift, y);
      final trail = Offset(drift * .025, 5 + 12 * depth);
      final color = Color.lerp(
        const Color(0xFFFF6D00),
        const Color(0xFFFFF3C4),
        seed,
      )!.withValues(alpha: (.78 * fade * strength).clamp(0, .94));
      canvas.drawLine(
        point + trail,
        point,
        Paint()
          ..color = color
          ..strokeWidth = .7 + depth * 1.7
          ..strokeCap = StrokeCap.round
          ..maskFilter = depth < .55
              ? const MaskFilter.blur(BlurStyle.normal, 1.2)
              : null,
      );
    }
  }

  double _noise(int value) {
    final raw = math.sin(value * 12.9898 + 78.233) * 43758.5453;
    return raw - raw.floorToDouble();
  }

  @override
  bool shouldRepaint(RpgFlamePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary;
}

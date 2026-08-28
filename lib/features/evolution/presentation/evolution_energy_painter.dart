import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/gymrat_colors.dart';

class EvolutionEnergyPainter extends CustomPainter {
  const EvolutionEnergyPainter({
    required this.progress,
    required this.intensity,
  });

  final double progress;
  final double intensity;

  double _phase(double start, double end) {
    return ((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .49);
    final shortest = size.shortestSide;
    final charge = Curves.easeInOutCubic.transform(_phase(.03, .46));
    final blast = Curves.easeOutQuart.transform(_phase(.43, .68));
    final settle = Curves.easeOutCubic.transform(_phase(.64, .94));
    final chargeFade = 1 - Curves.easeIn.transform(_phase(.43, .62));
    final blastFade = 1 - Curves.easeIn.transform(_phase(.62, .88));

    _drawAura(canvas, center, shortest, charge, settle);
    _drawOrbitRings(canvas, center, shortest, charge, blast);
    _drawChargeRays(canvas, center, shortest, charge, chargeFade);
    _drawExplosion(canvas, center, shortest, blast, blastFade);
    _drawLightning(canvas, size, center, charge, blast, blastFade);
    _drawParticles(canvas, center, shortest, charge, blast, blastFade);
  }

  void _drawAura(
    Canvas canvas,
    Offset center,
    double shortest,
    double charge,
    double settle,
  ) {
    final pulse = .82 + math.sin(progress * math.pi * 22).abs() * .18;
    final radius = shortest * (.16 + .24 * charge + .04 * settle);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: .08 * charge),
            GymRatColors.gold.withValues(alpha: .24 * charge * pulse),
            const Color(0xFF23F58A).withValues(alpha: .13 * charge),
            Colors.transparent,
          ],
          stops: const <double>[0, .28, .66, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _drawOrbitRings(
    Canvas canvas,
    Offset center,
    double shortest,
    double charge,
    double blast,
  ) {
    for (var ring = 0; ring < 5; ring++) {
      final phase = (progress * (1.15 + ring * .14) + ring * .17) % 1;
      final radius = shortest * (.17 + ring * .055 + phase * .05);
      final alpha = charge * (1 - blast) * (.42 - ring * .055);
      final rect = Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * (1.05 + ring * .08),
      );
      canvas.drawArc(
        rect,
        progress * math.pi * (ring.isEven ? 5 : -4),
        math.pi * (1.12 + ring * .13),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 + ring * .65
          ..strokeCap = StrokeCap.round
          ..color = (ring.isEven ? GymRatColors.gold : const Color(0xFF55FFAA))
              .withValues(alpha: alpha.clamp(0.0, 1.0).toDouble()),
      );
    }
  }

  void _drawChargeRays(
    Canvas canvas,
    Offset center,
    double shortest,
    double charge,
    double fade,
  ) {
    const count = 72;
    for (var i = 0; i < count; i++) {
      final angle =
          i / count * math.pi * 2 + progress * (i.isEven ? 1.7 : -1.2);
      final direction = Offset(math.cos(angle), math.sin(angle));
      final wave = .52 + (i % 9) * .055;
      final outer = shortest * (.28 + .24 * charge) * wave;
      final inner = outer - shortest * (.025 + (i % 5) * .009) * charge;
      final alpha = charge * fade * (.32 + (i % 7) * .07) * intensity;
      canvas.drawLine(
        center + direction * inner,
        center + direction * outer,
        Paint()
          ..strokeWidth = 1 + (i % 4) * .7
          ..strokeCap = StrokeCap.round
          ..color = (i % 3 == 0 ? Colors.white : GymRatColors.gold).withValues(
            alpha: alpha.clamp(0.0, 1.0).toDouble(),
          ),
      );
    }
  }

  void _drawExplosion(
    Canvas canvas,
    Offset center,
    double shortest,
    double blast,
    double fade,
  ) {
    if (blast <= 0) return;
    const count = 118;
    for (var i = 0; i < count; i++) {
      final angle = i / count * math.pi * 2 + (i % 11) * .026;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final length = shortest * (.12 + .75 * blast) * (.46 + (i % 10) * .06);
      final alpha = fade * (.42 + (i % 6) * .09) * intensity;
      canvas.drawLine(
        center + direction * length * .08,
        center + direction * length,
        Paint()
          ..strokeWidth = 1.2 + (i % 6) * .85
          ..strokeCap = StrokeCap.round
          ..color = <Color>[
            Colors.white,
            GymRatColors.gold,
            const Color(0xFFFF8F00),
            const Color(0xFF41FF9A),
          ][i % 4].withValues(alpha: alpha.clamp(0.0, 1.0).toDouble()),
      );
    }
  }

  void _drawLightning(
    Canvas canvas,
    Size size,
    Offset center,
    double charge,
    double blast,
    double fade,
  ) {
    final energy = math.max(charge * (1 - blast), blast * fade) * intensity;
    if (energy <= .02) return;
    for (var bolt = 0; bolt < 14; bolt++) {
      final angle = bolt / 14 * math.pi * 2 + progress * 2.4;
      final startRadius = size.shortestSide * (.13 + (bolt % 4) * .025);
      final endRadius = size.shortestSide * (.38 + (bolt % 5) * .055);
      final start =
          center + Offset(math.cos(angle), math.sin(angle)) * startRadius;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * endRadius;
      final path = Path()..moveTo(start.dx, start.dy);
      const segments = 6;
      for (var segment = 1; segment <= segments; segment++) {
        final t = segment / segments;
        final base = Offset.lerp(start, end, t)!;
        final normal = Offset(-math.sin(angle), math.cos(angle));
        final zigzag = math.sin((segment + bolt) * 2.7) * (8 + bolt % 4 * 3);
        path.lineTo(base.dx + normal.dx * zigzag, base.dy + normal.dy * zigzag);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bolt.isEven ? 3.2 : 1.8
          ..strokeCap = StrokeCap.round
          ..color =
              (bolt % 3 == 0 ? const Color(0xFF54FFAA) : GymRatColors.gold)
                  .withValues(alpha: (energy * .82).clamp(0.0, 1.0).toDouble())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  void _drawParticles(
    Canvas canvas,
    Offset center,
    double shortest,
    double charge,
    double blast,
    double fade,
  ) {
    const count = 190;
    for (var i = 0; i < count; i++) {
      final seed = (i * 73 % 191) / 191;
      final angle = seed * math.pi * 2 + progress * (i.isEven ? 2.1 : -1.45);
      final travel = blast > 0
          ? (.12 + blast * (.48 + (i % 8) * .055))
          : (.13 + charge * .19 + seed * .12);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * shortest * travel;
      final alpha = (blast > 0 ? fade : charge * .68) * intensity;
      canvas.drawCircle(
        point,
        1.2 + (i % 6) * .7,
        Paint()
          ..color = <Color>[
            GymRatColors.gold,
            const Color(0xFFFFE082),
            const Color(0xFF35F58C),
            Colors.white,
          ][i % 4].withValues(alpha: alpha.clamp(0.0, 1.0).toDouble()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant EvolutionEnergyPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity;
  }
}

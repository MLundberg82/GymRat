import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../../core/units/weight_unit_store.dart';
import '../../workout/domain/workout_result.dart';
import '../../workout/presentation/workout_copy.dart';

class PrCelebration extends StatefulWidget {
  const PrCelebration({
    super.key,
    required this.pr,
    required this.position,
    required this.total,
  });

  static const duration = Duration(milliseconds: 2800);
  final WorkoutPR pr;
  final int position;
  final int total;

  @override
  State<PrCelebration> createState() => _PrCelebrationState();
}

class _PrCelebrationState extends State<PrCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Timer> _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PrCelebration.duration,
    )..forward();
    HapticFeedback.heavyImpact();
    _timers.add(
      Timer(const Duration(milliseconds: 180), HapticFeedback.vibrate),
    );
    _timers.add(
      Timer(const Duration(milliseconds: 520), HapticFeedback.heavyImpact),
    );
    _timers.add(
      Timer(const Duration(milliseconds: 980), HapticFeedback.mediumImpact),
    );
    _timers.add(
      Timer(const Duration(milliseconds: 1550), HapticFeedback.selectionClick),
    );
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  double _part(double p, double start, double end, Curve curve) {
    final value = ((p - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(value.toDouble());
  }

  double _pulse(double p, double start, double end) {
    if (p <= start || p >= end) return 0;
    return math.sin((p - start) / (end - start) * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GymRatColors.black,
      child: AnimatedBuilder(animation: _controller, builder: _buildFrame),
    );
  }

  Widget _buildFrame(BuildContext context, Widget? child) {
    final p = _controller.value;
    final impact = _part(p, .02, .27, Curves.easeOutBack);
    final reveal = _part(p, .18, .48, Curves.easeOutBack);
    final reward = _part(p, .43, .70, Curves.elasticOut);
    final fade = p < .93
        ? 1.0
        : 1 - ((p - .93) / .07).clamp(0.0, 1.0).toDouble();
    final firstShake = p < .34 ? math.sin(p * 210) * (1 - p / .34) * 17 : 0.0;
    final secondShake = p > .39 && p < .57
        ? math.sin(p * 260) * (1 - (p - .39) / .18) * 8
        : 0.0;
    final shake = firstShake + secondShake;
    final camera = 1 + _pulse(p, .02, .28) * .075 + _pulse(p, .40, .62) * .035;
    final whiteFlash = (_pulse(p, .01, .13) * .90 + _pulse(p, .42, .54) * .58)
        .clamp(0.0, 1.0)
        .toDouble();
    final goldFlash = (_pulse(p, .10, .34) * .34).clamp(0.0, 1.0).toDouble();

    return Opacity(
      opacity: fade,
      child: Transform.scale(
        scale: camera,
        child: Transform.translate(
          offset: Offset(shake, shake * .22),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _background(p),
              CustomPaint(painter: _PrExplosionPainter(p)),
              SafeArea(child: _stage(context, p, impact, reveal, reward)),
              IgnorePointer(
                child: ColoredBox(
                  color: const Color(0xFFFF8F00).withValues(alpha: goldFlash),
                ),
              ),
              IgnorePointer(
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: whiteFlash),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _background(double p) {
    final heat = _pulse(p, .02, .82);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -.18),
          radius: .94,
          colors: <Color>[
            Color.lerp(const Color(0xFF4A1800), const Color(0xFFFF8F00), heat)!,
            const Color(0xFF3A2400),
            const Color(0xFF07140C),
            GymRatColors.black,
          ],
          stops: const <double>[0, .26, .62, 1],
        ),
      ),
    );
  }

  Widget _stage(
    BuildContext context,
    double p,
    double impact,
    double reveal,
    double reward,
  ) {
    final revealOpacity = ((p - .18) / .30).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (widget.total > 1)
            Text(
              '${widget.position} / ${widget.total}',
              style: const TextStyle(
                color: GymRatColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Transform.rotate(
                  angle: p * math.pi * 3,
                  child: Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .34),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -p * math.pi * 4,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: GymRatColors.gold, width: 4),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: .12 + impact * .88,
                  child: Container(
                    width: 142,
                    height: 142,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: <Color>[
                          Colors.white,
                          Color(0xFFFFE082),
                          GymRatColors.gold,
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFFFF8F00).withValues(alpha: .86),
                          blurRadius: 100,
                          spreadRadius: 30,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: GymRatColors.black,
                      size: 82,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: revealOpacity,
            child: Transform.scale(
              scale: .58 + reveal * .42,
              child: Column(
                children: <Widget>[
                  Text(
                    context.tr.t('recordBroken'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: <Shadow>[
                        Shadow(color: Color(0xFFFF8F00), blurRadius: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    context.tr.t('newPersonalBest'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GymRatColors.gold,
                      fontSize: 34,
                      height: .94,
                      fontWeight: FontWeight.w900,
                      shadows: <Shadow>[
                        Shadow(color: Color(0xFFFF8F00), blurRadius: 28),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    WorkoutCopy.exercise(
                      context,
                      widget.pr.exercise,
                    ).toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GymRatColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '${WeightUnitStore.formatKilograms(widget.pr.previousBest, includeUnit: false)} '
                        '${WeightUnitStore.symbolUpper}',
                        style: const TextStyle(
                          color: GymRatColors.textMuted,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.double_arrow_rounded,
                          color: GymRatColors.gold,
                          size: 27,
                        ),
                      ),
                      Transform.scale(
                        scale: .38 + reward * .62,
                        child: Text(
                          '${WeightUnitStore.formatKilograms(widget.pr.newWeight, includeUnit: false)} '
                          '${WeightUnitStore.symbolUpper}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            shadows: <Shadow>[
                              Shadow(color: GymRatColors.gold, blurRadius: 30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Transform.scale(
                    scale: .30 + reward * .70,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: GymRatColors.black.withValues(alpha: .78),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: GymRatColors.gold,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '▲ +${WeightUnitStore.formatKilograms(widget.pr.newWeight - widget.pr.previousBest, includeUnit: false)} '
                            '${WeightUnitStore.symbolUpper}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFFFF8F00),
                                GymRatColors.gold,
                                Color(0xFFFFF3B0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: GymRatColors.gold.withValues(alpha: .68),
                                blurRadius: 38,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: const Text(
                            '+18 XP',
                            style: TextStyle(
                              color: GymRatColors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrExplosionPainter extends CustomPainter {
  const _PrExplosionPainter(this.progress);
  final double progress;

  double _part(double start, double end) =>
      ((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .35);
    final burst = Curves.easeOutQuart.transform(_part(.01, .58));
    final after = Curves.easeOutCubic.transform(_part(.34, .86));
    final burstFade = (1 - burst).clamp(0.0, 1.0).toDouble();
    const colors = <Color>[
      Colors.white,
      Color(0xFFFFF3B0),
      GymRatColors.gold,
      Color(0xFFFF8F00),
      Color(0xFF2EFF88),
    ];

    canvas.drawCircle(
      center,
      size.shortestSide * (.05 + .28 * burst),
      Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: burstFade * .52)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    for (var i = 0; i < 72; i++) {
      final angle = i / 72 * math.pi * 2 + (i % 5) * .027;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final length =
          size.shortestSide * (.20 + .67 * burst) * (.54 + (i % 9) * .052);
      canvas.drawLine(
        center + direction * length * .16,
        center + direction * length,
        Paint()
          ..color = colors[i % colors.length].withValues(alpha: burstFade * .94)
          ..strokeWidth = 1.4 + (i % 5) * .85
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var ring = 0; ring < 5; ring++) {
      final value = ((progress - .025 - ring * .035) / (.42 + ring * .055))
          .clamp(0.0, 1.0)
          .toDouble();
      canvas.drawCircle(
        center,
        size.shortestSide * (.08 + .65 * value),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11 * (1 - value) + 1
          ..color = colors[ring].withValues(alpha: (1 - value) * .82),
      );
    }

    for (var i = 0; i < 96; i++) {
      final angle = i / 96 * math.pi * 2 + (i % 11) * .041;
      final speed = .55 + (i % 10) * .055;
      final distance = size.shortestSide * (.10 + .78 * burst) * speed;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final radius = 1.8 + (i % 5) * 1.05;
      canvas.drawCircle(
        point,
        radius,
        Paint()..color = colors[i % colors.length].withValues(alpha: burstFade),
      );
    }

    final afterFade = (1 - after).clamp(0.0, 1.0).toDouble();
    for (var i = 0; i < 44; i++) {
      final angle = i / 44 * math.pi * 2 - progress * 1.8;
      final distance =
          size.shortestSide * (.12 + .62 * after) * (.64 + (i % 6) * .055);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + after * 4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 10 + (i % 4) * 4,
          height: 2.5 + (i % 3),
        ),
        Paint()
          ..color = colors[(i + 2) % colors.length].withValues(
            alpha: afterFade * .92,
          ),
      );
      canvas.restore();
    }

    if (progress < .64) {
      final lightning = math.sin(_part(.03, .64) * math.pi).abs();
      for (var bolt = 0; bolt < 10; bolt++) {
        final angle = bolt / 10 * math.pi * 2 + progress * 2;
        final path = Path()..moveTo(center.dx, center.dy);
        for (var step = 1; step <= 5; step++) {
          final distance = size.shortestSide * .07 * step;
          final side = (step.isEven ? 1 : -1) * 8.0;
          path.lineTo(
            center.dx +
                math.cos(angle) * distance +
                math.cos(angle + math.pi / 2) * side,
            center.dy +
                math.sin(angle) * distance +
                math.sin(angle + math.pi / 2) * side,
          );
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = bolt.isEven ? 3.2 : 1.8
            ..color = colors[bolt % colors.length].withValues(
              alpha: lightning * .82,
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PrExplosionPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

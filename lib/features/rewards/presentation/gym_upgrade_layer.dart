import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/gym_upgrade.dart';

class GymUpgradeLayer extends StatefulWidget {
  const GymUpgradeLayer({super.key, required this.level, this.highlightLevel});

  final int level;
  final int? highlightLevel;

  @override
  State<GymUpgradeLayer> createState() => _GymUpgradeLayerState();
}

class _GymUpgradeLayerState extends State<GymUpgradeLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  GymUpgradeType? get _highlightType {
    final level = widget.highlightLevel;
    if (level == null || level < 2 || level > widget.level) return null;
    return GymUpgradeCatalog.forLevel(level).type;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
      value: _highlightType == null ? 1 : 0,
    );
    if (_highlightType != null) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant GymUpgradeLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final type = _highlightType;
    if (type != null &&
        (oldWidget.level != widget.level ||
            oldWidget.highlightLevel != widget.highlightLevel)) {
      _controller.forward(from: 0);
    } else if (type == null) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiers = GymUpgradeCatalog.tiersAtLevel(widget.level);
    return IgnorePointer(
      child: SizedBox.expand(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              painter: _GymUpgradePainter(
                tiers: tiers,
                highlightType: _highlightType,
                reveal: _controller.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GymUpgradePainter extends CustomPainter {
  const _GymUpgradePainter({
    required this.tiers,
    required this.highlightType,
    required this.reveal,
  });

  final Map<GymUpgradeType, int> tiers;
  final GymUpgradeType? highlightType;
  final double reveal;

  int _tier(GymUpgradeType type) => tiers[type] ?? 0;

  @override
  void paint(Canvas canvas, Size size) {
    _drawSpotlights(canvas, size, _tier(GymUpgradeType.spotlights));
    _drawPowerRack(canvas, size, _tier(GymUpgradeType.powerRack));
    _drawDumbbells(canvas, size, _tier(GymUpgradeType.dumbbellRack));
    _drawPlates(canvas, size, _tier(GymUpgradeType.weightPlates));
    _drawSpeakers(canvas, size, _tier(GymUpgradeType.speakers));
    _drawBanner(canvas, size, _tier(GymUpgradeType.banner));
    _drawPlaque(canvas, size, _tier(GymUpgradeType.championPlaque));
    _drawNeon(canvas, size, _tier(GymUpgradeType.neonLights));
    _drawUnlockPulse(canvas, size);
  }

  void _item(Canvas canvas, Size size, GymUpgradeType type, VoidCallback draw) {
    final isNew = highlightType == type;
    final animation = isNew
        ? Curves.elasticOut.transform(reveal.clamp(0.0, 1.0).toDouble())
        : 1.0;
    final anchor = _anchor(type, size);
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.scale(.12 + .88 * animation, .12 + .88 * animation);
    canvas.translate(-anchor.dx, -anchor.dy);
    draw();
    canvas.restore();
  }

  Offset _anchor(GymUpgradeType type, Size size) {
    return switch (type) {
      GymUpgradeType.dumbbellRack => Offset(
        size.width * .22,
        size.height * .78,
      ),
      GymUpgradeType.neonLights => Offset(size.width * .50, size.height * .14),
      GymUpgradeType.weightPlates => Offset(
        size.width * .84,
        size.height * .78,
      ),
      GymUpgradeType.powerRack => Offset(size.width * .50, size.height * .50),
      GymUpgradeType.banner => Offset(size.width * .78, size.height * .24),
      GymUpgradeType.spotlights => Offset(size.width * .50, size.height * .18),
      GymUpgradeType.speakers => Offset(size.width * .50, size.height * .48),
      GymUpgradeType.championPlaque => Offset(
        size.width * .17,
        size.height * .23,
      ),
    };
  }

  void _drawUnlockPulse(Canvas canvas, Size size) {
    final type = highlightType;
    if (type == null || reveal >= 1) return;
    final anchor = _anchor(type, size);
    final wave = Curves.easeOutCubic.transform(reveal);
    final opacity = (1 - reveal).clamp(0.0, 1.0).toDouble();
    canvas.drawCircle(
      anchor,
      24 + size.shortestSide * .28 * wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * opacity + 1
        ..color = const Color(0xFFFFC107).withValues(alpha: opacity * .92),
    );
    canvas.drawCircle(
      anchor,
      18 + size.shortestSide * .16 * wave,
      Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: opacity * .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
  }

  void _drawPowerRack(Canvas canvas, Size size, int tier) {
    if (tier < 1) return;
    _item(canvas, size, GymUpgradeType.powerRack, () {
      final left = size.width * .17;
      final right = size.width * .83;
      final top = size.height * .25;
      final bottom = size.height * .82;
      final steel = Paint()
        ..color = const Color(0xFFB6C1BC).withValues(alpha: .78)
        ..strokeWidth = 6 + tier.clamp(1, 5).toDouble() * .7
        ..strokeCap = StrokeCap.round;
      final shadow = Paint()
        ..color = Colors.black.withValues(alpha: .66)
        ..strokeWidth = steel.strokeWidth + 5
        ..strokeCap = StrokeCap.round;
      for (final x in <double>[left, right]) {
        canvas.drawLine(Offset(x, top), Offset(x, bottom), shadow);
        canvas.drawLine(Offset(x, top), Offset(x, bottom), steel);
      }
      canvas.drawLine(Offset(left, top), Offset(right, top), shadow);
      canvas.drawLine(Offset(left, top), Offset(right, top), steel);
      for (var i = 0; i < 5 + tier.clamp(1, 4); i++) {
        final y = top + 48 + i * 36;
        for (final x in <double>[left, right]) {
          canvas.drawCircle(
            Offset(x, y),
            3.2,
            Paint()..color = const Color(0xFF202824),
          );
        }
      }
      final hookPaint = Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: .88)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(left - 3, size.height * .57),
        Offset(left + 24, size.height * .57),
        hookPaint,
      );
      canvas.drawLine(
        Offset(right - 24, size.height * .57),
        Offset(right + 3, size.height * .57),
        hookPaint,
      );
    });
  }

  void _drawDumbbells(Canvas canvas, Size size, int tier) {
    if (tier < 1) return;
    _item(canvas, size, GymUpgradeType.dumbbellRack, () {
      final start = Offset(size.width * .055, size.height * .73);
      final end = Offset(size.width * .36, size.height * .73);
      final frame = Paint()
        ..color = const Color(0xFF9EAAA4).withValues(alpha: .90)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Colors.black.withValues(alpha: .72)
          ..strokeWidth = 13,
      );
      canvas.drawLine(start, end, frame);
      canvas.drawLine(start.translate(14, 0), start.translate(3, 80), frame);
      canvas.drawLine(end.translate(-14, 0), end.translate(-3, 80), frame);
      final count = (3 + tier).clamp(4, 8).toInt();
      for (var i = 0; i < count; i++) {
        final x =
            start.dx +
            20 +
            i * ((end.dx - start.dx - 40) / math.max(1, count - 1));
        final y = start.dy - 14 - (i.isOdd ? 4 : 0);
        final metal = Paint()
          ..color = i == count - 1
              ? const Color(0xFFFFC107)
              : const Color(0xFFD8E0DC)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(x - 11, y), Offset(x + 11, y), metal);
        canvas.drawLine(
          Offset(x - 10, y - 7),
          Offset(x - 10, y + 7),
          metal..strokeWidth = 7,
        );
        canvas.drawLine(Offset(x + 10, y - 7), Offset(x + 10, y + 7), metal);
      }
    });
  }

  void _drawPlates(Canvas canvas, Size size, int tier) {
    if (tier < 1) return;
    _item(canvas, size, GymUpgradeType.weightPlates, () {
      final center = Offset(size.width * .84, size.height * .79);
      final stand = Paint()
        ..color = const Color(0xFFB8C3BE)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center.translate(0, -76), center.translate(0, 42), stand);
      canvas.drawLine(
        center.translate(-38, 42),
        center.translate(38, 42),
        stand,
      );
      final count = (2 + tier).clamp(3, 7).toInt();
      const plateColors = <Color>[
        Color(0xFFE53935),
        Color(0xFF1E88E5),
        Color(0xFFFFC107),
        Color(0xFF43A047),
      ];
      for (var i = 0; i < count; i++) {
        final point = center.translate((i - count / 2) * 7, -45 + (i % 2) * 30);
        final radius = 18.0 + (i % 3) * 4;
        canvas.drawCircle(
          point,
          radius + 3,
          Paint()..color = Colors.black.withValues(alpha: .65),
        );
        canvas.drawCircle(
          point,
          radius,
          Paint()
            ..color = plateColors[i % plateColors.length].withValues(
              alpha: .88,
            ),
        );
        canvas.drawCircle(point, 5, Paint()..color = const Color(0xFF151A17));
      }
    });
  }

  void _drawNeon(Canvas canvas, Size size, int tier) {
    if (tier < 1) return;
    _item(canvas, size, GymUpgradeType.neonLights, () {
      final center = Offset(size.width * .50, size.height * .135);
      final width = size.width * (.25 + .025 * tier.clamp(1, 5).toDouble());
      final glow = Paint()
        ..color = const Color(0xFF2EFF88).withValues(alpha: .38)
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      final tube = Paint()
        ..color = const Color(0xFFB9FFD5).withValues(alpha: .96)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      for (final paint in <Paint>[glow, tube]) {
        canvas.drawLine(
          center.translate(-width, 0),
          center.translate(-32, 0),
          paint,
        );
        canvas.drawLine(
          center.translate(32, 0),
          center.translate(width, 0),
          paint,
        );
      }
      final bolt = Path()
        ..moveTo(center.dx + 10, center.dy - 32)
        ..lineTo(center.dx - 17, center.dy + 2)
        ..lineTo(center.dx + 1, center.dy + 2)
        ..lineTo(center.dx - 11, center.dy + 34)
        ..lineTo(center.dx + 24, center.dy - 8)
        ..lineTo(center.dx + 5, center.dy - 8)
        ..close();
      canvas.drawPath(bolt, glow);
      canvas.drawPath(bolt, Paint()..color = const Color(0xFFB9FFD5));
    });
  }

  void _drawBanner(Canvas canvas, Size size, int tier) {
    if (tier < 1) return;
    _item(canvas, size, GymUpgradeType.banner, () {
      final rect = Rect.fromLTWH(
        size.width * .69,
        size.height * .17,
        size.width * .22,
        size.height * .17,
      );
      final banner = Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.bottom - 18)
        ..lineTo(rect.center.dx, rect.bottom)
        ..lineTo(rect.left, rect.bottom - 18)
        ..close();
      canvas.drawPath(
        banner,
        Paint()..color = const Color(0xFF4A0D13).withValues(alpha: .92),
      );
      canvas.drawPath(
        banner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFFFC107).withValues(alpha: .94),
      );
      canvas.drawCircle(
        rect.center.translate(0, -7),
        22 + tier.clamp(1, 4).toDouble() * 2,
        Paint()..color = const Color(0xFFFFC107).withValues(alpha: .88),
      );
      canvas.drawPath(
        Path()
          ..moveTo(rect.center.dx, rect.center.dy - 24)
          ..lineTo(rect.center.dx + 9, rect.center.dy - 5)
          ..lineTo(rect.center.dx + 30, rect.center.dy - 2)
          ..lineTo(rect.center.dx + 14, rect.center.dy + 12)
          ..lineTo(rect.center.dx + 19, rect.center.dy + 32)
          ..lineTo(rect.center.dx, rect.center.dy + 20)
          ..lineTo(rect.center.dx - 19, rect.center.dy + 32)
          ..lineTo(rect.center.dx - 14, rect.center.dy + 12)
          ..lineTo(rect.center.dx - 30, rect.center.dy - 2)
          ..lineTo(rect.center.dx - 9, rect.center.dy - 5)
          ..close(),
        Paint()..color = const Color(0xFF5A2500),
      );
    });
  }

  void _drawSpotlights(Canvas canvas, Size size, int tier) {
    if (tier < 1) return;
    _item(canvas, size, GymUpgradeType.spotlights, () {
      final count = (2 + tier).clamp(3, 6).toInt();
      for (var i = 0; i < count; i++) {
        final x = size.width * (.18 + i * (.64 / math.max(1, count - 1)));
        final target = Offset(
          size.width * (.36 + (i.isEven ? .08 : -.08)),
          size.height * .69,
        );
        final cone = Path()
          ..moveTo(x - 9, 0)
          ..lineTo(target.dx - 62, target.dy)
          ..lineTo(target.dx + 62, target.dy)
          ..lineTo(x + 9, 0)
          ..close();
        canvas.drawPath(
          cone,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                const Color(0xFFFFF4D0).withValues(alpha: .20),
                const Color(0xFFFFC107).withValues(alpha: .035),
                Colors.transparent,
              ],
            ).createShader(Rect.fromLTWH(x - 90, 0, 180, target.dy)),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 14, 0, 28, 18),
            const Radius.circular(5),
          ),
          Paint()..color = const Color(0xFF303834),
        );
      }
    });
  }

  void _drawSpeakers(Canvas canvas, Size size, int tier) {
    if (tier < 1) return;
    _item(canvas, size, GymUpgradeType.speakers, () {
      for (final leftSide in <bool>[true, false]) {
        final x = leftSide ? size.width * .035 : size.width * .86;
        final rect = Rect.fromLTWH(
          x,
          size.height * .36,
          size.width * .105,
          size.height * .20,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(9)),
          Paint()..color = const Color(0xFF101613).withValues(alpha: .96),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(9)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = const Color(0xFF2EFF88).withValues(alpha: .55),
        );
        for (final offset in <double>[.34, .70]) {
          final point = Offset(rect.center.dx, rect.top + rect.height * offset);
          canvas.drawCircle(
            point,
            17 + tier.clamp(1, 4).toDouble() * 2,
            Paint()..color = Colors.black,
          );
          canvas.drawCircle(
            point,
            13 + tier.clamp(1, 4).toDouble() * 2,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = const Color(0xFF2EFF88).withValues(alpha: .72),
          );
        }
      }
    });
  }

  void _drawPlaque(Canvas canvas, Size size, int tier) {
    if (tier < 1) return;
    _item(canvas, size, GymUpgradeType.championPlaque, () {
      final rect = Rect.fromLTWH(
        size.width * .075,
        size.height * .17,
        size.width * .19,
        size.height * .13,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(7)),
        Paint()..color = const Color(0xFF4B2F04).withValues(alpha: .95),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(7)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xFFFFC107),
      );
      final medal = rect.center.translate(0, -5);
      canvas.drawCircle(
        medal,
        22 + tier.clamp(1, 4).toDouble() * 2,
        Paint()..color = const Color(0xFFFFC107),
      );
      canvas.drawCircle(medal, 12, Paint()..color = const Color(0xFFFFF1A8));
      canvas.drawRect(
        Rect.fromCenter(
          center: rect.center.translate(0, 38),
          width: rect.width * .58,
          height: 7,
        ),
        Paint()..color = const Color(0xFFFFD54F).withValues(alpha: .82),
      );
    });
  }

  @override
  bool shouldRepaint(_GymUpgradePainter oldDelegate) {
    return oldDelegate.tiers.toString() != tiers.toString() ||
        oldDelegate.highlightType != highlightType ||
        oldDelegate.reveal != reveal;
  }
}

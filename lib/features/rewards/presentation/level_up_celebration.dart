import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../armory/domain/rat_item.dart';
import '../../character/domain/rat_appearance.dart';
import '../../character/presentation/gymrat_character.dart';
import '../../profile/domain/training_profile.dart';
import '../domain/gym_upgrade.dart';
import 'rpg_flame_painter.dart';
import 'volumetric_explosion.dart';
import 'volumetric_fire.dart';

class LevelUpCelebration extends StatefulWidget {
  const LevelUpCelebration({
    super.key,
    required this.previousLevel,
    required this.newLevel,
    required this.isEvolution,
    required this.gender,
    required this.upgrade,
    this.appearanceId = RatAppearanceCatalog.baseId,
    this.characterView = RatCharacterView.front,
    this.ratItem,
  });

  static const duration = Duration(milliseconds: 4700);
  static const evolutionDuration = Duration(milliseconds: 5600);

  final int previousLevel;
  final int newLevel;
  final bool isEvolution;
  final RatGender gender;
  final GymUpgrade upgrade;
  final String appearanceId;
  final RatCharacterView characterView;
  final RatItem? ratItem;

  Duration get playDuration => isEvolution ? evolutionDuration : duration;

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Timer> _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.playDuration,
    )..forward();
    HapticFeedback.heavyImpact();
    _timers.add(
      Timer(const Duration(milliseconds: 220), HapticFeedback.selectionClick),
    );
    _timers.add(
      Timer(const Duration(milliseconds: 500), HapticFeedback.vibrate),
    );
    _timers.add(
      Timer(const Duration(milliseconds: 900), HapticFeedback.mediumImpact),
    );
    _timers.add(
      Timer(const Duration(milliseconds: 1450), HapticFeedback.heavyImpact),
    );
    _timers.add(
      Timer(const Duration(milliseconds: 2500), HapticFeedback.vibrate),
    );
    _timers.add(
      Timer(const Duration(milliseconds: 3450), HapticFeedback.mediumImpact),
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

  double _phase(double value, double start, double end, Curve curve) {
    final amount = ((value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(amount.toDouble());
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
    final charge = _phase(p, .02, .34, Curves.easeInOutCubic);
    final morph = _phase(p, .20, .60, Curves.easeInOutBack);
    final slam = _phase(p, .54, .73, Curves.elasticOut);
    final upgrade = _phase(p, .72, .91, Curves.easeOutBack);
    final slamOpacity = ((p - .54) / .19).clamp(0.0, 1.0).toDouble();
    final upgradeOpacity = ((p - .72) / .19).clamp(0.0, 1.0).toDouble();
    final explosion = _phase(p, .47, .73, Curves.easeOutQuart);
    final silhouetteFade = p < .67
        ? 1.0
        : 1 - ((p - .67) / .16).clamp(0.0, 1.0).toDouble();
    final fade = p < .95
        ? 1.0
        : 1 - ((p - .95) / .05).clamp(0.0, 1.0).toDouble();
    final shake = p > .18 && p < .61
        ? math.sin(p * 210) * (1 - (p - .18) / .43) * 12
        : 0.0;
    final camera = 1 + math.sin(explosion * math.pi) * .055;
    final scaleX = .82 + morph * (widget.isEvolution ? .42 : .30);
    final scaleY = .90 + morph * (widget.isEvolution ? .25 : .17);
    final flash = p > .48 && p < .60
        ? math.sin((p - .48) / .12 * math.pi) * .92
        : 0.0;
    final goldFlash = p > .40 && p < .72
        ? math.sin((p - .40) / .32 * math.pi).abs() * .30
        : 0.0;
    final evolutionFlash = widget.isEvolution && p > .56 && p < .78
        ? math.sin((p - .56) / .22 * math.pi).abs() * .24
        : 0.0;

    return Opacity(
      opacity: fade,
      child: Transform.scale(
        scale: camera,
        child: Transform.translate(
          offset: Offset(shake, shake * .28),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _background(p, charge),
              CustomPaint(
                painter: _LevelEnergyPainter(
                  progress: p,
                  evolution: widget.isEvolution,
                ),
              ),
              VolumetricExplosion(
                progress: p,
                start: .43,
                end: .75,
                alignment: const Alignment(0, -.04),
                scale: widget.isEvolution ? 1.42 : 1.12,
              ),
              VolumetricFire(
                progress: p,
                intensity: widget.isEvolution ? 1.18 : 1,
              ),
              RepaintBoundary(
                child: CustomPaint(
                  painter: RpgFlamePainter(
                    progress: p,
                    intensity: widget.isEvolution ? 1.45 : 1.08,
                    primary: const Color(0xFFFF6D00),
                    secondary: widget.isEvolution
                        ? const Color(0xFFB45CFF)
                        : GymRatColors.gold,
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _stage(
                      context,
                      constraints,
                      charge: charge,
                      slam: slam,
                      upgrade: upgrade,
                      slamOpacity: slamOpacity,
                      upgradeOpacity: upgradeOpacity,
                      silhouetteFade: silhouetteFade,
                      scaleX: scaleX,
                      scaleY: scaleY,
                    );
                  },
                ),
              ),
              IgnorePointer(
                child: ColoredBox(
                  color: const Color(0xFFFF8F00).withValues(alpha: goldFlash),
                ),
              ),
              IgnorePointer(
                child: ColoredBox(
                  color: const Color(0xFF8A4DFF)
                      .withValues(alpha: evolutionFlash),
                ),
              ),
              IgnorePointer(
                child: ColoredBox(
                  color: Colors.white.withValues(
                    alpha: flash.clamp(0.0, 1.0).toDouble(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _background(double p, double charge) {
    final heat = math.sin((p.clamp(0.0, .72) / .72) * math.pi).abs();
    final evolutionColor = widget.isEvolution
        ? const Color(0xFF5A189A)
        : const Color(0xFF063D24);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, .02),
          radius: .80,
          colors: <Color>[
            Color.lerp(
              const Color(0xFF5A2500),
              const Color(0xFFFFB300),
              heat,
            )!.withValues(alpha: .32 + .38 * charge),
            Color.lerp(evolutionColor, const Color(0xFF5E3600), charge)!,
            const Color(0xFF07100B),
            GymRatColors.black,
          ],
          stops: const <double>[0, .30, .68, 1],
        ),
      ),
    );
  }

  Widget _stage(
    BuildContext context,
    BoxConstraints constraints, {
    required double charge,
    required double slam,
    required double upgrade,
    required double slamOpacity,
    required double upgradeOpacity,
    required double silhouetteFade,
    required double scaleX,
    required double scaleY,
  }) {
    final ratHeight = (constraints.maxHeight * .57)
        .clamp(330.0, 520.0)
        .toDouble();
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Align(
          alignment: const Alignment(0, -.02),
          child: SizedBox.square(
            dimension: (constraints.maxWidth * .92)
                .clamp(300.0, 460.0)
                .toDouble(),
            child: CustomPaint(
              painter: _LevelSealPainter(
                charge: charge,
                reveal: slamOpacity,
                evolution: widget.isEvolution,
              ),
            ),
          ),
        ),
        Positioned(
          top: constraints.maxHeight * .055,
          left: 16,
          right: 16,
          child: Opacity(
            opacity: 1 - slamOpacity,
            child: Text(
              context.tr.t('powerSurging'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GymRatColors.gold.withValues(alpha: .45 + .55 * charge),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -.02),
          child: Opacity(
            opacity: silhouetteFade,
            child: Transform(
              transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: ratHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Opacity(
                      opacity: .28 + .62 * charge,
                      child: _silhouette(
                        GymRatColors.gold,
                        blur: 22 - 10 * charge,
                      ),
                    ),
                    Transform.scale(
                      scale: .985,
                      child: _silhouette(const Color(0xFFFFE082), blur: 7),
                    ),
                    Transform.scale(
                      scale: .96,
                      child: _silhouette(Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -.08),
          child: Opacity(
            opacity: slamOpacity,
            child: Transform.scale(
              scale: .18 + slam * .82,
              child: _levelBadge(context),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, .88),
          child: Opacity(
            opacity: upgradeOpacity,
            child: Transform.translate(
              offset: Offset(0, 45 * (1 - upgrade)),
              child: _upgradeCard(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _silhouette(Color color, {double blur = 0}) {
    final image = ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: Image.asset(
        GymRatCharacter.assetFor(
          gender: widget.gender,
          view: widget.characterView,
          level: widget.newLevel,
          appearanceId: widget.appearanceId,
        ),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
    if (blur <= 0) return image;
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: image,
    );
  }

  Widget _levelBadge(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          context.tr.t('levelUp'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 43,
            height: .88,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            shadows: <Shadow>[Shadow(color: GymRatColors.gold, blurRadius: 32)],
          ),
        ),
        const SizedBox(height: 15),
        Container(
          width: 154,
          height: 154,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: <Color>[
                Colors.white,
                Color(0xFFFFE082),
                GymRatColors.gold,
                Color(0xFFFF8F00),
              ],
              stops: <double>[0, .28, .72, 1],
            ),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: GymRatColors.gold.withValues(alpha: .72),
                blurRadius: 90,
                spreadRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                context.tr.t('level'),
                style: const TextStyle(
                  color: GymRatColors.goldDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${widget.newLevel}',
                style: const TextStyle(
                  color: GymRatColors.black,
                  fontSize: 72,
                  height: .92,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          '${context.tr.t('level')} ${widget.previousLevel}'
          '  →  ${context.tr.t('level')} ${widget.newLevel}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (widget.isEvolution) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            context.tr.t('evolutionUnlocked'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GymRatColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _upgradeCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(15, 12, 18, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151205).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GymRatColors.gold.withValues(alpha: .72),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: GymRatColors.gold.withValues(alpha: .25),
            blurRadius: 34,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GymRatColors.gold.withValues(alpha: .15),
            ),
            child: Icon(
              _upgradeIcon(widget.upgrade.type),
              color: GymRatColors.gold,
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${context.tr.t('gymUpgrade')} · ${context.tr.t('unlocked')}',
                  style: const TextStyle(
                    color: GymRatColors.gold,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr.t(widget.upgrade.nameKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (widget.ratItem case final item?) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+ ${context.tr.t('ratItemUnlocked')}: '
                    '${context.tr.t(item.nameKey)}'
                    '${item.slot == RatItemSlot.collectible ? ' ${item.unlockLevel}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GymRatColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _upgradeIcon(GymUpgradeType type) {
    return switch (type) {
      GymUpgradeType.dumbbellRack => Icons.fitness_center_rounded,
      GymUpgradeType.neonLights => Icons.bolt_rounded,
      GymUpgradeType.weightPlates => Icons.album_rounded,
      GymUpgradeType.powerRack => Icons.view_column_rounded,
      GymUpgradeType.liftingPlatform => Icons.crop_square_rounded,
      GymUpgradeType.banner => Icons.flag_rounded,
      GymUpgradeType.spotlights => Icons.lightbulb_rounded,
      GymUpgradeType.speakers => Icons.speaker_rounded,
      GymUpgradeType.championPlaque => Icons.workspace_premium_rounded,
      GymUpgradeType.cardio => Icons.directions_run_rounded,
      GymUpgradeType.recovery => Icons.health_and_safety_rounded,
      GymUpgradeType.strongman => Icons.sports_martial_arts_rounded,
      GymUpgradeType.architecture => Icons.account_balance_rounded,
    };
  }
}

class _LevelSealPainter extends CustomPainter {
  const _LevelSealPainter({
    required this.charge,
    required this.reveal,
    required this.evolution,
  });

  final double charge;
  final double reveal;
  final bool evolution;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * (.31 + .055 * charge);
    final opacity = (.22 + .68 * charge) * (1 - reveal * .30);
    final accent = evolution ? const Color(0xFF9B5CFF) : GymRatColors.gold;

    canvas.drawCircle(
      center,
      radius * .87,
      Paint()
        ..color = const Color(0xFF060603).withValues(alpha: .72)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 19
        ..color = accent.withValues(alpha: opacity * .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..color = GymRatColors.gold.withValues(alpha: opacity),
    );
    canvas.drawCircle(
      center,
      radius * .84,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFFFE082).withValues(alpha: opacity * .62),
    );

    const tickCount = 36;
    for (var index = 0; index < tickCount; index++) {
      final angle = index / tickCount * math.pi * 2 - math.pi / 2;
      final major = index % 3 == 0;
      final innerRadius = radius * (major ? .91 : .95);
      final outerRadius = radius * (major ? 1.08 : 1.03);
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * innerRadius,
        center + direction * outerRadius,
        Paint()
          ..strokeWidth = major ? 2.2 : 1
          ..strokeCap = StrokeCap.round
          ..color = (major ? GymRatColors.gold : const Color(0xFFFFE082))
              .withValues(alpha: opacity * (major ? .90 : .48)),
      );
    }

    final chevronPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFFE082).withValues(alpha: opacity * .82);
    for (final side in <double>[-1, 1]) {
      final x = center.dx + side * radius * .68;
      final y = center.dy + radius * .67;
      final path = Path()
        ..moveTo(x - side * 12, y - 8)
        ..lineTo(x, y)
        ..lineTo(x - side * 12, y + 8);
      canvas.drawPath(path, chevronPaint);
    }
  }

  @override
  bool shouldRepaint(_LevelSealPainter oldDelegate) {
    return oldDelegate.charge != charge ||
        oldDelegate.reveal != reveal ||
        oldDelegate.evolution != evolution;
  }
}

class _LevelEnergyPainter extends CustomPainter {
  const _LevelEnergyPainter({required this.progress, required this.evolution});

  final double progress;
  final bool evolution;

  double _part(double start, double end) {
    return ((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble();
  }

  double _noise(int value) {
    final raw = math.sin(value * 12.9898 + 78.233) * 43758.5453;
    return raw - raw.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .48);
    final charge = Curves.easeInCubic.transform(_part(.02, .50));
    final blast = Curves.easeOutQuart.transform(_part(.44, .82));
    final echo = Curves.easeOutCubic.transform(_part(.56, .94));
    final chargeFade = (1 - _part(.42, .68)).clamp(0.0, 1.0).toDouble();
    final blastEnergy = math.sin(blast * math.pi).abs();
    final echoEnergy = math.sin(echo * math.pi).abs();
    final colors = evolution
        ? const <Color>[
            Colors.white,
            Color(0xFFFFF3B0),
            GymRatColors.gold,
            Color(0xFFFF8F00),
            Color(0xFF9B5CFF),
            Color(0xFF2EFF88),
          ]
        : const <Color>[
            Colors.white,
            Color(0xFFFFF3B0),
            GymRatColors.gold,
            Color(0xFFFF8F00),
            Color(0xFF2EFF88),
          ];
    final chargeRayCount = evolution ? 34 : 26;

    canvas.drawCircle(
      center,
      size.shortestSide * (.08 + .25 * charge + .22 * blast),
      Paint()
        ..color = colors[evolution ? 4 : 2].withValues(
          alpha: (.20 * chargeFade + .42 * blastEnergy)
              .clamp(0.0, 1.0)
              .toDouble(),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 38),
    );

    for (var i = 0; i < chargeRayCount; i++) {
      final seed = _noise(i * 37 + 5);
      final angle =
          (i / chargeRayCount + (seed - .5) * .055) * math.pi * 2 +
          progress * (.34 + seed * .36);
      final inner = size.shortestSide * (.14 + .16 * charge);
      final outer = size.shortestSide * (.29 + .18 * charge);
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * inner,
        center + direction * outer,
        Paint()
          ..color = colors[i % colors.length].withValues(
            alpha: (charge * chargeFade * (.26 + seed * .34))
                .clamp(0.0, 1.0)
                .toDouble(),
          )
          ..strokeWidth = 1.2 + (i % 5) * .72
          ..strokeCap = StrokeCap.round,
      );
    }

    final explosionRays = evolution ? 40 : 32;
    for (var i = 0; i < explosionRays; i++) {
      final seed = _noise(i * 53 + 13);
      final angle = (i / explosionRays + (seed - .5) * .065) * math.pi * 2;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final length =
          size.shortestSide * (.12 + .76 * blast) * (.42 + seed * .58);
      canvas.drawLine(
        center + direction * length * .12,
        center + direction * length,
        Paint()
          ..color = colors[i % colors.length].withValues(
            alpha: blastEnergy * (.20 + seed * .34),
          )
          ..strokeWidth = .8 + seed * 2.6
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var ring = 0; ring < 2; ring++) {
      final value = _part(.44 + ring * .065, .73 + ring * .085);
      final radius = size.shortestSide * (.07 + .70 * value);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * (1.12 + ring * .13),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 * (1 - value) + .8
          ..color = colors[(ring + 1) % colors.length].withValues(
            alpha: (1 - value) * .46,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.3),
      );
    }

    final particleCount = evolution ? 90 : 70;
    for (var i = 0; i < particleCount; i++) {
      final seed = _noise(i * 67 + 23);
      final angle = (i / particleCount + (seed - .5) * .08) * math.pi * 2;
      final distance =
          size.shortestSide * (.08 + .80 * blast) * (.44 + seed * .56);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(
        point,
        1.0 + seed * 3.6,
        Paint()
          ..color = colors[i % colors.length].withValues(
            alpha: blastEnergy * (.36 + seed * .48),
          ),
      );
    }

    final shardCount = evolution ? 36 : 28;
    for (var i = 0; i < shardCount; i++) {
      final seed = _noise(i * 89 + 31);
      final angle =
          (i / shardCount + (seed - .5) * .085) * math.pi * 2 - progress * .7;
      final distance =
          size.shortestSide * (.12 + .72 * echo) * (.50 + seed * .48);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle + echo * 5);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 6 + seed * 13,
          height: 1.5 + seed * 2.5,
        ),
        Paint()
          ..color = colors[(i + 2) % colors.length].withValues(
            alpha: echoEnergy * (.36 + seed * .48),
          ),
      );
      canvas.restore();
    }

    if (progress > .14 && progress < .72) {
      final energy = math.sin(_part(.14, .72) * math.pi).abs();
      final boltCount = evolution ? 8 : 6;
      for (var bolt = 0; bolt < boltCount; bolt++) {
        final seed = _noise(bolt * 101 + 41);
        final angle =
            (bolt / boltCount + seed * .11) * math.pi * 2 + progress * .55;
        final path = Path()..moveTo(center.dx, center.dy);
        for (var step = 1; step <= 7; step++) {
          final distance = size.shortestSide * .052 * step;
          final side = (step.isEven ? 1 : -1) * (4.0 + seed * 9);
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
            ..strokeWidth = 1.2 + seed * 2.0
            ..color = colors[bolt % colors.length].withValues(
              alpha: energy * (.35 + seed * .38),
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LevelEnergyPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.evolution != evolution;
  }
}

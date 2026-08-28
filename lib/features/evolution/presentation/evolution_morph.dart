import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/gymrat_assets.dart';
import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../domain/evolution_milestones.dart';
import 'evolution_energy_painter.dart';

class EvolutionMorph extends StatefulWidget {
  const EvolutionMorph({
    super.key,
    required this.previousLevel,
    required this.newLevel,
    required this.duration,
    required this.onComplete,
  });

  final int previousLevel;
  final int newLevel;
  final Duration duration;
  final VoidCallback onComplete;

  @override
  State<EvolutionMorph> createState() => _EvolutionMorphState();
}

class _EvolutionMorphState extends State<EvolutionMorph>
    with SingleTickerProviderStateMixin {
  static const int _cacheHeight = 1000;

  late final AnimationController _controller;
  final List<Timer> _hapticTimers = <Timer>[];
  bool _started = false;

  String get _sourceAsset => GymRatAssets.maleForLevel(
    EvolutionMilestones.previousStageFor(widget.newLevel),
  );

  String get _targetAsset => GymRatAssets.maleForLevel(widget.newLevel);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _prepareAndStart();
  }

  Future<void> _prepareAndStart() async {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.duration = const Duration(milliseconds: 900);
    }
    await Future.wait(<Future<void>>[
      precacheImage(
        ResizeImage(AssetImage(_sourceAsset), height: _cacheHeight),
        context,
      ),
      precacheImage(
        ResizeImage(AssetImage(_targetAsset), height: _cacheHeight),
        context,
      ),
      precacheImage(
        AssetImage(GymRatAssets.gymForLevel(widget.previousLevel)),
        context,
      ),
      precacheImage(
        AssetImage(GymRatAssets.gymForLevel(widget.newLevel)),
        context,
      ),
    ]);
    if (!mounted) return;
    if (reduceMotion) {
      HapticFeedback.mediumImpact();
    } else {
      _scheduleHaptics();
    }
    await _controller.forward(from: 0);
    if (mounted) widget.onComplete();
  }

  void _scheduleHaptics() {
    HapticFeedback.heavyImpact();
    _hapticTimers.add(
      Timer(
        const Duration(milliseconds: 320),
        () => HapticFeedback.selectionClick(),
      ),
    );
    _hapticTimers.add(
      Timer(
        const Duration(milliseconds: 760),
        () => HapticFeedback.mediumImpact(),
      ),
    );
    _hapticTimers.add(
      Timer(const Duration(milliseconds: 1280), () => HapticFeedback.vibrate()),
    );
    _hapticTimers.add(
      Timer(
        const Duration(milliseconds: 2050),
        () => HapticFeedback.heavyImpact(),
      ),
    );
    _hapticTimers.add(
      Timer(const Duration(milliseconds: 2860), () => HapticFeedback.vibrate()),
    );
    _hapticTimers.add(
      Timer(
        const Duration(milliseconds: 3340),
        () => HapticFeedback.heavyImpact(),
      ),
    );
    _hapticTimers.add(
      Timer(
        const Duration(milliseconds: 4680),
        () => HapticFeedback.mediumImpact(),
      ),
    );
  }

  double _phase(double value, double start, double end, Curve curve) {
    final amount = ((value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(amount.toDouble());
  }

  @override
  void dispose() {
    for (final timer in _hapticTimers) {
      timer.cancel();
    }
    _controller.dispose();
    super.dispose();
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
    final charge = _phase(p, .03, .43, Curves.easeInOutCubic);
    final morph = _phase(p, .20, .61, Curves.easeInOutBack);
    final reveal = _phase(p, .55, .76, Curves.easeOutCubic);
    final settle = _phase(p, .69, .92, Curves.elasticOut);
    final textReveal = _phase(p, .69, .86, Curves.easeOutBack);
    final textOpacity = textReveal.clamp(0.0, 1.0).toDouble();
    final sourceFade = 1 - _phase(p, .24, .47, Curves.easeInCubic);
    final silhouetteFade = 1 - _phase(p, .60, .78, Curves.easeInCubic);
    final blast = _phase(p, .44, .69, Curves.easeOutQuart);
    final intensity = EvolutionMilestones.intensityForLevel(widget.newLevel);
    final flash = p > .48 && p < .62
        ? math.sin((p - .48) / .14 * math.pi).abs()
        : 0.0;
    final goldFlash = p > .38 && p < .74
        ? math.sin((p - .38) / .36 * math.pi).abs()
        : 0.0;
    final shake = p > .17 && p < .69
        ? math.sin(p * 250) * (1 - _phase(p, .17, .69, Curves.easeOut)) * 13
        : 0.0;
    final cameraPunch = 1 + math.sin(blast * math.pi) * .075;
    final finalFade = p < .97
        ? 1.0
        : 1 - ((p - .97) / .03).clamp(0.0, 1.0).toDouble();

    return Opacity(
      opacity: finalFade,
      child: Transform.scale(
        scale: cameraPunch,
        child: Transform.translate(
          offset: Offset(shake, shake * .22),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _background(reveal: reveal, charge: charge),
              RepaintBoundary(
                child: CustomPaint(
                  painter: EvolutionEnergyPainter(
                    progress: p,
                    intensity: intensity,
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => _stage(
                    context,
                    constraints,
                    progress: p,
                    charge: charge,
                    morph: morph,
                    reveal: reveal,
                    settle: settle,
                    textReveal: textReveal,
                    textOpacity: textOpacity,
                    sourceOpacity: sourceFade,
                    silhouetteOpacity: silhouetteFade,
                    intensity: intensity,
                  ),
                ),
              ),
              IgnorePointer(
                child: ColoredBox(
                  color: GymRatColors.gold.withValues(alpha: goldFlash * .28),
                ),
              ),
              IgnorePointer(
                child: ColoredBox(
                  color: Colors.white.withValues(
                    alpha: (flash * .92).clamp(0.0, 1.0).toDouble(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _background({required double reveal, required double charge}) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          GymRatAssets.gymForLevel(widget.previousLevel),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
        Opacity(
          opacity: reveal,
          child: Image.asset(
            GymRatAssets.gymForLevel(widget.newLevel),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, .08),
              radius: .82,
              colors: <Color>[
                const Color(0xFF4B2700).withValues(alpha: .22 + .24 * charge),
                const Color(0xFF032A18).withValues(alpha: .48),
                GymRatColors.black.withValues(alpha: .92),
              ],
              stops: const <double>[0, .48, 1],
            ),
          ),
        ),
        ColoredBox(color: GymRatColors.black.withValues(alpha: .24)),
      ],
    );
  }

  Widget _stage(
    BuildContext context,
    BoxConstraints constraints, {
    required double progress,
    required double charge,
    required double morph,
    required double reveal,
    required double settle,
    required double textReveal,
    required double textOpacity,
    required double sourceOpacity,
    required double silhouetteOpacity,
    required double intensity,
  }) {
    final height = (constraints.maxHeight * .72).clamp(430.0, 700.0).toDouble();
    final previousStage = EvolutionMilestones.previousStageFor(widget.newLevel);
    final fromX = EvolutionMilestones.widthScaleForLevel(previousStage);
    final fromY = EvolutionMilestones.heightScaleForLevel(previousStage);
    final toX = EvolutionMilestones.widthScaleForLevel(widget.newLevel);
    final toY = EvolutionMilestones.heightScaleForLevel(widget.newLevel);
    final growthBurst =
        math.sin(morph * math.pi).abs() * (.20 + .08 * intensity);
    final pulse = math.sin(progress * math.pi * 28) * charge * .018;
    final morphX = _lerp(fromX, toX, morph) + growthBurst + pulse;
    final morphY = _lerp(fromY, toY, morph) + growthBurst * .42 - pulse * .4;
    final targetPunch = 1 + math.sin(settle * math.pi).abs() * .055;
    final targetX = toX * targetPunch;
    final targetY = toY * (1 + (targetPunch - 1) * .45);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned(
          top: constraints.maxHeight * .035,
          left: 20,
          right: 20,
          child: Opacity(
            opacity: (1 - textOpacity) * (.36 + .64 * charge),
            child: Text(
              context.tr.t('powerSurging'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GymRatColors.gold.withValues(alpha: .58 + .42 * charge),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.2,
                shadows: const <Shadow>[
                  Shadow(color: GymRatColors.gold, blurRadius: 22),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, .17),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Opacity(
                  opacity: sourceOpacity,
                  child: _scaledCharacter(
                    asset: _sourceAsset,
                    scaleX: fromX,
                    scaleY: fromY,
                  ),
                ),
                Opacity(
                  opacity: silhouetteOpacity,
                  child: _morphingSilhouette(
                    scaleX: morphX,
                    scaleY: morphY,
                    charge: charge,
                  ),
                ),
                Opacity(
                  opacity: reveal,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      _scaledCharacter(
                        asset: _targetAsset,
                        scaleX: targetX * 1.018,
                        scaleY: targetY * 1.008,
                        color: GymRatColors.gold,
                        blur: 18 * (1 - reveal) + 5,
                      ),
                      _scaledCharacter(
                        asset: _targetAsset,
                        scaleX: targetX,
                        scaleY: targetY,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, .88),
          child: Opacity(
            opacity: textOpacity,
            child: Transform.translate(
              offset: Offset(0, 36 * (1 - textReveal)),
              child: _resultBadge(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _morphingSilhouette({
    required double scaleX,
    required double scaleY,
    required double charge,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _scaledCharacter(
          asset: _sourceAsset,
          scaleX: scaleX * 1.045,
          scaleY: scaleY * 1.018,
          color: GymRatColors.gold,
          blur: 28 - 14 * charge,
        ),
        _scaledCharacter(
          asset: _sourceAsset,
          scaleX: scaleX * 1.018,
          scaleY: scaleY * 1.008,
          color: const Color(0xFFFFE6A1),
          blur: 7,
        ),
        _scaledCharacter(
          asset: _sourceAsset,
          scaleX: scaleX,
          scaleY: scaleY,
          color: Colors.black,
        ),
      ],
    );
  }

  Widget _scaledCharacter({
    required String asset,
    required double scaleX,
    required double scaleY,
    Color? color,
    double blur = 0,
  }) {
    Widget image = Image.asset(
      asset,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.high,
      cacheHeight: _cacheHeight,
    );
    if (color != null) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: image,
      );
    }
    if (blur > 0) {
      image = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: image,
      );
    }
    return Transform(
      transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
      alignment: Alignment.bottomCenter,
      child: image,
    );
  }

  Widget _resultBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 26),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 15),
      decoration: BoxDecoration(
        color: const Color(0xFF121006).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GymRatColors.gold, width: 1.7),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: GymRatColors.gold.withValues(alpha: .34),
            blurRadius: 46,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
          const SizedBox(height: 5),
          Text(
            '${context.tr.t('level')} ${widget.newLevel}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  double _lerp(double from, double to, double amount) {
    return from + (to - from) * amount;
  }
}

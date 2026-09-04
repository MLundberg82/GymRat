import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../profile/domain/training_profile.dart';
import '../domain/rat_animation_set.dart';
import '../domain/rat_appearance.dart';
import '../domain/rat_character_view.dart';

export '../domain/rat_character_view.dart';

class GymRatCharacter extends StatefulWidget {
  const GymRatCharacter({
    super.key,
    this.height,
    this.level = 1,
    this.gender = RatGender.nonBinary,
    this.view = RatCharacterView.front,
    this.appearanceId = RatAppearanceCatalog.baseId,
    this.enableEmotes = false,
    this.emoteSemanticLabel,
  });

  final double? height;
  final int level;
  final RatGender gender;
  final RatCharacterView view;
  final String appearanceId;
  final bool enableEmotes;
  final String? emoteSemanticLabel;

  static const double displayScale = .70;

  static double breathingScaleX(double progress) =>
      1 + sin(progress.clamp(0.0, 1.0) * pi) * .006;

  static double breathingScaleY(double progress) =>
      1 + sin(progress.clamp(0.0, 1.0) * pi) * .002;

  static double emoteScaleX(double progress) =>
      1 + sin(progress.clamp(0.0, 1.0) * pi) * .025;

  static double emoteScaleY(double progress) =>
      1 - sin(progress.clamp(0.0, 1.0) * pi) * .018;

  static double emoteRotation(double progress) {
    final safe = progress.clamp(0.0, 1.0);
    return sin(safe * pi * 6) * (1 - safe) * .014;
  }

  static double emoteDrop(double progress) =>
      sin(progress.clamp(0.0, 1.0) * pi) * 7;

  static Rect breathingTorsoRect(Size size, RatCharacterView view) {
    final top = size.height * (view == RatCharacterView.front ? .20 : .19);
    final bottom = size.height * (view == RatCharacterView.front ? .48 : .47);
    return Rect.fromLTRB(size.width * .20, top, size.width * .80, bottom);
  }

  static String assetFor({
    required RatGender gender,
    RatCharacterView view = RatCharacterView.front,
    String appearanceId = RatAppearanceCatalog.baseId,
    int level = 1,
  }) => RatAppearanceCatalog.assetFor(
    appearanceId: appearanceId,
    gender: gender,
    view: switch (view) {
      RatCharacterView.front => RatAppearanceView.front,
      RatCharacterView.back => RatAppearanceView.back,
    },
    level: level,
  );

  static bool usesAuthoredSpriteFrames({
    required RatGender gender,
    required RatCharacterView view,
    required int level,
    String appearanceId = RatAppearanceCatalog.baseId,
  }) => RatAnimationCatalog.hasAnyAuthoredMotion(
    gender: gender,
    view: view,
    level: level,
    appearanceId: appearanceId,
  );

  static bool usesAuthoredBreathingFrames({
    required RatGender gender,
    required RatCharacterView view,
    required int level,
    String appearanceId = RatAppearanceCatalog.baseId,
  }) => RatAnimationCatalog.hasAuthoredBreathing(
    gender: gender,
    view: view,
    level: level,
    appearanceId: appearanceId,
  );

  @override
  State<GymRatCharacter> createState() => _GymRatCharacterState();
}

enum _IdleAction { neutral, breathing, blinking, tail, emote }

class _GymRatCharacterState extends State<GymRatCharacter>
    with TickerProviderStateMixin {
  static const int _cacheHeight = 800;

  final Random _random = Random();

  Timer? _breathScheduleTimer;
  Timer? _blinkScheduleTimer;
  Timer? _tailScheduleTimer;
  Timer? _animationTimer;

  _IdleAction _action = _IdleAction.neutral;

  List<String> _activeFrames = <String>[];
  int _frameIndex = 0;

  bool _assetsPrecached = false;
  late final AnimationController _breathingController;
  late final AnimationController _emoteController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _emoteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _scheduleBreath(initial: true);
      _scheduleBlink(initial: true);
      _scheduleTail(initial: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAssets();
  }

  void _precacheAssets() {
    if (_assetsPrecached) return;
    _assetsPrecached = true;

    final allFrames = <String>{
      GymRatCharacter.assetFor(
        gender: widget.gender,
        view: RatCharacterView.front,
        appearanceId: widget.appearanceId,
        level: widget.level,
      ),
      GymRatCharacter.assetFor(
        gender: widget.gender,
        view: RatCharacterView.back,
        appearanceId: widget.appearanceId,
        level: widget.level,
      ),
    };
    allFrames.addAll(_animationSet.allFrames);

    for (final frame in allFrames) {
      precacheImage(
        ResizeImage(AssetImage(frame), height: _cacheHeight),
        context,
      );
    }
  }

  @override
  void didUpdateWidget(covariant GymRatCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gender == widget.gender &&
        oldWidget.view == widget.view &&
        oldWidget.level == widget.level &&
        oldWidget.appearanceId == widget.appearanceId) {
      return;
    }

    _animationTimer?.cancel();
    _breathScheduleTimer?.cancel();
    _blinkScheduleTimer?.cancel();
    _tailScheduleTimer?.cancel();
    _activeFrames = <String>[];
    _frameIndex = 0;
    _action = _IdleAction.neutral;
    _assetsPrecached = false;
    _precacheAssets();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleBreath(initial: true);
      _scheduleBlink(initial: true);
      _scheduleTail(initial: true);
    });
  }

  void _scheduleBreath({bool initial = false}) {
    _breathScheduleTimer?.cancel();

    final delay = initial ? 1000 + _random.nextInt(1000) : _nextBreathPause();

    _breathScheduleTimer = Timer(
      Duration(milliseconds: delay),
      _tryStartBreathing,
    );
  }

  int _nextBreathPause() {
    final roll = _random.nextInt(100);

    if (roll < 15) {
      return 2400 + _random.nextInt(1200);
    }

    if (roll < 40) {
      return 1600 + _random.nextInt(900);
    }

    return 950 + _random.nextInt(800);
  }

  void _tryStartBreathing() {
    if (!mounted) return;

    if (_action != _IdleAction.neutral) {
      _breathScheduleTimer = Timer(
        const Duration(milliseconds: 300),
        _tryStartBreathing,
      );
      return;
    }

    if (!_animationSet.hasAuthoredBreathing) {
      _action = _IdleAction.breathing;
      _breathingController.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        _breathingController.reset();
        _action = _IdleAction.neutral;
        _scheduleBreath();
      });
      return;
    }

    _playAnimation(
      action: _IdleAction.breathing,
      frames: _animationSet.breathing,
      frameDuration: const Duration(milliseconds: 175),
      onComplete: _scheduleBreath,
    );
  }

  void _scheduleBlink({bool initial = false}) {
    _blinkScheduleTimer?.cancel();
    if (!_animationSet.hasAuthoredBlink) return;

    final delay = initial
        ? 2500 + _random.nextInt(3000)
        : 3200 + _random.nextInt(4500);

    _blinkScheduleTimer = Timer(Duration(milliseconds: delay), _tryStartBlink);
  }

  void _tryStartBlink() {
    if (!mounted) return;

    if (_action != _IdleAction.neutral) {
      _blinkScheduleTimer = Timer(
        const Duration(milliseconds: 220),
        _tryStartBlink,
      );
      return;
    }

    final doubleBlink = _random.nextInt(100) < 10;

    if (doubleBlink) {
      _playDoubleBlink();
      return;
    }

    _playAnimation(
      action: _IdleAction.blinking,
      frames: [
        _animationSet.blinking[0],
        _animationSet.blinking[1],
        _animationSet.blinking[2],
        _animationSet.blinking[3],
        _animationSet.blinking[0],
      ],
      frameDuration: const Duration(milliseconds: 45),
      onComplete: _scheduleBlink,
    );
  }

  void _playDoubleBlink() {
    _playAnimation(
      action: _IdleAction.blinking,
      frames: [
        _animationSet.blinking[0],
        _animationSet.blinking[1],
        _animationSet.blinking[2],
        _animationSet.blinking[3],
        _animationSet.blinking[0],
        _animationSet.blinking[0],
        _animationSet.blinking[1],
        _animationSet.blinking[2],
        _animationSet.blinking[3],
        _animationSet.blinking[0],
      ],
      frameDuration: const Duration(milliseconds: 42),
      onComplete: _scheduleBlink,
    );
  }

  void _scheduleTail({bool initial = false}) {
    _tailScheduleTimer?.cancel();
    if (!_animationSet.hasAuthoredTail) return;

    final delay = initial
        ? 3500 + _random.nextInt(3500)
        : 4500 + _random.nextInt(5000);

    _tailScheduleTimer = Timer(Duration(milliseconds: delay), _tryStartTail);
  }

  void _tryStartTail() {
    if (!mounted) return;

    if (_action != _IdleAction.neutral) {
      _tailScheduleTimer = Timer(
        const Duration(milliseconds: 300),
        _tryStartTail,
      );
      return;
    }

    _playAnimation(
      action: _IdleAction.tail,
      frames: _animationSet.tail,
      frameDuration: const Duration(milliseconds: 90),
      onComplete: _scheduleTail,
    );
  }

  void _playAnimation({
    required _IdleAction action,
    required List<String> frames,
    required Duration frameDuration,
    required VoidCallback onComplete,
  }) {
    if (!mounted || frames.isEmpty) return;

    _animationTimer?.cancel();

    setState(() {
      _action = action;
      _activeFrames = frames;
      _frameIndex = 0;
    });

    _animationTimer = Timer.periodic(frameDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextFrame = _frameIndex + 1;

      if (nextFrame >= _activeFrames.length) {
        timer.cancel();

        setState(() {
          _action = _IdleAction.neutral;
          _activeFrames = <String>[];
          _frameIndex = 0;
        });

        onComplete();
        return;
      }

      setState(() {
        _frameIndex = nextFrame;
      });
    });
  }

  String get _currentFrame {
    if (_action == _IdleAction.neutral || _activeFrames.isEmpty) {
      return _identityMaster;
    }

    return _activeFrames[_frameIndex];
  }

  RatAnimationSet get _animationSet => RatAnimationCatalog.forCharacter(
    gender: widget.gender,
    view: widget.view,
    level: widget.level,
    appearanceId: widget.appearanceId,
  );

  String get _identityMaster => _animationSet.neutral;

  void _playFlexEmote() {
    if (!widget.enableEmotes || _emoteController.isAnimating) return;
    HapticFeedback.mediumImpact();
    _emoteController.forward(from: 0);

    final emotes = _animationSet.emotes;
    if (emotes.isEmpty) return;

    final frames = emotes[_random.nextInt(emotes.length)];
    _playAnimation(
      action: _IdleAction.emote,
      frames: frames,
      frameDuration: const Duration(milliseconds: 105),
      onComplete: () {
        _scheduleBreath();
        _scheduleBlink();
        _scheduleTail();
      },
    );
  }

  @override
  void dispose() {
    _breathScheduleTimer?.cancel();
    _blinkScheduleTimer?.cancel();
    _tailScheduleTimer?.cancel();
    _animationTimer?.cancel();
    _breathingController.dispose();
    _emoteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.enableEmotes,
      label: widget.emoteSemanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enableEmotes ? _playFlexEmote : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_breathingController, _emoteController]),
          builder: (context, _) {
            final emote = _emoteController.value;
            return Transform.translate(
              offset: Offset(0, GymRatCharacter.emoteDrop(emote)),
              child: Transform.rotate(
                angle: GymRatCharacter.emoteRotation(emote),
                alignment: Alignment.bottomCenter,
                child: Transform(
                  transform: Matrix4.diagonal3Values(
                    GymRatCharacter.displayScale *
                        GymRatCharacter.emoteScaleX(emote),
                    GymRatCharacter.displayScale *
                        GymRatCharacter.emoteScaleY(emote),
                    1,
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      if (_emoteController.isAnimating)
                        Positioned.fill(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Opacity(
                                opacity: (sin(emote * pi) * .24)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment(0, .05),
                                      radius: .48,
                                      colors: [
                                        Color(0x66FFC107),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              CustomPaint(
                                painter: _PowerStancePainter(progress: emote),
                              ),
                            ],
                          ),
                        ),
                      Image.asset(
                        _currentFrame,
                        height: widget.height,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                        cacheHeight: _cacheHeight,
                        semanticLabel: widget.gender.name,
                      ),
                      if (_action == _IdleAction.breathing &&
                          !_animationSet.hasAuthoredBreathing)
                        Positioned.fill(
                          child: ClipRect(
                            clipper: _BreathingTorsoClipper(view: widget.view),
                            child: Transform.scale(
                              alignment: const Alignment(0, -.26),
                              scaleX: GymRatCharacter.breathingScaleX(
                                _breathingController.value,
                              ),
                              scaleY: GymRatCharacter.breathingScaleY(
                                _breathingController.value,
                              ),
                              child: Image.asset(
                                _identityMaster,
                                height: widget.height,
                                fit: BoxFit.contain,
                                alignment: Alignment.bottomCenter,
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.high,
                                cacheHeight: _cacheHeight,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BreathingTorsoClipper extends CustomClipper<Rect> {
  const _BreathingTorsoClipper({required this.view});

  final RatCharacterView view;

  @override
  Rect getClip(Size size) => GymRatCharacter.breathingTorsoRect(size, view);

  @override
  bool shouldReclip(covariant _BreathingTorsoClipper oldClipper) =>
      oldClipper.view != view;
}

class _PowerStancePainter extends CustomPainter {
  const _PowerStancePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final power = sin(progress.clamp(0.0, 1.0) * pi).clamp(0.0, 1.0);
    if (power <= 0) return;
    final paint = Paint()
      ..color = const Color(0xFFFFC107).withValues(alpha: power * .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height * .91);
    final radius = size.width * (.12 + .24 * progress);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * .10,
      pi * .80,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 1.10,
      pi * .80,
      false,
      paint,
    );
    for (final direction in const <double>[-1, 1]) {
      canvas.drawLine(
        Offset(center.dx + direction * size.width * .16, center.dy - 8),
        Offset(
          center.dx + direction * size.width * (.24 + .07 * progress),
          center.dy - size.height * .10,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PowerStancePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

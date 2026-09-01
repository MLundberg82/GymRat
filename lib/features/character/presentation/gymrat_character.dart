import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/assets/gymrat_assets.dart';
import '../../evolution/domain/evolution_milestones.dart';
import '../../profile/domain/training_profile.dart';
import '../domain/rat_appearance.dart';

enum RatCharacterView { front, back }

class GymRatCharacter extends StatefulWidget {
  const GymRatCharacter({
    super.key,
    this.height,
    this.level = 1,
    this.gender = RatGender.nonBinary,
    this.view = RatCharacterView.front,
    this.appearanceId = RatAppearanceCatalog.baseId,
  });

  final double? height;
  final int level;
  final RatGender gender;
  final RatCharacterView view;
  final String appearanceId;

  static double breathingScaleX(double progress) =>
      1 + sin(progress * pi * 2) * .0025;

  static Rect breathingTorsoRect(Size size, RatCharacterView view) {
    final top = size.height * (view == RatCharacterView.front ? .20 : .19);
    final bottom = size.height * (view == RatCharacterView.front ? .48 : .47);
    return Rect.fromLTRB(0, top, size.width, bottom);
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
  }) =>
      gender == RatGender.male &&
      view == RatCharacterView.front &&
      appearanceId == RatAppearanceCatalog.baseId &&
      RatAppearanceCatalog.approvedStageForLevel(
            appearanceId: appearanceId,
            level: level,
          ) ==
          1;

  @override
  State<GymRatCharacter> createState() => _GymRatCharacterState();
}

enum _IdleAction { neutral, breathing, blinking, tail }

class _GymRatCharacterState extends State<GymRatCharacter>
    with SingleTickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
    if (_usesAuthoredSpriteFrames) {
      allFrames.addAll(GymRatAssets.maleLevel1IdleFrames);
      allFrames.addAll(GymRatAssets.maleLevel1BlinkFrames);
      allFrames.addAll(GymRatAssets.maleLevel1TailFrames);
    }

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
    _blinkScheduleTimer?.cancel();
    _tailScheduleTimer?.cancel();
    _activeFrames = <String>[];
    _frameIndex = 0;
    _action = _IdleAction.neutral;
    _assetsPrecached = false;
    _precacheAssets();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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

    if (!_usesAuthoredSpriteFrames) {
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
      frames: GymRatAssets.maleLevel1IdleFrames,
      frameDuration: const Duration(milliseconds: 110),
      onComplete: _scheduleBreath,
    );
  }

  void _scheduleBlink({bool initial = false}) {
    _blinkScheduleTimer?.cancel();
    if (!_usesAuthoredSpriteFrames) return;

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
        GymRatAssets.maleLevel1BlinkFrames[0],
        GymRatAssets.maleLevel1BlinkFrames[1],
        GymRatAssets.maleLevel1BlinkFrames[2],
        GymRatAssets.maleLevel1BlinkFrames[3],
        GymRatAssets.maleLevel1BlinkFrames[0],
      ],
      frameDuration: const Duration(milliseconds: 45),
      onComplete: _scheduleBlink,
    );
  }

  void _playDoubleBlink() {
    _playAnimation(
      action: _IdleAction.blinking,
      frames: [
        GymRatAssets.maleLevel1BlinkFrames[0],
        GymRatAssets.maleLevel1BlinkFrames[1],
        GymRatAssets.maleLevel1BlinkFrames[2],
        GymRatAssets.maleLevel1BlinkFrames[3],
        GymRatAssets.maleLevel1BlinkFrames[0],
        GymRatAssets.maleLevel1BlinkFrames[0],
        GymRatAssets.maleLevel1BlinkFrames[1],
        GymRatAssets.maleLevel1BlinkFrames[2],
        GymRatAssets.maleLevel1BlinkFrames[3],
        GymRatAssets.maleLevel1BlinkFrames[0],
      ],
      frameDuration: const Duration(milliseconds: 42),
      onComplete: _scheduleBlink,
    );
  }

  void _scheduleTail({bool initial = false}) {
    _tailScheduleTimer?.cancel();
    if (!_usesAuthoredSpriteFrames) return;

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
      frames: GymRatAssets.maleLevel1TailFrames,
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
    if (!_usesAuthoredSpriteFrames) return _identityMaster;
    if (_action == _IdleAction.neutral || _activeFrames.isEmpty) {
      return _identityMaster;
    }

    return _activeFrames[_frameIndex];
  }

  String get _identityMaster => GymRatCharacter.assetFor(
    gender: widget.gender,
    view: widget.view,
    appearanceId: widget.appearanceId,
    level: widget.level,
  );

  bool get _usesAuthoredSpriteFrames =>
      GymRatCharacter.usesAuthoredSpriteFrames(
        gender: widget.gender,
        view: widget.view,
        level: widget.level,
        appearanceId: widget.appearanceId,
      );

  @override
  void dispose() {
    _breathScheduleTimer?.cancel();
    _blinkScheduleTimer?.cancel();
    _tailScheduleTimer?.cancel();
    _animationTimer?.cancel();
    _breathingController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.diagonal3Values(
        EvolutionMilestones.widthScaleForLevel(widget.level),
        EvolutionMilestones.heightScaleForLevel(widget.level),
        1,
      ),
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: _breathingController,
        builder: (context, _) => Stack(
          alignment: Alignment.bottomCenter,
          children: [
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
            if (_action == _IdleAction.breathing && !_usesAuthoredSpriteFrames)
              Positioned.fill(
                child: ClipRect(
                  clipper: _BreathingTorsoClipper(view: widget.view),
                  child: Transform.scale(
                    alignment: const Alignment(0, -.26),
                    scaleX: GymRatCharacter.breathingScaleX(
                      _breathingController.value,
                    ),
                    scaleY: 1,
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

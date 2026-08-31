import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/assets/gymrat_assets.dart';
import '../../armory/domain/rat_item.dart';
import '../../evolution/domain/evolution_milestones.dart';
import '../../profile/domain/training_profile.dart';

class GymRatCharacter extends StatefulWidget {
  const GymRatCharacter({
    super.key,
    this.height,
    this.level = 1,
    this.gender = RatGender.nonBinary,
    this.loadout = const RatLoadout(<RatItemSlot, RatItem>{}),
  });

  final double? height;
  final int level;
  final RatGender gender;
  final RatLoadout loadout;

  @override
  State<GymRatCharacter> createState() => _GymRatCharacterState();
}

enum _IdleAction { neutral, breathing, blinking, tail }

class _GymRatCharacterState extends State<GymRatCharacter> {
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

  @override
  void initState() {
    super.initState();

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

    if (_assetsPrecached) return;
    _assetsPrecached = true;

    final allFrames = <String>{
      GymRatAssets.maleLevel1,
      ...GymRatAssets.maleLevel1IdleFrames,
      ...GymRatAssets.maleLevel1BlinkFrames,
      ...GymRatAssets.maleLevel1TailFrames,
    };

    for (final frame in allFrames) {
      precacheImage(
        ResizeImage(AssetImage(frame), height: _cacheHeight),
        context,
      );
    }
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

    _playAnimation(
      action: _IdleAction.breathing,
      frames: GymRatAssets.maleLevel1IdleFrames,
      frameDuration: const Duration(milliseconds: 110),
      onComplete: _scheduleBreath,
    );
  }

  void _scheduleBlink({bool initial = false}) {
    _blinkScheduleTimer?.cancel();

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
    if (_action == _IdleAction.neutral || _activeFrames.isEmpty) {
      return _identityMaster;
    }

    return _activeFrames[_frameIndex];
  }

  String get _identityMaster => switch (widget.gender) {
    RatGender.male => GymRatAssets.maleLevel1,
    RatGender.female => GymRatAssets.maleLevel1,
    RatGender.nonBinary => GymRatAssets.maleLevel1,
  };

  @override
  void dispose() {
    _breathScheduleTimer?.cancel();
    _blinkScheduleTimer?.cancel();
    _tailScheduleTimer?.cancel();
    _animationTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aura = widget.loadout[RatItemSlot.aura];
    return Transform(
      transform: Matrix4.diagonal3Values(
        EvolutionMilestones.widthScaleForLevel(widget.level),
        EvolutionMilestones.heightScaleForLevel(widget.level),
        1,
      ),
      alignment: Alignment.bottomCenter,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (aura != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, .10),
                    radius: .48,
                    colors: [
                      _itemColor(aura).withValues(alpha: .38),
                      _itemColor(aura).withValues(alpha: .10),
                      Colors.transparent,
                    ],
                  ),
                ),
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
          Positioned.fill(child: _EquipmentOverlay(loadout: widget.loadout)),
        ],
      ),
    );
  }
}

class _EquipmentOverlay extends StatelessWidget {
  const _EquipmentOverlay({required this.loadout});

  final RatLoadout loadout;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      children: [
        if (loadout[RatItemSlot.head] case final item?)
          Align(
            alignment: const Alignment(0, -.82),
            child: _EquipmentBadge(item: item, size: 36),
          ),
        if (loadout[RatItemSlot.neck] case final item?)
          Align(
            alignment: const Alignment(0, -.25),
            child: _EquipmentBadge(item: item, size: 27),
          ),
        if (loadout[RatItemSlot.belt] case final item?)
          Align(
            alignment: const Alignment(0, .30),
            child: _EquipmentBadge(item: item, size: 30),
          ),
      ],
    ),
  );
}

class _EquipmentBadge extends StatelessWidget {
  const _EquipmentBadge({required this.item, required this.size});

  final RatItem item;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [Colors.white, _itemColor(item), Colors.black],
        stops: const [0, .42, 1],
      ),
      border: Border.all(color: _itemColor(item), width: 2),
      boxShadow: [
        BoxShadow(color: _itemColor(item), blurRadius: 13, spreadRadius: 1),
      ],
    ),
    child: Icon(_itemIcon(item), color: Colors.black, size: size * .58),
  );
}

Color _itemColor(RatItem item) {
  if (item.id.contains('void') || item.id.contains('violet')) {
    return const Color(0xFF9B6DFF);
  }
  if (item.id.contains('emerald') || item.id.contains('power')) {
    return const Color(0xFF32D071);
  }
  if (item.id.contains('shadow')) return const Color(0xFF7C8790);
  if (item.id.contains('molten')) return const Color(0xFFFF6D00);
  return const Color(0xFFFFC107);
}

IconData _itemIcon(RatItem item) => switch (item.slot) {
  RatItemSlot.head =>
    item.id.contains('crown')
        ? Icons.workspace_premium_rounded
        : Icons.sports_martial_arts_rounded,
  RatItemSlot.neck => Icons.link_rounded,
  RatItemSlot.belt => Icons.shield_rounded,
  RatItemSlot.aura => Icons.auto_awesome_rounded,
};

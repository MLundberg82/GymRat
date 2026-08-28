import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/gymrat_assets.dart';
import '../../../core/theme/gymrat_colors.dart';

class GymUpgradeLayer extends StatefulWidget {
  const GymUpgradeLayer({
    super.key,
    required this.level,
    this.previousLevel,
    this.animateUnlock = false,
  });

  final int level;
  final int? previousLevel;
  final bool animateUnlock;

  @override
  State<GymUpgradeLayer> createState() => _GymUpgradeLayerState();
}

class _GymUpgradeLayerState extends State<GymUpgradeLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _initialPrepared = false;

  bool get _canAnimate {
    final previous = widget.previousLevel;
    return widget.animateUnlock &&
        previous != null &&
        previous.clamp(1, 50) < widget.level.clamp(1, 50);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
      value: _canAnimate ? 0 : 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_canAnimate && !_initialPrepared) {
      _initialPrepared = true;
      _prepareAndAnimate();
    }
  }

  @override
  void didUpdateWidget(covariant GymUpgradeLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_canAnimate &&
        (oldWidget.level != widget.level ||
            oldWidget.previousLevel != widget.previousLevel)) {
      _prepareAndAnimate();
    } else if (!_canAnimate) {
      _controller.value = 1;
    }
  }

  Future<void> _prepareAndAnimate() async {
    _controller.value = 0;
    await Future.wait(<Future<void>>[
      precacheImage(
        AssetImage(
          GymRatAssets.gymForLevel(widget.previousLevel ?? widget.level),
        ),
        context,
      ),
      precacheImage(
        AssetImage(GymRatAssets.gymForLevel(widget.level)),
        context,
      ),
    ]);
    if (!mounted) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAsset = GymRatAssets.gymForLevel(widget.level);
    final previousAsset = GymRatAssets.gymForLevel(
      widget.previousLevel ?? widget.level,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final reveal = Curves.easeInOutCubic.transform(_controller.value);
        final impact = math.sin(_controller.value * math.pi).abs();
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _GymImage(asset: previousAsset),
            Opacity(
              opacity: reveal,
              child: Transform.scale(
                scale: 1.018 - .018 * reveal,
                child: _GymImage(asset: currentAsset),
              ),
            ),
            if (_canAnimate)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, .25),
                      radius: .82,
                      colors: <Color>[
                        GymRatColors.gold.withValues(alpha: .19 * impact),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GymImage extends StatelessWidget {
  const _GymImage({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    fit: BoxFit.cover,
    alignment: Alignment.center,
    filterQuality: FilterQuality.high,
    gaplessPlayback: true,
  );
}

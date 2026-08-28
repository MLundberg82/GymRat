import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../workout/data/workout_session_store.dart';
import '../../workout/domain/workout_result.dart';
import '../domain/gym_upgrade.dart';
import 'level_up_celebration.dart';
import 'pr_celebration.dart';

enum _RewardPhase { personalBest, xp, levelUp }

class RewardSequence extends StatefulWidget {
  const RewardSequence({
    super.key,
    required this.result,
    required this.onComplete,
  });
  final WorkoutResult result;
  final VoidCallback onComplete;
  @override
  State<RewardSequence> createState() => _RewardSequenceState();
}

class _RewardSequenceState extends State<RewardSequence> {
  static const xpDuration = Duration(milliseconds: 1800),
      phaseGap = Duration(milliseconds: 140);
  _RewardPhase phase = _RewardPhase.xp;
  int prIndex = 0, celebrationLevel = 1;
  bool finished = false;
  @override
  void initState() {
    super.initState();
    phase = widget.result.prs.isEmpty
        ? _RewardPhase.xp
        : _RewardPhase.personalBest;
    celebrationLevel = widget.result.previousLevel + 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runSequence();
    });
  }

  Future<void> runSequence() async {
    if (widget.result.prs.isNotEmpty) {
      for (var index = 0; index < widget.result.prs.length; index++) {
        if (!mounted) return;
        setState(() {
          prIndex = index;
          phase = _RewardPhase.personalBest;
        });
        await Future<void>.delayed(PrCelebration.duration + phaseGap);
      }
    }
    if (!mounted) return;
    setState(() => phase = _RewardPhase.xp);
    await Future<void>.delayed(xpDuration + const Duration(milliseconds: 260));
    if (!mounted) return;
    if (widget.result.leveledUp) {
      const milestones = {5, 10, 15, 20, 30, 40, 50};
      for (
        var level = widget.result.previousLevel + 1;
        level <= widget.result.newLevel;
        level++
      ) {
        if (!mounted) return;
        setState(() {
          celebrationLevel = level;
          phase = _RewardPhase.levelUp;
        });
        await Future<void>.delayed(
          (milestones.contains(level)
                  ? LevelUpCelebration.evolutionDuration
                  : LevelUpCelebration.duration) +
              phaseGap,
        );
      }
    }
    if (!mounted || finished) return;
    finished = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (phase) {
        _RewardPhase.personalBest => PrCelebration(
          key: ValueKey('pr-$prIndex'),
          pr: widget.result.prs[prIndex],
          position: prIndex + 1,
          total: widget.result.prs.length,
        ),
        _RewardPhase.xp => XpRewardStage(
          key: const ValueKey('xp'),
          result: widget.result,
          duration: xpDuration,
        ),
        _RewardPhase.levelUp => LevelUpCelebration(
          key: ValueKey('level-$celebrationLevel'),
          previousLevel: celebrationLevel - 1,
          newLevel: celebrationLevel,
          isEvolution: const {
            5,
            10,
            15,
            20,
            30,
            40,
            50,
          }.contains(celebrationLevel),
          upgrade: GymUpgradeCatalog.forLevel(celebrationLevel),
        ),
      },
    ),
  );
}

class XpRewardStage extends StatefulWidget {
  const XpRewardStage({
    super.key,
    required this.result,
    required this.duration,
  });
  final WorkoutResult result;
  final Duration duration;
  @override
  State<XpRewardStage> createState() => _XpRewardStageState();
}

class _XpRewardStageState extends State<XpRewardStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final oldTotal = math.max<int>(
      0,
      widget.result.totalXP - widget.result.xp.totalXP,
    );
    return ColoredBox(
      color: GymRatColors.black,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final progress = Curves.easeInOutCubic.transform(controller.value),
              total = oldTotal + (widget.result.xp.totalXP * progress).round(),
              level = WorkoutSessionStore.levelFromXP(total),
              current = WorkoutSessionStore.currentLevelXP(total),
              required = WorkoutSessionStore.levelSpan(level),
              bar = required <= 0
                  ? 0.0
                  : (current / required).clamp(0.0, 1.0).toDouble();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GymRatColors.gold.withValues(alpha: .12),
                      boxShadow: [
                        BoxShadow(
                          color: GymRatColors.gold.withValues(alpha: .22),
                          blurRadius: 42,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: GymRatColors.gold,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.tr.t('xpEarned'),
                    style: const TextStyle(
                      color: GymRatColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+${widget.result.xp.totalXP} XP',
                    style: const TextStyle(
                      color: GymRatColors.gold,
                      fontSize: 35,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      Text(
                        '${context.tr.t('level')} $level',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      Text(
                        '$current / $required XP',
                        style: const TextStyle(
                          color: GymRatColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: bar,
                      minHeight: 12,
                      backgroundColor: GymRatColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation(
                        GymRatColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../character/domain/rat_appearance.dart';
import '../../character/domain/rat_character_view.dart';
import '../../evolution/domain/evolution_milestones.dart';
import '../../armory/domain/rat_item.dart';
import '../../evolution/presentation/evolution_sequence.dart';
import '../../profile/domain/training_profile.dart';
import '../../workout/data/workout_session_store.dart';
import '../../workout/domain/workout_result.dart';
import '../domain/gym_upgrade.dart';
import 'level_up_celebration.dart';
import 'pr_celebration.dart';

enum _RewardPhase { personalBest, xp, levelUp, evolution }

class RewardSequence extends StatefulWidget {
  const RewardSequence({
    super.key,
    required this.result,
    required this.onComplete,
    required this.gender,
    this.appearanceId = RatAppearanceCatalog.baseId,
    this.characterView = RatCharacterView.front,
  });
  final WorkoutResult result;
  final VoidCallback onComplete;
  final RatGender gender;
  final String appearanceId;
  final RatCharacterView characterView;
  @override
  State<RewardSequence> createState() => _RewardSequenceState();
}

class _RewardSequenceState extends State<RewardSequence> {
  static const xpDuration = Duration(milliseconds: 1800),
      phaseGap = Duration(milliseconds: 140);
  _RewardPhase phase = _RewardPhase.xp;
  int prIndex = 0, celebrationLevel = 1, evolutionLevel = 5;
  bool finished = false;
  Completer<void>? evolutionCompleter;
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
        await Future<void>.delayed(LevelUpCelebration.duration + phaseGap);
        if (!mounted) return;
        if (EvolutionMilestones.isMilestone(level) &&
            RatAppearanceCatalog.hasDistinctStageAtLevel(
              appearanceId: widget.appearanceId,
              level: level,
            )) {
          evolutionCompleter = Completer<void>();
          setState(() {
            evolutionLevel = level;
            phase = _RewardPhase.evolution;
          });
          await evolutionCompleter!.future;
          await Future<void>.delayed(phaseGap);
        }
      }
    }
    if (!mounted || finished) return;
    finished = true;
    widget.onComplete();
  }

  void _completeEvolution() {
    final completer = evolutionCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  void dispose() {
    _completeEvolution();
    super.dispose();
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
          isEvolution: false,
          gender: widget.gender,
          appearanceId: widget.appearanceId,
          characterView: widget.characterView,
          upgrade: GymUpgradeCatalog.forLevel(celebrationLevel),
          ratItem: RatItemCatalog.forLevel(celebrationLevel),
        ),
        _RewardPhase.evolution => EvolutionSequence(
          key: ValueKey('evolution-$evolutionLevel'),
          previousLevel: evolutionLevel - 1,
          newLevel: evolutionLevel,
          gender: widget.gender,
          appearanceId: widget.appearanceId,
          characterView: widget.characterView,
          onComplete: _completeEvolution,
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
    final workoutXP =
        widget.result.xp.baseXP +
        widget.result.xp.activityXP +
        widget.result.xp.durationXP +
        widget.result.xp.firstWorkoutXP;
    final sources = <({IconData icon, String label, int value})>[
      (
        icon: Icons.fitness_center_rounded,
        label: context.tr.t('workout'),
        value: workoutXP,
      ),
      (
        icon: Icons.monitor_weight_outlined,
        label: context.tr.t('totalVolume'),
        value: widget.result.xp.volumeXP,
      ),
      (
        icon: Icons.local_fire_department_rounded,
        label: context.tr.t('streak'),
        value: widget.result.xp.consistencyXP,
      ),
      (
        icon: Icons.emoji_events_rounded,
        label: context.tr.t('personalBest'),
        value: widget.result.xp.prXP,
      ),
      (
        icon: Icons.workspace_premium_rounded,
        label: context.tr.t('premiumXpBoost'),
        value: widget.result.xp.premiumBonusXP,
      ),
    ].where((source) => source.value > 0).toList(growable: false);
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
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final source in sources)
                        _XpSourceChip(
                          icon: source.icon,
                          label: source.label,
                          value: source.value,
                        ),
                    ],
                  ),
                  const SizedBox(height: 26),
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

class _XpSourceChip extends StatelessWidget {
  const _XpSourceChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label, +$value XP',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: GymRatColors.gold.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: GymRatColors.gold.withValues(alpha: .24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: GymRatColors.gold, size: 14),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '+$value',
            style: const TextStyle(
              color: GymRatColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

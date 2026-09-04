import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../../core/units/weight_unit_store.dart';
import '../../character/domain/rat_appearance.dart';
import '../../character/domain/rat_character_view.dart';
import '../../hub/presentation/hub_screen.dart';
import '../../profile/data/training_profile_store.dart';
import '../../profile/domain/training_profile.dart';
import '../../rewards/presentation/reward_sequence.dart';
import '../data/workout_session_store.dart';
import '../domain/workout_result.dart';
import 'workout_copy.dart';

class WorkoutCompleteScreen extends StatefulWidget {
  const WorkoutCompleteScreen({
    super.key,
    required this.result,
    this.appearanceId = RatAppearanceCatalog.baseId,
    this.characterView = RatCharacterView.front,
  });

  final WorkoutResult result;
  final String appearanceId;
  final RatCharacterView characterView;

  @override
  State<WorkoutCompleteScreen> createState() => _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends State<WorkoutCompleteScreen> {
  bool _showSummary = false;

  void _showWorkoutSummary() {
    if (!mounted) return;
    setState(() => _showSummary = true);
  }

  void _continue() {
    final previousTotalXP = widget.result.totalXP - widget.result.xp.totalXP;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HubScreen(
          animationFromXP: previousTotalXP,
          unlockedUpgradeLevel: widget.result.leveledUp
              ? widget.result.newLevel
              : null,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _showSummary,
      child: Scaffold(
        backgroundColor: GymRatColors.black,
        body: SizedBox.expand(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _showSummary
                ? _WorkoutSummary(
                    key: const ValueKey('workout-summary'),
                    result: widget.result,
                    appearanceId: widget.appearanceId,
                    onContinue: _continue,
                  )
                : RewardSequence(
                    key: const ValueKey('reward-sequence'),
                    result: widget.result,
                    gender:
                        TrainingProfileStore.profile.value?.gender ??
                        RatGender.nonBinary,
                    appearanceId: widget.appearanceId,
                    characterView: widget.characterView,
                    onComplete: _showWorkoutSummary,
                  ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutSummary extends StatelessWidget {
  const _WorkoutSummary({
    super.key,
    required this.result,
    required this.appearanceId,
    required this.onContinue,
  });

  final WorkoutResult result;
  final String appearanceId;
  final VoidCallback onContinue;

  String get duration =>
      '${result.durationSeconds ~/ 60}:'
      '${(result.durationSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final translations = context.tr;
    final finalXP = WorkoutSessionStore.currentLevelXP(result.totalXP);
    final requiredXP = WorkoutSessionStore.levelSpan(result.newLevel);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 38, 24, 24),
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: GymRatColors.green,
            size: 58,
          ),
          const SizedBox(height: 18),
          Text(
            translations.t('workoutComplete'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GymRatColors.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            WorkoutCopy.workout(context, result.workoutName),
            textAlign: TextAlign.center,
            style: const TextStyle(color: GymRatColors.textSecondary),
          ),
          if (result.leveledUp) ...[
            const SizedBox(height: 20),
            Text(
              '${translations.t('level')} ${result.previousLevel}'
              '  →  ${translations.t('level')} ${result.newLevel}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GymRatColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          const SizedBox(height: 30),
          Row(
            children: [
              _Stat(label: translations.t('time'), value: duration),
              _Stat(
                label: translations.t('volume'),
                value: result.volume == 0
                    ? '—'
                    : WeightUnitStore.formatVolume(result.volume),
              ),
              _Stat(label: translations.t('streak'), value: '${result.streak}'),
            ],
          ),
          if (result.effortRating != null || result.sessionNote.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: GymRatColors.gold.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: GymRatColors.goldDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${translations.t('sessionEffort')}: '
                    '${result.effortRating == null ? translations.t('notRated') : '${result.effortRating}/5'}',
                    style: const TextStyle(
                      color: GymRatColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (result.sessionNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      result.sessionNote,
                      style: const TextStyle(
                        color: GymRatColors.textSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          _XPPanel(
            gained: result.xp.totalXP,
            currentXP: finalXP,
            requiredXP: requiredXP,
          ),
          if (result.prs.isNotEmpty) ...[
            const SizedBox(height: 30),
            Text(
              translations.t('personalBest'),
              style: const TextStyle(
                color: GymRatColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            for (final pr in result.prs) _PRRow(pr: pr),
          ],
          if (result.milestoneUnlocked case final milestone?
              when RatAppearanceCatalog.hasDistinctStageAtLevel(
                appearanceId: appearanceId,
                level: milestone,
              )) ...[
            const SizedBox(height: 28),
            Text(
              '${translations.t('evolutionUnlocked')} · '
              '${translations.t('level')} $milestone',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GymRatColors.gold,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 34),
          SizedBox(
            height: 58,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: GymRatColors.green,
                foregroundColor: GymRatColors.black,
              ),
              child: Text(
                translations.t('collectContinue'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XPPanel extends StatelessWidget {
  const _XPPanel({
    required this.gained,
    required this.currentXP,
    required this.requiredXP,
  });

  final int gained;
  final int currentXP;
  final int requiredXP;

  @override
  Widget build(BuildContext context) {
    final progress = requiredXP <= 0
        ? 0.0
        : (currentXP / requiredXP).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Text(
              context.tr.t('xpEarned'),
              style: const TextStyle(
                color: GymRatColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              '+$gained XP',
              style: const TextStyle(
                color: GymRatColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: GymRatColors.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation(GymRatColors.gold),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$currentXP / $requiredXP XP',
            style: const TextStyle(color: GymRatColors.textMuted, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _PRRow extends StatelessWidget {
  const _PRRow({required this.pr});

  final WorkoutPR pr;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: GymRatColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: GymRatColors.gold,
            size: 19,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              pr.exercise,
              style: const TextStyle(
                color: GymRatColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '${WeightUnitStore.formatKilograms(pr.previousBest, includeUnit: false)} '
            '→ ${WeightUnitStore.formatKilograms(pr.newWeight)}',
            style: const TextStyle(
              color: GymRatColors.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: GymRatColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: GymRatColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

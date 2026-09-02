import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../workout/data/workout_session_store.dart';
import '../../workout/domain/workout_result.dart';
import '../../workout/presentation/workout_copy.dart';

Future<void> showWorkoutHistoryDetails(
  BuildContext context,
  WorkoutHistoryEntry workout,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _WorkoutHistoryDetailSheet(workout: workout),
  );
}

class _WorkoutHistoryDetailSheet extends StatelessWidget {
  const _WorkoutHistoryDetailSheet({required this.workout});

  final WorkoutHistoryEntry workout;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final date = material.formatMediumDate(workout.completedAt);
    final time = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(workout.completedAt),
    );
    final minutes = (workout.durationSeconds / 60).round();

    return DraggableScrollableSheet(
      initialChildSize: .84,
      minChildSize: .55,
      maxChildSize: .96,
      expand: false,
      builder: (context, controller) => DecoratedBox(
        decoration: const BoxDecoration(
          color: GymRatColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: GymRatColors.border)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: GymRatColors.textMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: GymRatColors.greenDark.withValues(alpha: .32),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: GymRatColors.green.withValues(alpha: .28),
                    ),
                  ),
                  child: Icon(
                    workout.isWalk
                        ? Icons.directions_walk_rounded
                        : Icons.fitness_center_rounded,
                    color: GymRatColors.green,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.t('workoutDetails'),
                        style: const TextStyle(
                          color: GymRatColors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        WorkoutCopy.workout(context, workout.workoutName),
                        style: const TextStyle(
                          color: GymRatColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$date  ·  $time',
                        style: const TextStyle(
                          color: GymRatColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: GymRatColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _DetailStat(
                    label: context.tr.t('time'),
                    value: '$minutes ${context.tr.t('minutesShort')}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailStat(
                    label: context.tr.t('exercise'),
                    value: '${workout.exerciseCount}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailStat(
                    label: context.tr.t('volume'),
                    value: '${workout.volume.round()} kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              context.tr.t('exerciseBreakdown'),
              style: const TextStyle(
                color: GymRatColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            if (workout.exercises.isEmpty)
              _EmptyExercises(message: context.tr.t('noExercisesRecorded'))
            else
              for (final exercise in workout.exercises) ...[
                _ExerciseCard(exercise: exercise),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 13),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: GymRatColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: GymRatColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
        ),
      ],
    ),
  );
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});

  final WorkoutExerciseResult exercise;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, color: GymRatColors.green, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                WorkoutCopy.exercise(context, exercise.name),
                style: const TextStyle(
                  color: GymRatColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${exercise.volume.round()} kg',
              style: const TextStyle(
                color: GymRatColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < exercise.sets.length; index++) ...[
          _SetRow(index: index, set: exercise.sets[index]),
          if (index < exercise.sets.length - 1)
            const Divider(height: 16, color: GymRatColors.border),
        ],
      ],
    ),
  );
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.index, required this.set});

  final int index;
  final WorkoutSetResult set;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        '${context.tr.t('setLabel')} ${index + 1}',
        style: const TextStyle(
          color: GymRatColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Spacer(),
      Text(
        '${set.weight.toStringAsFixed(set.weight == set.weight.roundToDouble() ? 0 : 1)} kg',
        style: const TextStyle(
          color: GymRatColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(width: 18),
      Text(
        '${set.reps} ${context.tr.t('reps')}',
        style: const TextStyle(
          color: GymRatColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _EmptyExercises extends StatelessWidget {
  const _EmptyExercises({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Row(
      children: [
        const Icon(Icons.route_rounded, color: GymRatColors.green),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

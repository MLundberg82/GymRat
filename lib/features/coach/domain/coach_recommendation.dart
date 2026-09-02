import '../../profile/domain/training_profile.dart';
import '../../workout/data/workout_session_store.dart';

enum CoachMissionMode { strength, activeRecovery }

class CoachRecommendation {
  const CoachRecommendation({
    required this.workoutName,
    required this.setRange,
    required this.recommendedSetCount,
    required this.repRange,
    required this.weeklyCompleted,
    required this.weeklyTarget,
    required this.weeklyRemaining,
    required this.recoveryRecommended,
    required this.reasonKey,
    required this.missionMode,
    required this.rotationQueue,
    required this.recoveryDays,
    required this.latestVolume,
    required this.volumeChangePercent,
  });

  final String workoutName;
  final String setRange;
  final int recommendedSetCount;
  final String repRange;
  final int weeklyCompleted;
  final int weeklyTarget;
  final int weeklyRemaining;
  final bool recoveryRecommended;
  final String reasonKey;
  final CoachMissionMode missionMode;
  final List<String> rotationQueue;
  final int? recoveryDays;
  final double? latestVolume;
  final double? volumeChangePercent;
}

abstract final class CoachRecommendationEngine {
  static CoachRecommendation build({
    required TrainingProfile profile,
    required TrainingHistorySnapshot history,
    DateTime? now,
  }) {
    final localNow = (now ?? DateTime.now()).toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final usableWorkouts = history.workouts.where(
      (workout) => !workout.completedAt.toLocal().isAfter(localNow),
    );
    final weekly = usableWorkouts
        .where((workout) => !workout.completedAt.toLocal().isBefore(weekStart))
        .toList();
    final trainedStrengthToday = usableWorkouts.any((workout) {
      final date = workout.completedAt.toLocal();
      return !workout.isWalk &&
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    });

    const candidates = <String>['CHEST', 'BACK', 'LEGS', 'ARMS'];
    final lastTrained = <String, DateTime>{};
    for (final workout in usableWorkouts) {
      final name = workout.workoutName.toUpperCase();
      if (candidates.contains(name)) {
        final completedAt = workout.completedAt.toLocal();
        final previous = lastTrained[name];
        if (previous == null || completedAt.isAfter(previous)) {
          lastTrained[name] = completedAt;
        }
      }
    }
    final rotation = [...candidates]
      ..sort((a, b) {
        final aDate = lastTrained[a];
        final bDate = lastTrained[b];
        if (aDate == null && bDate == null) {
          return candidates.indexOf(a).compareTo(candidates.indexOf(b));
        }
        if (aDate == null) return -1;
        if (bDate == null) return 1;
        final dateOrder = aDate.compareTo(bDate);
        return dateOrder != 0
            ? dateOrder
            : candidates.indexOf(a).compareTo(candidates.indexOf(b));
      });
    final recommended = rotation.first;
    final weeklyRemaining = (profile.sessionsPerWeek - weekly.length).clamp(
      0,
      7,
    );
    final weeklyTargetReached = weeklyRemaining == 0;
    final activeRecovery = trainedStrengthToday || weeklyTargetReached;

    final (sets, setCount, reps) = switch (profile.experience) {
      TrainingExperience.beginner => ('2–3', 2, '8–12'),
      TrainingExperience.intermediate => ('3–4', 3, '6–12'),
      TrainingExperience.advanced => ('4–5', 4, '5–10'),
      TrainingExperience.expert => ('4–6', 4, '4–10'),
    };
    final goalReps = switch (profile.goal) {
      TrainingGoal.strength => '4–6',
      TrainingGoal.fatLoss => '10–15',
      TrainingGoal.buildMuscle => '8–12',
      TrainingGoal.generalFitness => reps,
    };

    final targetSessions =
        usableWorkouts
            .where(
              (workout) =>
                  workout.workoutName.toUpperCase() == recommended &&
                  workout.volume > 0,
            )
            .toList()
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final latestVolume = targetSessions.isEmpty
        ? null
        : targetSessions.first.volume;
    final previousVolume = targetSessions.length < 2
        ? null
        : targetSessions[1].volume;
    final volumeChangePercent =
        latestVolume == null || previousVolume == null || previousVolume <= 0
        ? null
        : ((latestVolume - previousVolume) / previousVolume * 100)
              .clamp(-999.0, 999.0)
              .toDouble();
    final lastTargetDate = lastTrained[recommended];

    return CoachRecommendation(
      workoutName: activeRecovery ? 'WALK' : recommended,
      setRange: activeRecovery ? '1' : sets,
      recommendedSetCount: activeRecovery ? 1 : setCount,
      repRange: activeRecovery ? '—' : goalReps,
      weeklyCompleted: weekly.length,
      weeklyTarget: profile.sessionsPerWeek,
      weeklyRemaining: weeklyRemaining,
      recoveryRecommended: activeRecovery,
      reasonKey: trainedStrengthToday
          ? 'coachRecoveryReason'
          : weeklyTargetReached
          ? 'coachWeeklyTargetReachedReason'
          : lastTrained[recommended] == null
          ? 'coachUntrainedReason'
          : 'coachRotationReason',
      missionMode: activeRecovery
          ? CoachMissionMode.activeRecovery
          : CoachMissionMode.strength,
      rotationQueue: List.unmodifiable(rotation),
      recoveryDays: lastTargetDate == null
          ? null
          : today
                .difference(
                  DateTime(
                    lastTargetDate.year,
                    lastTargetDate.month,
                    lastTargetDate.day,
                  ),
                )
                .inDays,
      latestVolume: latestVolume,
      volumeChangePercent: volumeChangePercent,
    );
  }
}

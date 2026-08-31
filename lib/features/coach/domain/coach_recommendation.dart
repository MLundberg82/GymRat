import '../../profile/domain/training_profile.dart';
import '../../workout/data/workout_session_store.dart';

class CoachRecommendation {
  const CoachRecommendation({
    required this.workoutName,
    required this.setRange,
    required this.repRange,
    required this.weeklyCompleted,
    required this.weeklyTarget,
    required this.recoveryRecommended,
    required this.reasonKey,
  });

  final String workoutName;
  final String setRange;
  final String repRange;
  final int weeklyCompleted;
  final int weeklyTarget;
  final bool recoveryRecommended;
  final String reasonKey;
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
    final weekly = history.workouts.where(
      (workout) => !workout.completedAt.toLocal().isBefore(weekStart),
    );
    final trainedToday = history.workouts.any((workout) {
      final date = workout.completedAt.toLocal();
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    });

    const candidates = <String>['CHEST', 'BACK', 'LEGS', 'ARMS'];
    final lastTrained = <String, DateTime>{};
    for (final workout in history.workouts) {
      final name = workout.workoutName.toUpperCase();
      if (candidates.contains(name)) {
        lastTrained.putIfAbsent(name, () => workout.completedAt);
      }
    }
    final recommended = candidates.reduce((a, b) {
      final aDate = lastTrained[a];
      final bDate = lastTrained[b];
      if (aDate == null) return a;
      if (bDate == null) return b;
      return aDate.isBefore(bDate) ? a : b;
    });

    final (sets, reps) = switch (profile.experience) {
      TrainingExperience.beginner => ('2–3', '8–12'),
      TrainingExperience.intermediate => ('3–4', '6–12'),
      TrainingExperience.advanced => ('4–5', '5–10'),
      TrainingExperience.expert => ('4–6', '4–10'),
    };
    final goalReps = switch (profile.goal) {
      TrainingGoal.strength => '4–6',
      TrainingGoal.fatLoss => '10–15',
      TrainingGoal.buildMuscle => '8–12',
      TrainingGoal.generalFitness => reps,
    };

    return CoachRecommendation(
      workoutName: trainedToday ? 'WALK' : recommended,
      setRange: trainedToday ? '1' : sets,
      repRange: trainedToday ? '—' : goalReps,
      weeklyCompleted: weekly.length,
      weeklyTarget: profile.sessionsPerWeek,
      recoveryRecommended: trainedToday,
      reasonKey: trainedToday
          ? 'coachRecoveryReason'
          : lastTrained[recommended] == null
          ? 'coachUntrainedReason'
          : 'coachRotationReason',
    );
  }
}

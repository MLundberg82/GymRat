import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/progress/domain/training_analytics.dart';
import 'package:gymrat/features/workout/data/workout_session_store.dart';
import 'package:gymrat/features/workout/domain/workout_result.dart';

void main() {
  WorkoutHistoryEntry workout({
    required String id,
    required DateTime date,
    required String name,
    required double weight,
    int reps = 10,
    int? effortRating,
  }) => WorkoutHistoryEntry(
    id: id,
    workoutName: 'CHEST',
    completedAt: date,
    durationSeconds: 1800,
    isWalk: false,
    effortRating: effortRating,
    exercises: [
      WorkoutExerciseResult(
        name: name,
        muscleGroup: 'chest',
        sets: [WorkoutSetResult(weight: weight, reps: reps)],
      ),
    ],
  );

  test('category analytics are chronological and preserve every session', () {
    final history = TrainingHistorySnapshot(
      workouts: [
        workout(
          id: 'new',
          date: DateTime(2026, 2, 1),
          name: 'Bench Press',
          weight: 70,
        ),
        workout(
          id: 'old',
          date: DateTime(2026, 1, 1),
          name: 'Bench Press',
          weight: 60,
        ),
      ],
      personalBests: const [],
    );

    final chest = TrainingAnalytics.category(history, 'CHEST');

    expect(chest.sessions.map((entry) => entry.id), ['old', 'new']);
    expect(chest.primaryMetric.map((point) => point.value), [600, 700]);
    expect(chest.exerciseNames, ['Bench Press']);
  });

  test('training load uses duration and user-rated effort', () {
    final now = DateTime(2026, 9, 3, 12);
    final history = TrainingHistorySnapshot(
      workouts: [
        workout(
          id: 'hard',
          date: now.subtract(const Duration(hours: 12)),
          name: 'Squat',
          weight: 100,
          effortRating: 5,
        ),
        workout(
          id: 'unrated',
          date: now.subtract(const Duration(days: 2)),
          name: 'Bench Press',
          weight: 70,
        ),
      ],
      personalBests: const [],
    );

    final insight = TrainingAnalytics.loadInsight(history, now: now);

    expect(insight.currentWeekLoad, 150);
    expect(insight.ratedSessions, 1);
    expect(insight.latestEffort, 5);
    expect(insight.readiness, TrainingReadiness.recover);
  });

  test('PB path starts with baseline and never moves backwards', () {
    final history = TrainingHistorySnapshot(
      workouts: [
        workout(
          id: 'third',
          date: DateTime(2026, 3, 1),
          name: 'Bench Press',
          weight: 75,
        ),
        workout(
          id: 'second',
          date: DateTime(2026, 2, 1),
          name: 'Bench Press',
          weight: 55,
        ),
        workout(
          id: 'baseline',
          date: DateTime(2026, 1, 1),
          name: 'Bench Press',
          weight: 60,
        ),
      ],
      personalBests: const [],
    );

    final trend = TrainingAnalytics.exercise(history, 'Bench Press');

    expect(trend.sessionBests.map((point) => point.value), [60, 55, 75]);
    expect(trend.personalBestPath.map((point) => point.value), [60, 60, 75]);
    expect(trend.baseline, 60);
    expect(trend.currentBest, 75);
    expect(trend.totalGain, 15);
    expect(trend.sessionVolumes.map((point) => point.value), [600, 550, 750]);
    expect(trend.estimatedStrength.map((point) => point.value.round()), [
      80,
      73,
      100,
    ]);
    expect(trend.currentEstimatedStrength, 100);
  });
}

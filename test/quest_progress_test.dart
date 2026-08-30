import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/quests/domain/quest_progress.dart';
import 'package:gymrat/features/workout/data/workout_session_store.dart';
import 'package:gymrat/features/workout/domain/workout_result.dart';

void main() {
  group('QuestProgressCalculator', () {
    test('derives daily and weekly contracts from real workout history', () {
      final now = DateTime(2026, 8, 30, 18);
      final history = TrainingHistorySnapshot(
        personalBests: const [],
        workouts: [
          _workout(
            id: 'today',
            completedAt: DateTime(2026, 8, 30, 10),
            durationSeconds: 30 * 60,
            exerciseCount: 3,
          ),
          _workout(
            id: 'this-week',
            completedAt: DateTime(2026, 8, 27, 10),
            durationSeconds: 60 * 60,
            exerciseCount: 1,
          ),
          _workout(
            id: 'previous-week',
            completedAt: DateTime(2026, 8, 23, 10),
            durationSeconds: 60 * 60,
            exerciseCount: 4,
          ),
        ],
      );

      final snapshot = QuestProgressCalculator.fromHistory(history, now: now);

      expect(snapshot.daily.map((quest) => quest.current), [1, 30, 3]);
      expect(snapshot.completedDaily, 3);
      expect(snapshot.weekly.map((quest) => quest.current), [2, 90]);
      expect(snapshot.completedWeekly, 1);
    });

    test('keeps visible progress and progress bars within their targets', () {
      final history = TrainingHistorySnapshot(
        personalBests: const [],
        workouts: List.generate(
          5,
          (index) => _workout(
            id: '$index',
            completedAt: DateTime(2026, 8, 30, 10 + index),
            durationSeconds: 60 * 60,
            exerciseCount: 4,
          ),
        ),
      );

      final snapshot = QuestProgressCalculator.fromHistory(
        history,
        now: DateTime(2026, 8, 30, 20),
      );

      for (final quest in [...snapshot.daily, ...snapshot.weekly]) {
        expect(quest.visibleCurrent, lessThanOrEqualTo(quest.target));
        expect(quest.progress, inInclusiveRange(0.0, 1.0));
      }
    });
  });
}

WorkoutHistoryEntry _workout({
  required String id,
  required DateTime completedAt,
  required int durationSeconds,
  required int exerciseCount,
}) {
  return WorkoutHistoryEntry(
    id: id,
    workoutName: 'CHEST',
    completedAt: completedAt,
    durationSeconds: durationSeconds,
    isWalk: false,
    exercises: List.generate(
      exerciseCount,
      (index) => WorkoutExerciseResult(
        name: 'Exercise $index',
        muscleGroup: 'chest',
        sets: const [WorkoutSetResult(weight: 10, reps: 10)],
      ),
    ),
  );
}

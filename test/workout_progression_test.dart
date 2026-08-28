import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/workout/data/workout_presets.dart';
import 'package:gymrat/features/workout/data/workout_session_store.dart';
import 'package:gymrat/features/workout/domain/workout_models.dart';
import 'package:gymrat/features/workout/domain/workout_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Workout presets', () {
    test('keeps the five expected presets free', () {
      expect(WorkoutPresets.free.map((preset) => preset.id), <String>[
        'chest',
        'back',
        'legs',
        'arms',
        'walk',
      ]);
      expect(WorkoutPresets.free.every((preset) => !preset.isPremium), isTrue);
    });

    test('uses the dedicated walk preset shape', () {
      final walk = WorkoutPresets.walk;

      expect(walk.type, WorkoutType.walk);
      expect(walk.isWalk, isTrue);
      expect(walk.exercises, isEmpty);
      expect(
        WorkoutPresets.free.where((preset) => !preset.isWalk),
        everyElement(
          isA<WorkoutPreset>().having(
            (preset) => preset.exercises,
            'exercises',
            isNotEmpty,
          ),
        ),
      );
    });
  });

  group('WorkoutSessionStore personal bests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'stores the first result as a baseline without awarding a PB',
      () async {
        final result = await _completeBenchPress(100);

        expect(result.prs, isEmpty);
        expect(result.xp.prXP, 0);
      },
    );

    test('awards a PB only above the stored best', () async {
      await _completeBenchPress(100);
      final lowerResult = await _completeBenchPress(90);
      final higherResult = await _completeBenchPress(105);

      expect(lowerResult.prs, isEmpty);
      expect(higherResult.prs, hasLength(1));
      expect(higherResult.prs.single.exercise, 'Bench Press');
      expect(higherResult.prs.single.previousBest, 100);
      expect(higherResult.prs.single.newWeight, 105);
      expect(higherResult.xp.prXP, 18);
    });
  });
}

Future<WorkoutResult> _completeBenchPress(double weight) {
  return WorkoutSessionStore.complete(
    workoutName: 'CHEST',
    walk: false,
    durationSeconds: 1800,
    exercises: <WorkoutExerciseResult>[
      WorkoutExerciseResult(
        name: 'Bench Press',
        muscleGroup: 'chest',
        sets: <WorkoutSetResult>[WorkoutSetResult(weight: weight, reps: 5)],
      ),
    ],
  );
}

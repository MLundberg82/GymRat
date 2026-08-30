import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/workout/data/workout_presets.dart';
import 'package:gymrat/features/workout/data/workout_session_store.dart';
import 'package:gymrat/features/workout/domain/workout_models.dart';
import 'package:gymrat/features/workout/domain/workout_result.dart';
import 'package:gymrat/features/rewards/domain/gym_upgrade.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Gym Armory exposes every level upgrade in order', () {
    final upgrades = GymUpgradeCatalog.all;

    expect(upgrades, hasLength(49));
    expect(upgrades.first.level, 2);
    expect(upgrades.last.level, 50);
    expect(
      upgrades.map((upgrade) => upgrade.level),
      orderedEquals(List.generate(49, (index) => index + 2)),
    );
  });

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

  group('WorkoutSessionStore progress snapshot', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('returns an empty snapshot for a new player', () async {
      final snapshot = await WorkoutSessionStore.getProgressSnapshot();

      expect(snapshot.player.level, 1);
      expect(snapshot.player.totalXP, 0);
      expect(snapshot.totalWorkouts, 0);
      expect(snapshot.recentWorkouts, isEmpty);
    });

    test('returns persisted workouts in newest-first order', () async {
      await _completeBenchPress(100);
      await WorkoutSessionStore.complete(
        workoutName: 'WALK',
        walk: true,
        durationSeconds: 900,
        exercises: const <WorkoutExerciseResult>[],
      );

      final snapshot = await WorkoutSessionStore.getProgressSnapshot();

      expect(snapshot.totalWorkouts, 2);
      expect(snapshot.recentWorkouts, hasLength(2));
      expect(snapshot.recentWorkouts.first.workoutName, 'WALK');
      expect(snapshot.recentWorkouts.first.isWalk, isTrue);
      expect(snapshot.recentWorkouts.last.exerciseCount, 1);
      expect(snapshot.recentWorkouts.last.volume, 500);
      expect(snapshot.recentWorkouts.last.exercises.single.sets.single.reps, 5);
    });

    test('ignores corrupt history without failing progress', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'gymrat-workout-history': jsonEncode(<Object>[
          'invalid',
          <String, Object>{'workoutName': 'MISSING DATE'},
        ]),
        'gymrat-total-xp': 25,
      });

      final snapshot = await WorkoutSessionStore.getProgressSnapshot();

      expect(snapshot.player.totalXP, 25);
      expect(snapshot.totalWorkouts, 0);
      expect(snapshot.recentWorkouts, isEmpty);
    });

    test('derives PB achievements only after the stored baseline', () async {
      await _completeBenchPress(100);
      var history = await WorkoutSessionStore.getTrainingHistory();
      expect(history.personalBests, isEmpty);

      await _completeBenchPress(90);
      await _completeBenchPress(105);
      await _completeBenchPress(110);
      history = await WorkoutSessionStore.getTrainingHistory();

      expect(history.workouts, hasLength(4));
      expect(history.personalBests, hasLength(1));
      final record = history.personalBests.single;
      expect(record.exerciseName, 'Bench Press');
      expect(record.baselineWeight, 100);
      expect(record.previousBest, 105);
      expect(record.weight, 110);
      expect(record.totalImprovement, 10);
      expect(record.improvementCount, 2);
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

import '../domain/workout_models.dart';

abstract final class WorkoutPresets {
  static const WorkoutPreset chest = WorkoutPreset(
    id: 'chest',
    title: 'CHEST',
    subtitle: 'Push strength & upper body',
    type: WorkoutType.strength,
    exercises: [
      WorkoutExercise(name: 'Bench Press'),
      WorkoutExercise(name: 'Incline Dumbbell Press'),
      WorkoutExercise(name: 'Chest Fly'),
      WorkoutExercise(name: 'Cable Press'),
    ],
  );

  static const WorkoutPreset back = WorkoutPreset(
    id: 'back',
    title: 'BACK',
    subtitle: 'Width, thickness & posture',
    type: WorkoutType.strength,
    exercises: [
      WorkoutExercise(name: 'Lat Pulldown'),
      WorkoutExercise(name: 'Barbell Row'),
      WorkoutExercise(name: 'Seated Cable Row'),
      WorkoutExercise(name: 'Face Pull'),
    ],
  );

  static const WorkoutPreset legs = WorkoutPreset(
    id: 'legs',
    title: 'LEGS',
    subtitle: 'Strength & lower body',
    type: WorkoutType.strength,
    exercises: [
      WorkoutExercise(name: 'Squat'),
      WorkoutExercise(name: 'Leg Press'),
      WorkoutExercise(name: 'Romanian Deadlift'),
      WorkoutExercise(name: 'Leg Curl'),
    ],
  );

  static const WorkoutPreset arms = WorkoutPreset(
    id: 'arms',
    title: 'ARMS',
    subtitle: 'Biceps & triceps',
    type: WorkoutType.strength,
    exercises: [
      WorkoutExercise(name: 'Barbell Curl'),
      WorkoutExercise(name: 'Hammer Curl'),
      WorkoutExercise(name: 'Tricep Pushdown'),
      WorkoutExercise(name: 'Overhead Extension'),
    ],
  );

  static const WorkoutPreset walk = WorkoutPreset(
    id: 'walk',
    title: 'WALK',
    subtitle: 'Recovery · movement · streak',
    type: WorkoutType.walk,
    exercises: [],
  );

  static const List<WorkoutPreset> free = [chest, back, legs, arms, walk];
}

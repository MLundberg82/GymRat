enum WorkoutType { strength, walk }

class WorkoutExercise {
  const WorkoutExercise({required this.name, this.defaultSets = 4});
  final String name;
  final int defaultSets;
}

class WorkoutPreset {
  const WorkoutPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.exercises,
    this.isPremium = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final WorkoutType type;
  final List<WorkoutExercise> exercises;
  final bool isPremium;

  bool get isWalk => type == WorkoutType.walk;
}

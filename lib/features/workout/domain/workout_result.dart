class WorkoutSetResult {
  const WorkoutSetResult({required this.weight, required this.reps});
  final double weight;
  final int reps;
  double get volume => weight * reps;
  Map<String, dynamic> toJson() => {'weight': weight, 'reps': reps};
  factory WorkoutSetResult.fromJson(Map<String, dynamic> j) => WorkoutSetResult(
    weight: (j['weight'] as num?)?.toDouble() ?? 0,
    reps: (j['reps'] as num?)?.toInt() ?? 0,
  );
}

class WorkoutExerciseResult {
  const WorkoutExerciseResult({
    required this.name,
    required this.muscleGroup,
    required this.sets,
  });
  final String name, muscleGroup;
  final List<WorkoutSetResult> sets;
  double get volume => sets.fold(0, (s, e) => s + e.volume);
  Map<String, dynamic> toJson() => {
    'name': name,
    'muscleGroup': muscleGroup,
    'sets': sets.map((e) => e.toJson()).toList(),
  };
  factory WorkoutExerciseResult.fromJson(Map<String, dynamic> j) =>
      WorkoutExerciseResult(
        name: j['name'] as String? ?? '',
        muscleGroup: j['muscleGroup'] as String? ?? 'core',
        sets: (j['sets'] as List? ?? const [])
            .map(
              (e) => WorkoutSetResult.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList(),
      );
}

class WorkoutPR {
  const WorkoutPR({
    required this.exercise,
    required this.newWeight,
    required this.previousBest,
  });
  final String exercise;
  final double newWeight, previousBest;
}

class XPBreakdown {
  const XPBreakdown({
    required this.baseXP,
    required this.activityXP,
    required this.volumeXP,
    required this.durationXP,
    required this.firstWorkoutXP,
    required this.consistencyXP,
    required this.prXP,
    this.premiumBonusXP = 0,
    required this.totalXP,
  });
  final int baseXP,
      activityXP,
      volumeXP,
      durationXP,
      firstWorkoutXP,
      consistencyXP,
      prXP,
      premiumBonusXP,
      totalXP;
}

class WorkoutResult {
  const WorkoutResult({
    required this.workoutName,
    required this.completedAt,
    required this.durationSeconds,
    required this.exercises,
    required this.prs,
    required this.xp,
    required this.previousLevel,
    required this.newLevel,
    required this.totalXP,
    required this.streak,
    required this.milestoneUnlocked,
    this.sessionNote = '',
    this.effortRating,
  });
  final String workoutName;
  final DateTime completedAt;
  final int durationSeconds;
  final List<WorkoutExerciseResult> exercises;
  final List<WorkoutPR> prs;
  final XPBreakdown xp;
  final int previousLevel, newLevel, totalXP, streak;
  final int? milestoneUnlocked;
  final String sessionNote;
  final int? effortRating;
  double get volume => exercises.fold(0, (s, e) => s + e.volume);
  int get exercisesCompleted => exercises.length;
  bool get leveledUp => newLevel > previousLevel;
}

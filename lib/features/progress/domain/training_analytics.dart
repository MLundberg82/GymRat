import '../../workout/data/workout_session_store.dart';

class TrainingPoint {
  const TrainingPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

class WorkoutCategoryTrend {
  const WorkoutCategoryTrend({
    required this.name,
    required this.sessions,
    required this.primaryMetric,
    required this.exerciseNames,
    required this.isWalk,
  });

  final String name;
  final List<WorkoutHistoryEntry> sessions;
  final List<TrainingPoint> primaryMetric;
  final List<String> exerciseNames;
  final bool isWalk;

  double get latestValue =>
      primaryMetric.isEmpty ? 0 : primaryMetric.last.value;
}

class ExerciseTrend {
  const ExerciseTrend({
    required this.exerciseName,
    required this.sessionBests,
    required this.personalBestPath,
    required this.sessionVolumes,
    required this.estimatedStrength,
  });

  final String exerciseName;
  final List<TrainingPoint> sessionBests;
  final List<TrainingPoint> personalBestPath;
  final List<TrainingPoint> sessionVolumes;
  final List<TrainingPoint> estimatedStrength;

  double get baseline => sessionBests.isEmpty ? 0 : sessionBests.first.value;
  double get currentBest =>
      personalBestPath.isEmpty ? 0 : personalBestPath.last.value;
  double get totalGain => currentBest - baseline;
  double get latestVolume =>
      sessionVolumes.isEmpty ? 0 : sessionVolumes.last.value;
  double get currentEstimatedStrength => estimatedStrength.isEmpty
      ? 0
      : estimatedStrength
            .map((point) => point.value)
            .reduce((left, right) => left > right ? left : right);
}

enum TrainingReadiness { noData, ready, balanced, recover }

class TrainingLoadInsight {
  const TrainingLoadInsight({
    required this.weeklyLoad,
    required this.currentWeekLoad,
    required this.previousWeekLoad,
    required this.ratedSessions,
    required this.latestEffort,
    required this.readiness,
  });

  final List<TrainingPoint> weeklyLoad;
  final int currentWeekLoad;
  final int previousWeekLoad;
  final int ratedSessions;
  final int? latestEffort;
  final TrainingReadiness readiness;

  double? get weeklyChangePercent => previousWeekLoad <= 0
      ? null
      : ((currentWeekLoad - previousWeekLoad) / previousWeekLoad * 100)
            .clamp(-999.0, 999.0)
            .toDouble();
}

abstract final class TrainingAnalytics {
  static const categoryNames = <String>[
    'CHEST',
    'BACK',
    'LEGS',
    'ARMS',
    'WALK',
  ];

  static List<WorkoutCategoryTrend> categories(
    TrainingHistorySnapshot history,
  ) => categoryNames.map((name) => category(history, name)).toList();

  static WorkoutCategoryTrend category(
    TrainingHistorySnapshot history,
    String name,
  ) {
    final sessions =
        history.workouts
            .where((workout) => workout.workoutName.toUpperCase() == name)
            .toList()
          ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    final isWalk = name == 'WALK';
    final exerciseNames = <String>{
      for (final session in sessions)
        for (final exercise in session.exercises)
          if (exercise.name.isNotEmpty) exercise.name,
    }.toList()..sort();
    return WorkoutCategoryTrend(
      name: name,
      sessions: List.unmodifiable(sessions),
      primaryMetric: List.unmodifiable(
        sessions.map(
          (session) => TrainingPoint(
            date: session.completedAt,
            value: isWalk ? session.durationSeconds / 60 : session.volume,
          ),
        ),
      ),
      exerciseNames: List.unmodifiable(exerciseNames),
      isWalk: isWalk,
    );
  }

  static ExerciseTrend exercise(
    TrainingHistorySnapshot history,
    String exerciseName,
  ) {
    final chronological = history.workouts.toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    final sessionBests = <TrainingPoint>[];
    final personalBestPath = <TrainingPoint>[];
    final sessionVolumes = <TrainingPoint>[];
    final estimatedStrength = <TrainingPoint>[];
    var runningBest = 0.0;

    for (final workout in chronological) {
      final matching = workout.exercises
          .where((exercise) => exercise.name == exerciseName)
          .toList(growable: false);
      final sets = matching
          .expand((exercise) => exercise.sets)
          .toList(growable: false);
      if (sets.isEmpty) continue;
      var sessionBest = 0.0;
      var sessionVolume = 0.0;
      var sessionEstimatedStrength = 0.0;
      for (final set in sets) {
        if (set.weight > sessionBest) sessionBest = set.weight;
        sessionVolume += set.volume;
        if (set.weight > 0 && set.reps > 0) {
          final estimate = set.reps == 1
              ? set.weight
              : set.weight * (1 + set.reps / 30);
          if (estimate > sessionEstimatedStrength) {
            sessionEstimatedStrength = estimate;
          }
        }
      }
      if (sessionBest <= 0) continue;
      sessionBests.add(
        TrainingPoint(date: workout.completedAt, value: sessionBest),
      );
      if (sessionBest > runningBest) runningBest = sessionBest;
      personalBestPath.add(
        TrainingPoint(date: workout.completedAt, value: runningBest),
      );
      sessionVolumes.add(
        TrainingPoint(date: workout.completedAt, value: sessionVolume),
      );
      estimatedStrength.add(
        TrainingPoint(
          date: workout.completedAt,
          value: sessionEstimatedStrength,
        ),
      );
    }

    return ExerciseTrend(
      exerciseName: exerciseName,
      sessionBests: List.unmodifiable(sessionBests),
      personalBestPath: List.unmodifiable(personalBestPath),
      sessionVolumes: List.unmodifiable(sessionVolumes),
      estimatedStrength: List.unmodifiable(estimatedStrength),
    );
  }

  static TrainingLoadInsight loadInsight(
    TrainingHistorySnapshot history, {
    DateTime? now,
  }) {
    final localNow = (now ?? DateTime.now()).toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final currentWeek = today.subtract(Duration(days: today.weekday - 1));
    final firstWeek = currentWeek.subtract(const Duration(days: 35));
    final loads = <DateTime, int>{
      for (var offset = 0; offset < 6; offset++)
        firstWeek.add(Duration(days: offset * 7)): 0,
    };
    final rated =
        history.workouts
            .where((workout) => workout.sessionLoad != null)
            .toList()
          ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    for (final workout in rated) {
      final date = workout.completedAt.toLocal();
      if (date.isAfter(localNow)) continue;
      final day = DateTime(date.year, date.month, date.day);
      final week = day.subtract(Duration(days: day.weekday - 1));
      if (loads.containsKey(week)) {
        loads[week] = loads[week]! + workout.sessionLoad!;
      }
    }

    final points = loads.entries
        .map(
          (entry) =>
              TrainingPoint(date: entry.key, value: entry.value.toDouble()),
        )
        .toList(growable: false);
    final current = loads[currentWeek] ?? 0;
    final previous = loads[currentWeek.subtract(const Duration(days: 7))] ?? 0;
    final completedRated = rated
        .where((workout) => !workout.completedAt.toLocal().isAfter(localNow))
        .toList(growable: false);
    final latestEffort = completedRated.isEmpty
        ? null
        : completedRated.last.effortRating;
    final latestDate = completedRated.isEmpty
        ? null
        : completedRated.last.completedAt.toLocal();
    final latestIsRecent =
        latestDate != null && localNow.difference(latestDate).inHours < 36;
    final readiness = completedRated.isEmpty
        ? TrainingReadiness.noData
        : latestIsRecent && latestEffort != null && latestEffort >= 4
        ? TrainingReadiness.recover
        : current > 0 && previous > 0 && current > previous * 1.35
        ? TrainingReadiness.balanced
        : TrainingReadiness.ready;

    return TrainingLoadInsight(
      weeklyLoad: List.unmodifiable(points),
      currentWeekLoad: current,
      previousWeekLoad: previous,
      ratedSessions: completedRated.length,
      latestEffort: latestEffort,
      readiness: readiness,
    );
  }
}

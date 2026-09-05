import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../evolution/domain/evolution_milestones.dart';
import '../domain/workout_result.dart';

String _normalizedSessionNote(Object? value) {
  final note = value is String ? value.trim() : '';
  return note.length <= 240 ? note : note.substring(0, 240);
}

class PlayerProgress {
  const PlayerProgress({
    required this.totalXP,
    required this.level,
    required this.currentLevelXP,
    required this.requiredLevelXP,
    required this.streak,
  });
  final int totalXP, level, currentLevelXP, requiredLevelXP, streak;
  double get progress =>
      requiredLevelXP <= 0 ? 0 : (currentLevelXP / requiredLevelXP).clamp(0, 1);
}

class WorkoutHistoryEntry {
  const WorkoutHistoryEntry({
    required this.id,
    required this.workoutName,
    required this.completedAt,
    required this.durationSeconds,
    required this.isWalk,
    required this.exercises,
    this.sessionNote = '',
    this.effortRating,
  });

  final String id;
  final String workoutName;
  final DateTime completedAt;
  final int durationSeconds;
  final bool isWalk;
  final List<WorkoutExerciseResult> exercises;
  final String sessionNote;
  final int? effortRating;

  int? get sessionLoad => effortRating == null
      ? null
      : ((durationSeconds / 60).round().clamp(1, 999999) * effortRating!);

  int get exerciseCount => exercises.length;
  double get volume =>
      exercises.fold<double>(0, (sum, exercise) => sum + exercise.volume);

  static WorkoutHistoryEntry? tryParse(Map<String, dynamic> json) {
    final rawWorkoutName = json['workoutName'];
    final rawCompletedAt = json['completedAt'];
    if (rawWorkoutName is! String || rawCompletedAt is! String) return null;
    final completedAt = DateTime.tryParse(rawCompletedAt);
    if (rawWorkoutName.isEmpty || completedAt == null) {
      return null;
    }

    final exercises = <WorkoutExerciseResult>[];
    final rawExercises = json['exercises'];
    if (rawExercises is List) {
      for (final raw in rawExercises) {
        if (raw is! Map) continue;
        try {
          exercises.add(
            WorkoutExerciseResult.fromJson(Map<String, dynamic>.from(raw)),
          );
        } catch (_) {
          // Keep older sessions readable even if one exercise is malformed.
        }
      }
    }

    final rawId = json['id'];
    final rawDuration = json['durationSeconds'];
    final rawWalk = json['walk'];
    return WorkoutHistoryEntry(
      id: rawId is String && rawId.isNotEmpty
          ? rawId
          : 'legacy-${completedAt.microsecondsSinceEpoch}-$rawWorkoutName',
      workoutName: rawWorkoutName,
      completedAt: completedAt,
      durationSeconds: rawDuration is num ? rawDuration.toInt() : 0,
      isWalk: rawWalk is bool ? rawWalk : exercises.isEmpty,
      exercises: List.unmodifiable(exercises),
      sessionNote: _normalizedSessionNote(json['sessionNote']),
      effortRating: switch (json['effortRating']) {
        final num value when value >= 1 && value <= 5 => value.toInt(),
        _ => null,
      },
    );
  }
}

class PersonalBestRecord {
  const PersonalBestRecord({
    required this.exerciseName,
    required this.weight,
    required this.previousBest,
    required this.baselineWeight,
    required this.achievedAt,
    required this.improvementCount,
  });

  final String exerciseName;
  final double weight;
  final double previousBest;
  final double baselineWeight;
  final DateTime achievedAt;
  final int improvementCount;

  double get totalImprovement => weight - baselineWeight;
}

class TrainingHistorySnapshot {
  const TrainingHistorySnapshot({
    required this.workouts,
    required this.personalBests,
  });

  final List<WorkoutHistoryEntry> workouts;
  final List<PersonalBestRecord> personalBests;

  int get totalDurationSeconds =>
      workouts.fold<int>(0, (sum, workout) => sum + workout.durationSeconds);
  double get totalVolume =>
      workouts.fold<double>(0, (sum, workout) => sum + workout.volume);
}

class _PersonalBestState {
  _PersonalBestState({required this.baselineWeight, required this.currentBest});

  final double baselineWeight;
  double currentBest;
  double previousBest = 0;
  DateTime? achievedAt;
  int improvementCount = 0;
}

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.player,
    required this.totalWorkouts,
    required this.recentWorkouts,
  });

  final PlayerProgress player;
  final int totalWorkouts;
  final List<WorkoutHistoryEntry> recentWorkouts;
}

abstract final class WorkoutSessionStore {
  static const _historyKey = 'gymrat-workout-history',
      _xpKey = 'gymrat-total-xp',
      _workoutsKey = 'gymrat-total-workouts',
      _streakKey = 'gymrat-streak',
      _lastWorkoutKey = 'gymrat-last-workout';

  static Future<List<Map<String, dynamic>>> _history() async {
    final p = await SharedPreferences.getInstance(),
        raw = p.getString(_historyKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<WorkoutHistoryEntry>> _parsedHistory() async {
    return (await _history())
        .map(WorkoutHistoryEntry.tryParse)
        .whereType<WorkoutHistoryEntry>()
        .toList();
  }

  static List<PersonalBestRecord> _personalBests(
    List<WorkoutHistoryEntry> workouts,
  ) {
    final states = <String, _PersonalBestState>{};
    for (final workout in workouts.reversed) {
      for (final exercise in workout.exercises) {
        var sessionBest = 0.0;
        for (final set in exercise.sets) {
          if (set.weight > sessionBest) sessionBest = set.weight;
        }
        if (exercise.name.isEmpty || exercise.sets.isEmpty) continue;

        final state = states[exercise.name];
        if (state == null) {
          states[exercise.name] = _PersonalBestState(
            baselineWeight: sessionBest,
            currentBest: sessionBest,
          );
        } else if (sessionBest > state.currentBest) {
          state.previousBest = state.currentBest;
          state.currentBest = sessionBest;
          state.achievedAt = workout.completedAt;
          state.improvementCount++;
        }
      }
    }

    final records = <PersonalBestRecord>[];
    for (final entry in states.entries) {
      final state = entry.value;
      if (state.improvementCount == 0 || state.achievedAt == null) continue;
      records.add(
        PersonalBestRecord(
          exerciseName: entry.key,
          weight: state.currentBest,
          previousBest: state.previousBest,
          baselineWeight: state.baselineWeight,
          achievedAt: state.achievedAt!,
          improvementCount: state.improvementCount,
        ),
      );
    }
    records.sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    return List.unmodifiable(records);
  }

  static Future<double?> _previousBest(String name) async {
    var found = false, best = 0.0;
    for (final w in await _history()) {
      final rawExercises = w['exercises'];
      if (rawExercises is! List) continue;
      for (final raw in rawExercises) {
        if (raw is! Map) continue;
        WorkoutExerciseResult e;
        try {
          e = WorkoutExerciseResult.fromJson(Map<String, dynamic>.from(raw));
        } catch (_) {
          continue;
        }
        if (e.name != name) continue;
        found = true;
        for (final s in e.sets) {
          if (s.weight > best) best = s.weight;
        }
      }
    }
    return found ? best : null;
  }

  static int _dayDifference(DateTime a, DateTime b) => DateTime(
    a.year,
    a.month,
    a.day,
  ).difference(DateTime(b.year, b.month, b.day)).inDays;

  static int levelSpan(int l) {
    if (l <= 1) return 90;
    if (l == 2) return 110;
    if (l == 3) return 130;
    if (l == 4) return 150;
    if (l <= 14) return 175 + (l - 5) * 18;
    if (l <= 29) return 355 + (l - 15) * 24;
    return 715 + (l - 30) * 30;
  }

  static int levelFromXP(int xp) {
    var r = xp < 0 ? 0 : xp, l = 1;
    while (r >= levelSpan(l)) {
      r -= levelSpan(l);
      l++;
    }
    return l;
  }

  static int totalXPToReachLevel(int level) {
    final target = level < 1 ? 1 : level;
    var total = 0;
    for (var current = 1; current < target; current++) {
      total += levelSpan(current);
    }
    return total;
  }

  static int currentLevelXP(int xp) {
    var r = xp < 0 ? 0 : xp, l = 1;
    while (r >= levelSpan(l)) {
      r -= levelSpan(l);
      l++;
    }
    return r;
  }

  static XPBreakdown _calculateXP({
    required bool walk,
    required int exercises,
    required double volume,
    required int durationMinutes,
    required int streak,
    required int prs,
    required bool firstToday,
    required bool premiumXPBoost,
  }) {
    final base = walk ? 22 : 50,
        activity = walk ? 0 : (exercises >= 4 ? 8 : 4),
        volumeXP = walk ? 0 : (volume ~/ 1600) * 4;
    final durationXP = durationMinutes >= 45
            ? 8
            : durationMinutes >= 30
            ? 4
            : 0,
        first = firstToday ? 8 : 0,
        consistency = (streak * 2).clamp(2, 16),
        prXP = prs * 18;
    final earnedXP =
        base + activity + volumeXP + durationXP + first + consistency + prXP;
    final premiumBonusXP = premiumXPBoost
        ? (earnedXP * .10).round().clamp(1, 1000000)
        : 0;
    return XPBreakdown(
      baseXP: base,
      activityXP: activity,
      volumeXP: volumeXP,
      durationXP: durationXP,
      firstWorkoutXP: first,
      consistencyXP: consistency,
      prXP: prXP,
      premiumBonusXP: premiumBonusXP,
      totalXP: earnedXP + premiumBonusXP,
    );
  }

  static Future<WorkoutResult> complete({
    required String workoutName,
    required bool walk,
    required int durationSeconds,
    required List<WorkoutExerciseResult> exercises,
    String sessionNote = '',
    int? effortRating,
    bool premiumXPBoost = false,
  }) async {
    final now = DateTime.now(), p = await SharedPreferences.getInstance();
    final normalizedNote = _normalizedSessionNote(sessionNote);
    final prs = <WorkoutPR>[];

    if (!walk) {
      for (final e in exercises) {
        final old = await _previousBest(e.name);
        var best = 0.0;
        for (final s in e.sets) {
          if (s.weight > best) best = s.weight;
        }
        if (old != null && best > 0 && best > old) {
          prs.add(
            WorkoutPR(exercise: e.name, newWeight: best, previousBest: old),
          );
        }
      }
    }

    final lastRaw = p.getString(_lastWorkoutKey),
        oldStreak = p.getInt(_streakKey) ?? 0;
    var streak = 1, firstToday = true;
    if (lastRaw != null) {
      final last = DateTime.tryParse(lastRaw);
      if (last != null) {
        final d = _dayDifference(now, last);
        firstToday = d > 0;
        if (d == 0) {
          streak = oldStreak.clamp(1, 999999);
        } else if (d == 1) {
          streak = oldStreak + 1;
        }
      }
    }

    final volume = exercises.fold<double>(0, (s, e) => s + e.volume),
        minutes = (durationSeconds / 60).round().clamp(1, 999999);
    final xp = _calculateXP(
      walk: walk,
      exercises: exercises.length,
      volume: volume,
      durationMinutes: minutes,
      streak: streak,
      prs: prs.length,
      firstToday: firstToday,
      premiumXPBoost: premiumXPBoost,
    );
    final previousXP = p.getInt(_xpKey) ?? 0,
        previousLevel = levelFromXP(previousXP),
        totalXP = previousXP + xp.totalXP,
        newLevel = levelFromXP(totalXP);

    int? unlocked;
    for (final m in EvolutionMilestones.unlockLevels) {
      if (m > previousLevel && m <= newLevel) unlocked = m;
    }

    final history = await _history();
    history.insert(0, {
      'id': 'workout-${now.millisecondsSinceEpoch}',
      'workoutName': workoutName,
      'completedAt': now.toIso8601String(),
      'durationSeconds': durationSeconds,
      'walk': walk,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'sessionNote': normalizedNote,
      'effortRating': effortRating?.clamp(1, 5),
    });
    await p.setString(_historyKey, jsonEncode(history));
    await p.setInt(_xpKey, totalXP);
    await p.setInt(_workoutsKey, (p.getInt(_workoutsKey) ?? 0) + 1);
    await p.setInt(_streakKey, streak);
    await p.setString(_lastWorkoutKey, now.toIso8601String());

    return WorkoutResult(
      workoutName: workoutName,
      completedAt: now,
      durationSeconds: durationSeconds,
      exercises: exercises,
      prs: prs,
      xp: xp,
      previousLevel: previousLevel,
      newLevel: newLevel,
      totalXP: totalXP,
      streak: streak,
      milestoneUnlocked: unlocked,
      sessionNote: normalizedNote,
      effortRating: effortRating?.clamp(1, 5),
    );
  }

  static Future<PlayerProgress> getPlayerProgress() async {
    final p = await SharedPreferences.getInstance(),
        xp = p.getInt(_xpKey) ?? 0,
        l = levelFromXP(xp);
    return PlayerProgress(
      totalXP: xp,
      level: l,
      currentLevelXP: currentLevelXP(xp),
      requiredLevelXP: levelSpan(l),
      streak: await getStreak(),
    );
  }

  static Future<ProgressSnapshot> getProgressSnapshot({
    int recentLimit = 5,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final parsedWorkouts = await _parsedHistory();
    final recentWorkouts = parsedWorkouts
        .take(recentLimit < 0 ? 0 : recentLimit)
        .toList(growable: false);

    return ProgressSnapshot(
      player: await getPlayerProgress(),
      totalWorkouts: (preferences.getInt(_workoutsKey) ?? parsedWorkouts.length)
          .clamp(0, 999999999),
      recentWorkouts: recentWorkouts,
    );
  }

  static Future<TrainingHistorySnapshot> getTrainingHistory() async {
    final workouts = await _parsedHistory();
    return TrainingHistorySnapshot(
      workouts: List.unmodifiable(workouts),
      personalBests: _personalBests(workouts),
    );
  }

  static Future<int> getStreak() async {
    final p = await SharedPreferences.getInstance(),
        raw = p.getString(_lastWorkoutKey);
    if (raw == null) return 0;
    final last = DateTime.tryParse(raw);
    if (last == null) return 0;
    if (_dayDifference(DateTime.now(), last) > 1) return 0;
    return p.getInt(_streakKey) ?? 0;
  }
}

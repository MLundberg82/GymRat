import '../../workout/data/workout_session_store.dart';

enum QuestPeriod { daily, weekly }

enum QuestUnit { sessions, minutes, exercises }

class QuestProgress {
  const QuestProgress({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.period,
    required this.unit,
    required this.current,
    required this.target,
    required this.claimId,
    required this.rewardCredits,
    required this.isClaimed,
  });

  final String id;
  final String titleKey;
  final String descriptionKey;
  final QuestPeriod period;
  final QuestUnit unit;
  final int current;
  final int target;
  final String claimId;
  final int rewardCredits;
  final bool isClaimed;

  bool get isComplete => current >= target;
  double get progress => (current / target).clamp(0.0, 1.0);
  int get visibleCurrent => current.clamp(0, target);
}

class QuestSnapshot {
  const QuestSnapshot({
    required this.daily,
    required this.weekly,
    this.credits = 0,
  });

  final List<QuestProgress> daily;
  final List<QuestProgress> weekly;
  final int credits;

  int get completedDaily => daily.where((quest) => quest.isComplete).length;
  int get completedWeekly => weekly.where((quest) => quest.isComplete).length;
}

abstract final class QuestProgressCalculator {
  static QuestSnapshot fromHistory(
    TrainingHistorySnapshot history, {
    DateTime? now,
    Set<String> claimedQuestIds = const <String>{},
    int credits = 0,
  }) {
    final localNow = (now ?? DateTime.now()).toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = weekStart.add(const Duration(days: 7));
    final dayToken = _dateToken(today);
    final weekToken = _dateToken(weekStart);

    final dailyWorkouts = history.workouts
        .where((workout) => _isWithin(workout.completedAt, today, tomorrow))
        .toList();
    final weeklyWorkouts = history.workouts
        .where((workout) => _isWithin(workout.completedAt, weekStart, nextWeek))
        .toList();

    final dailySeconds = dailyWorkouts.fold<int>(
      0,
      (sum, workout) => sum + workout.durationSeconds,
    );
    final weeklySeconds = weeklyWorkouts.fold<int>(
      0,
      (sum, workout) => sum + workout.durationSeconds,
    );
    final dailyExercises = dailyWorkouts.fold<int>(
      0,
      (sum, workout) => sum + workout.exerciseCount,
    );

    return QuestSnapshot(
      daily: List.unmodifiable(<QuestProgress>[
        QuestProgress(
          id: 'daily-session',
          titleKey: 'questDailySession',
          descriptionKey: 'questDailySessionDescription',
          period: QuestPeriod.daily,
          unit: QuestUnit.sessions,
          current: dailyWorkouts.length,
          target: 1,
          claimId: 'daily-session-$dayToken',
          rewardCredits: 10,
          isClaimed: claimedQuestIds.contains('daily-session-$dayToken'),
        ),
        QuestProgress(
          id: 'daily-duration',
          titleKey: 'questDailyDuration',
          descriptionKey: 'questDailyDurationDescription',
          period: QuestPeriod.daily,
          unit: QuestUnit.minutes,
          current: dailySeconds ~/ 60,
          target: 20,
          claimId: 'daily-duration-$dayToken',
          rewardCredits: 10,
          isClaimed: claimedQuestIds.contains('daily-duration-$dayToken'),
        ),
        QuestProgress(
          id: 'daily-exercises',
          titleKey: 'questDailyExercises',
          descriptionKey: 'questDailyExercisesDescription',
          period: QuestPeriod.daily,
          unit: QuestUnit.exercises,
          current: dailyExercises,
          target: 3,
          claimId: 'daily-exercises-$dayToken',
          rewardCredits: 15,
          isClaimed: claimedQuestIds.contains('daily-exercises-$dayToken'),
        ),
      ]),
      weekly: List.unmodifiable(<QuestProgress>[
        QuestProgress(
          id: 'weekly-sessions',
          titleKey: 'questWeeklySessions',
          descriptionKey: 'questWeeklySessionsDescription',
          period: QuestPeriod.weekly,
          unit: QuestUnit.sessions,
          current: weeklyWorkouts.length,
          target: 3,
          claimId: 'weekly-sessions-$weekToken',
          rewardCredits: 30,
          isClaimed: claimedQuestIds.contains('weekly-sessions-$weekToken'),
        ),
        QuestProgress(
          id: 'weekly-duration',
          titleKey: 'questWeeklyDuration',
          descriptionKey: 'questWeeklyDurationDescription',
          period: QuestPeriod.weekly,
          unit: QuestUnit.minutes,
          current: weeklySeconds ~/ 60,
          target: 90,
          claimId: 'weekly-duration-$weekToken',
          rewardCredits: 35,
          isClaimed: claimedQuestIds.contains('weekly-duration-$weekToken'),
        ),
      ]),
      credits: credits,
    );
  }

  static bool _isWithin(DateTime value, DateTime start, DateTime end) {
    final localValue = value.toLocal();
    return !localValue.isBefore(start) && localValue.isBefore(end);
  }

  static String _dateToken(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}'
      '${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}';
}

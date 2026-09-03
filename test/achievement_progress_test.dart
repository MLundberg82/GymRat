import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/progress/domain/achievement_progress.dart';
import 'package:gymrat/features/workout/data/workout_session_store.dart';

void main() {
  test('achievements derive only from canonical progress and records', () {
    final progress = ProgressSnapshot(
      player: const PlayerProgress(
        totalXP: 500,
        level: 5,
        currentLevelXP: 20,
        requiredLevelXP: 175,
        streak: 3,
      ),
      totalWorkouts: 10,
      recentWorkouts: const [],
    );
    final history = TrainingHistorySnapshot(
      workouts: const [],
      personalBests: [
        PersonalBestRecord(
          exerciseName: 'Squat',
          weight: 110,
          previousBest: 105,
          baselineWeight: 100,
          achievedAt: DateTime(2026, 9, 3),
          improvementCount: 2,
        ),
      ],
    );

    final achievements = AchievementProgress.derive(
      progress: progress,
      history: history,
    );

    expect(
      achievements
          .where((achievement) => achievement.isUnlocked)
          .map((a) => a.id),
      containsAll(<String>[
        'first-session',
        'ten-sessions',
        'three-streak',
        'first-record',
        'first-evolution',
      ]),
    );
    expect(
      achievements.singleWhere((a) => a.id == 'five-records').progress,
      .4,
    );
  });
}

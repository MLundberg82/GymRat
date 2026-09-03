import '../../workout/data/workout_session_store.dart';

enum AchievementKind { workout, streak, record, evolution }

class GymRatAchievement {
  const GymRatAchievement({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.kind,
    required this.current,
    required this.target,
  });

  final String id;
  final String titleKey;
  final String descriptionKey;
  final AchievementKind kind;
  final int current;
  final int target;

  bool get isUnlocked => current >= target;
  double get progress =>
      target <= 0 ? 0 : (current / target).clamp(0.0, 1.0).toDouble();
}

abstract final class AchievementProgress {
  static List<GymRatAchievement> derive({
    required ProgressSnapshot progress,
    required TrainingHistorySnapshot history,
  }) {
    final recordBreaks = history.personalBests.fold<int>(
      0,
      (sum, record) => sum + record.improvementCount,
    );
    return List.unmodifiable(<GymRatAchievement>[
      GymRatAchievement(
        id: 'first-session',
        titleKey: 'achievementFirstSession',
        descriptionKey: 'achievementFirstSessionHelp',
        kind: AchievementKind.workout,
        current: progress.totalWorkouts,
        target: 1,
      ),
      GymRatAchievement(
        id: 'ten-sessions',
        titleKey: 'achievementTenSessions',
        descriptionKey: 'achievementTenSessionsHelp',
        kind: AchievementKind.workout,
        current: progress.totalWorkouts,
        target: 10,
      ),
      GymRatAchievement(
        id: 'campaign-veteran',
        titleKey: 'achievementCampaignVeteran',
        descriptionKey: 'achievementCampaignVeteranHelp',
        kind: AchievementKind.workout,
        current: progress.totalWorkouts,
        target: 25,
      ),
      GymRatAchievement(
        id: 'three-streak',
        titleKey: 'achievementThreeStreak',
        descriptionKey: 'achievementThreeStreakHelp',
        kind: AchievementKind.streak,
        current: progress.player.streak,
        target: 3,
      ),
      GymRatAchievement(
        id: 'seven-streak',
        titleKey: 'achievementSevenStreak',
        descriptionKey: 'achievementSevenStreakHelp',
        kind: AchievementKind.streak,
        current: progress.player.streak,
        target: 7,
      ),
      GymRatAchievement(
        id: 'first-record',
        titleKey: 'achievementFirstRecord',
        descriptionKey: 'achievementFirstRecordHelp',
        kind: AchievementKind.record,
        current: recordBreaks,
        target: 1,
      ),
      GymRatAchievement(
        id: 'five-records',
        titleKey: 'achievementFiveRecords',
        descriptionKey: 'achievementFiveRecordsHelp',
        kind: AchievementKind.record,
        current: recordBreaks,
        target: 5,
      ),
      GymRatAchievement(
        id: 'first-evolution',
        titleKey: 'achievementFirstEvolution',
        descriptionKey: 'achievementFirstEvolutionHelp',
        kind: AchievementKind.evolution,
        current: progress.player.level,
        target: 5,
      ),
    ]);
  }
}

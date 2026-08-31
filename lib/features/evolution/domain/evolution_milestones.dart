abstract final class EvolutionMilestones {
  static const List<int> unlockLevels = <int>[5, 10, 15, 20, 30, 40, 50];
  static const List<int> stages = <int>[1, ...unlockLevels];

  static bool isMilestone(int level) => unlockLevels.contains(level);

  static int stageForLevel(int level) {
    var stage = 1;
    for (final milestone in unlockLevels) {
      if (level < milestone) break;
      stage = milestone;
    }
    return stage;
  }

  static int previousStageFor(int milestone) {
    var previous = 1;
    for (final stage in stages) {
      if (stage >= milestone) break;
      previous = stage;
    }
    return previous;
  }

  static int stageIndexForLevel(int level) {
    return stages
        .indexOf(stageForLevel(level))
        .clamp(0, stages.length - 1)
        .toInt();
  }

  static double widthScaleForLevel(int level) {
    const scales = <double>[1, 1.06, 1.12, 1.18, 1.27, 1.36, 1.47, 1.62];
    return scales[stageIndexForLevel(level)];
  }

  static double heightScaleForLevel(int level) {
    const scales = <double>[1, 1.02, 1.05, 1.08, 1.12, 1.16, 1.20, 1.25];
    return scales[stageIndexForLevel(level)];
  }

  static double intensityForLevel(int level) {
    final index = stageIndexForLevel(level);
    return .72 + index / (stages.length - 1) * .28;
  }
}

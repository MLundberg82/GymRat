abstract final class EvolutionMilestones {
  static const List<int> unlockLevels = <int>[5, 10, 15, 20, 30, 40, 50];
  static const List<int> stages = <int>[1, ...unlockLevels];

  static bool isMilestone(int level) => unlockLevels.contains(level);

  static int? nextMilestoneAfter(int level) {
    for (final milestone in unlockLevels) {
      if (milestone > level) return milestone;
    }
    return null;
  }

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
    const scales = <double>[.68, .82, 1, 1.12, 1.25, 1.38, 1.52, 1.70];
    return scales[stageIndexForLevel(level)];
  }

  static double heightScaleForLevel(int level) {
    const scales = <double>[.72, .85, 1, 1.08, 1.16, 1.24, 1.31, 1.38];
    return scales[stageIndexForLevel(level)];
  }

  static double intensityForLevel(int level) {
    final index = stageIndexForLevel(level);
    return .72 + index / (stages.length - 1) * .28;
  }
}

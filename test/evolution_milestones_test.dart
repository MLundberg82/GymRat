import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/evolution/domain/evolution_milestones.dart';

void main() {
  group('EvolutionMilestones', () {
    test('uses the expected milestone levels', () {
      expect(EvolutionMilestones.unlockLevels, <int>[
        5,
        10,
        15,
        20,
        30,
        40,
        50,
      ]);
    });

    test('resolves the active evolution stage', () {
      expect(EvolutionMilestones.stageForLevel(1), 1);
      expect(EvolutionMilestones.stageForLevel(4), 1);
      expect(EvolutionMilestones.stageForLevel(5), 5);
      expect(EvolutionMilestones.stageForLevel(29), 20);
      expect(EvolutionMilestones.stageForLevel(50), 50);
      expect(EvolutionMilestones.stageForLevel(80), 50);
    });

    test('resolves the previous milestone for morphing', () {
      expect(EvolutionMilestones.previousStageFor(5), 1);
      expect(EvolutionMilestones.previousStageFor(10), 5);
      expect(EvolutionMilestones.previousStageFor(30), 20);
      expect(EvolutionMilestones.previousStageFor(50), 40);
    });

    test('character growth is monotonic', () {
      var previousWidth = 0.0;
      var previousHeight = 0.0;
      for (final stage in EvolutionMilestones.stages) {
        final width = EvolutionMilestones.widthScaleForLevel(stage);
        final height = EvolutionMilestones.heightScaleForLevel(stage);
        expect(width, greaterThan(previousWidth));
        expect(height, greaterThan(previousHeight));
        previousWidth = width;
        previousHeight = height;
      }
    });
  });
}

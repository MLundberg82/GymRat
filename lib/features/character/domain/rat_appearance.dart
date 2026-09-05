import '../../../core/assets/gymrat_assets.dart';
import '../../evolution/domain/evolution_milestones.dart';
import '../../profile/domain/training_profile.dart';

enum RatAppearanceView { front, back }

class RatAppearanceAssets {
  const RatAppearanceAssets({required this.front, required this.back});

  final String front;
  final String back;

  String forView(RatAppearanceView view) => switch (view) {
    RatAppearanceView.front => front,
    RatAppearanceView.back => back,
  };
}

class RatAppearance {
  const RatAppearance({
    required this.id,
    required this.stages,
    this.productId,
    this.approvedMotionContractVersion,
  });

  final String id;
  final Map<int, Map<RatGender, RatAppearanceAssets>> stages;
  final String? productId;
  final int? approvedMotionContractVersion;

  Map<RatGender, RatAppearanceAssets> get assetsByGender => stages[1] ?? {};

  bool get isComplete =>
      stages.containsKey(1) &&
      stages.entries.every((entry) {
        if (!EvolutionMilestones.stages.contains(entry.key)) return false;
        return RatGender.values.every((gender) {
          final assets = entry.value[gender];
          return assets != null &&
              assets.front.isNotEmpty &&
              assets.back.isNotEmpty;
        });
      });

  List<int> get approvedStages => stages.keys.toList()..sort();

  int approvedStageForLevel(int level) {
    var approvedStage = 1;
    for (final stage in approvedStages) {
      if (stage > level) break;
      approvedStage = stage;
    }
    return approvedStage;
  }

  String assetFor(RatGender gender, RatAppearanceView view, {int level = 1}) {
    final stage = approvedStageForLevel(level);
    final assets = stages[stage]?[gender];
    if (assets == null || !isComplete) {
      if (id == RatAppearanceCatalog.baseId) {
        return RatAppearanceCatalog.base.assetsByGender[gender]!.forView(view);
      }
      return RatAppearanceCatalog.base.assetFor(gender, view, level: level);
    }
    return assets.forView(view);
  }
}

abstract final class RatAppearanceCatalog {
  static const String baseId = 'base';
  static const int motionContractVersion = 4;

  static const RatAppearance base = RatAppearance(
    id: baseId,
    stages: {
      1: {
        RatGender.male: RatAppearanceAssets(
          front: GymRatAssets.maleLevel1,
          back: GymRatAssets.maleLevel1Back,
        ),
        RatGender.female: RatAppearanceAssets(
          front: GymRatAssets.femaleLevel1,
          back: GymRatAssets.femaleLevel1Back,
        ),
        RatGender.nonBinary: RatAppearanceAssets(
          front: GymRatAssets.nonBinaryLevel1,
          back: GymRatAssets.nonBinaryLevel1Back,
        ),
      },
    },
  );

  // Add an appearance only when all six approved full-character renders exist:
  // male/female/non-binary, front and back, for every base milestone stage.
  static const List<RatAppearance> all = [base];

  static bool _isReleaseComplete(RatAppearance appearance) {
    if (!appearance.isComplete) return false;
    if (!base.approvedStages.every(appearance.stages.containsKey)) return false;
    return appearance.id == baseId ||
        appearance.approvedMotionContractVersion == motionContractVersion;
  }

  static RatAppearance byId(String? id) {
    for (final appearance in all) {
      if (appearance.id == id && _isReleaseComplete(appearance)) {
        return appearance;
      }
    }
    return base;
  }

  static bool isReady(String? id) =>
      id != null &&
      all.any(
        (appearance) => appearance.id == id && _isReleaseComplete(appearance),
      );

  static RatAppearance? byProductId(String productId) {
    for (final appearance in all) {
      if (appearance.productId == productId && _isReleaseComplete(appearance)) {
        return appearance;
      }
    }
    return null;
  }

  static String assetFor({
    required String? appearanceId,
    required RatGender gender,
    required RatAppearanceView view,
    int level = 1,
  }) => byId(appearanceId).assetFor(gender, view, level: level);

  static int approvedStageForLevel({
    required String? appearanceId,
    required int level,
  }) => byId(appearanceId).approvedStageForLevel(level);

  static bool hasDistinctStageAtLevel({
    required String? appearanceId,
    required int level,
  }) {
    final appearance = byId(appearanceId);
    final targetStage = EvolutionMilestones.stageForLevel(level);
    final previousStage = EvolutionMilestones.previousStageFor(targetStage);
    return targetStage != previousStage &&
        appearance.stages.containsKey(targetStage) &&
        appearance.stages.containsKey(previousStage);
  }
}

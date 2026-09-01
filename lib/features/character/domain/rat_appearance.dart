import '../../../core/assets/gymrat_assets.dart';
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
    required this.assetsByGender,
    this.productId,
  });

  final String id;
  final Map<RatGender, RatAppearanceAssets> assetsByGender;
  final String? productId;

  bool get isComplete => RatGender.values.every((gender) {
    final assets = assetsByGender[gender];
    return assets != null && assets.front.isNotEmpty && assets.back.isNotEmpty;
  });

  String assetFor(RatGender gender, RatAppearanceView view) {
    final assets = assetsByGender[gender];
    if (assets == null || !isComplete) {
      return RatAppearanceCatalog.base.assetFor(gender, view);
    }
    return assets.forView(view);
  }
}

abstract final class RatAppearanceCatalog {
  static const String baseId = 'base';

  static const RatAppearance base = RatAppearance(
    id: baseId,
    assetsByGender: {
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
  );

  // Add an appearance only when all six approved full-character renders exist:
  // male/female/non-binary, each from the front and back.
  static const List<RatAppearance> all = [base];

  static RatAppearance byId(String? id) {
    for (final appearance in all) {
      if (appearance.id == id && appearance.isComplete) return appearance;
    }
    return base;
  }

  static bool isReady(String? id) =>
      id != null &&
      all.any((appearance) => appearance.id == id && appearance.isComplete);

  static RatAppearance? byProductId(String productId) {
    for (final appearance in all) {
      if (appearance.productId == productId && appearance.isComplete) {
        return appearance;
      }
    }
    return null;
  }

  static String assetFor({
    required String? appearanceId,
    required RatGender gender,
    required RatAppearanceView view,
  }) => byId(appearanceId).assetFor(gender, view);
}

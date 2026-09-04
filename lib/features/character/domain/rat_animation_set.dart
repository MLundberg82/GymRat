import '../../../core/assets/gymrat_assets.dart';
import '../../profile/domain/training_profile.dart';
import 'rat_appearance.dart';
import 'rat_character_view.dart';

class RatAnimationSet {
  const RatAnimationSet({
    required this.neutral,
    this.breathing = const <String>[],
    this.blinking = const <String>[],
    this.tail = const <String>[],
  });

  final String neutral;
  final List<String> breathing;
  final List<String> blinking;
  final List<String> tail;

  bool get hasAuthoredBreathing => breathing.length >= 2;
  bool get hasAuthoredBlink => blinking.length >= 4;
  bool get hasAuthoredTail => tail.length >= 2;
  bool get isComplete =>
      hasAuthoredBreathing && hasAuthoredBlink && hasAuthoredTail;

  Iterable<String> get allFrames sync* {
    yield neutral;
    yield* breathing;
    yield* blinking;
    yield* tail;
  }
}

abstract final class RatAnimationCatalog {
  static RatAnimationSet forCharacter({
    required RatGender gender,
    required RatCharacterView view,
    required int level,
    String appearanceId = RatAppearanceCatalog.baseId,
  }) {
    final neutral = RatAppearanceCatalog.assetFor(
      appearanceId: appearanceId,
      gender: gender,
      view: switch (view) {
        RatCharacterView.front => RatAppearanceView.front,
        RatCharacterView.back => RatAppearanceView.back,
      },
      level: level,
    );
    final approvedStage = RatAppearanceCatalog.approvedStageForLevel(
      appearanceId: appearanceId,
      level: level,
    );

    if (appearanceId == RatAppearanceCatalog.baseId &&
        gender == RatGender.male &&
        view == RatCharacterView.front &&
        approvedStage == 1) {
      return RatAnimationSet(
        neutral: neutral,
        breathing: GymRatAssets.maleLevel1IdleFrames,
        blinking: GymRatAssets.maleLevel1BlinkFrames,
        tail: GymRatAssets.maleLevel1TailFrames,
      );
    }

    return RatAnimationSet(neutral: neutral);
  }

  static bool hasCompleteMotion({
    required RatGender gender,
    required RatCharacterView view,
    required int level,
    String appearanceId = RatAppearanceCatalog.baseId,
  }) => forCharacter(
    gender: gender,
    view: view,
    level: level,
    appearanceId: appearanceId,
  ).isComplete;
}

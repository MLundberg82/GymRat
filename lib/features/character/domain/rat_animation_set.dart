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
    this.emotes = const <List<String>>[],
  });

  final String neutral;
  final List<String> breathing;
  final List<String> blinking;
  final List<String> tail;
  final List<List<String>> emotes;

  bool get hasAuthoredBreathing => breathing.length >= 2;
  bool get hasAuthoredBlink => blinking.length >= 4;
  bool get hasAuthoredTail => tail.length >= 2;
  bool get hasAuthoredEmotes => emotes.any((frames) => frames.length >= 3);
  bool get hasAnyAuthoredMotion =>
      hasAuthoredBreathing ||
      hasAuthoredBlink ||
      hasAuthoredTail ||
      hasAuthoredEmotes;
  bool get isComplete =>
      hasAuthoredBreathing && hasAuthoredBlink && hasAuthoredTail;

  Iterable<String> get allFrames sync* {
    yield neutral;
    yield* breathing;
    yield* blinking;
    yield* tail;
    for (final emote in emotes) {
      yield* emote;
    }
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

    if (appearanceId == RatAppearanceCatalog.baseId && approvedStage == 1) {
      if (view == RatCharacterView.back) {
        final backFrames = switch (gender) {
          RatGender.male => GymRatAssets.maleLevel1BackIdleFrames,
          RatGender.female => GymRatAssets.femaleLevel1BackIdleFrames,
          RatGender.nonBinary => GymRatAssets.nonBinaryLevel1BackIdleFrames,
        };
        return RatAnimationSet(
          neutral: neutral,
          breathing: backFrames,
          tail: backFrames,
        );
      }

      return switch (gender) {
        RatGender.male => RatAnimationSet(
          neutral: neutral,
          breathing: GymRatAssets.maleLevel1IdleFrames,
          blinking: GymRatAssets.maleLevel1BlinkFrames,
          tail: GymRatAssets.maleLevel1TailFrames,
          emotes: const [GymRatAssets.maleLevel1EmoteFrames],
        ),
        RatGender.female => RatAnimationSet(
          neutral: neutral,
          breathing: GymRatAssets.femaleLevel1IdleFrames,
          blinking: GymRatAssets.femaleLevel1BlinkFrames,
          tail: GymRatAssets.femaleLevel1TailFrames,
          emotes: const [GymRatAssets.femaleLevel1EmoteFrames],
        ),
        RatGender.nonBinary => RatAnimationSet(
          neutral: neutral,
          breathing: GymRatAssets.nonBinaryLevel1IdleFrames,
          blinking: GymRatAssets.nonBinaryLevel1BlinkFrames,
          tail: GymRatAssets.nonBinaryLevel1TailFrames,
          emotes: const [GymRatAssets.nonBinaryLevel1EmoteFrames],
        ),
      };
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

  static bool hasAnyAuthoredMotion({
    required RatGender gender,
    required RatCharacterView view,
    required int level,
    String appearanceId = RatAppearanceCatalog.baseId,
  }) => forCharacter(
    gender: gender,
    view: view,
    level: level,
    appearanceId: appearanceId,
  ).hasAnyAuthoredMotion;
}

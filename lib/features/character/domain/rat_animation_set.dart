import '../../../core/assets/gymrat_assets.dart';
import '../../profile/domain/training_profile.dart';
import 'rat_appearance.dart';
import 'rat_character_view.dart';

enum RatEmoteType { doubleBiceps, chestFlex, legPose, triceps }

class RatEmoteSequence {
  const RatEmoteSequence({required this.type, required this.frames});

  final RatEmoteType type;
  final List<String> frames;
}

class RatAnimationSet {
  const RatAnimationSet({
    required this.neutral,
    this.breathing = const <String>[],
    this.blinking = const <String>[],
    this.tail = const <String>[],
    this.emotes = const <RatEmoteSequence>[],
  });

  final String neutral;
  final List<String> breathing;
  final List<String> blinking;
  final List<String> tail;
  final List<RatEmoteSequence> emotes;

  bool get hasAuthoredBreathing => breathing.length >= 2;
  bool get hasAuthoredBlink => blinking.length >= 4;
  bool get hasAuthoredTail => tail.length >= 2;
  bool get hasAuthoredEmotes =>
      emotes.any((sequence) => sequence.frames.length >= 3);
  bool get hasCompleteEmoteSet => RatEmoteType.values.every(
    (type) => emotes.any(
      (sequence) => sequence.type == type && sequence.frames.length >= 3,
    ),
  );
  bool get hasAnyAuthoredMotion =>
      hasAuthoredBreathing ||
      hasAuthoredBlink ||
      hasAuthoredTail ||
      hasAuthoredEmotes;
  bool get isComplete =>
      hasAuthoredBreathing &&
      hasAuthoredBlink &&
      hasAuthoredTail &&
      hasCompleteEmoteSet;

  Iterable<String> get allFrames sync* {
    yield neutral;
    yield* breathing;
    yield* blinking;
    yield* tail;
    for (final emote in emotes) {
      yield* emote.frames;
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
        return RatAnimationSet(
          neutral: neutral,
          breathing: _breathingFrames(gender: gender, view: view),
        );
      }

      return switch (gender) {
        RatGender.male => RatAnimationSet(
          neutral: neutral,
          breathing: _breathingFrames(gender: gender, view: view),
          blinking: GymRatAssets.maleLevel1BlinkFrames,
          tail: GymRatAssets.maleLevel1TailFrames,
        ),
        RatGender.female => RatAnimationSet(
          neutral: neutral,
          breathing: _breathingFrames(gender: gender, view: view),
          blinking: GymRatAssets.femaleLevel1BlinkFrames,
          tail: GymRatAssets.femaleLevel1TailFrames,
        ),
        RatGender.nonBinary => RatAnimationSet(
          neutral: neutral,
          breathing: _breathingFrames(gender: gender, view: view),
          blinking: GymRatAssets.nonBinaryLevel1BlinkFrames,
          tail: GymRatAssets.nonBinaryLevel1TailFrames,
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

  static bool hasAuthoredBreathing({
    required RatGender gender,
    required RatCharacterView view,
    required int level,
    String appearanceId = RatAppearanceCatalog.baseId,
  }) => forCharacter(
    gender: gender,
    view: view,
    level: level,
    appearanceId: appearanceId,
  ).hasAuthoredBreathing;

  static List<String> _breathingFrames({
    required RatGender gender,
    required RatCharacterView view,
  }) {
    final identity = switch (gender) {
      RatGender.male => 'male',
      RatGender.female => 'female',
      RatGender.nonBinary => 'non_binary',
    };
    final viewToken = switch (view) {
      RatCharacterView.front => 'front',
      RatCharacterView.back => 'back',
    };
    String frame(int index) =>
        'assets/characters/$identity/motion/level_01/$viewToken/'
        'breath_${index.toString().padLeft(2, '0')}.png';
    return <String>[
      frame(0),
      frame(1),
      frame(2),
      frame(3),
      frame(4),
      frame(3),
      frame(2),
      frame(1),
      frame(0),
    ];
  }
}

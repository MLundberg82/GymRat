import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/character/domain/rat_animation_set.dart';
import 'package:gymrat/features/character/presentation/gymrat_character.dart';
import 'package:gymrat/features/evolution/domain/evolution_milestones.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';

void main() {
  test('shared breathing curve expands and contracts', () {
    expect(GymRatCharacter.breathingScaleX(0), 1);
    expect(GymRatCharacter.breathingScaleX(.5), greaterThan(1));
    expect(GymRatCharacter.breathingScaleX(1), closeTo(1, .000001));

    final torso = GymRatCharacter.breathingTorsoRect(
      const Size(320, 600),
      RatCharacterView.front,
    );
    expect(torso.top, greaterThan(0));
    expect(torso.bottom, lessThan(600));
    expect(torso.height, lessThan(600 / 3));
    expect(torso.left, greaterThan(0));
    expect(torso.right, lessThan(320));
  });

  test('fallback power stance transforms but authored emotes stay stable', () {
    expect(GymRatCharacter.emoteScaleX(0), 1);
    expect(GymRatCharacter.emoteScaleX(.5), greaterThan(1));
    expect(GymRatCharacter.emoteScaleY(.5), lessThan(1));
    expect(GymRatCharacter.emoteDrop(.5), greaterThan(0));
    expect(GymRatCharacter.emoteScaleX(1), closeTo(1, .000001));
    expect(
      GymRatCharacter.emoteTransformProgress(
        progress: .5,
        hasAuthoredFrames: true,
      ),
      0,
    );
    expect(
      GymRatCharacter.emoteTransformProgress(
        progress: .5,
        hasAuthoredFrames: false,
      ),
      .5,
    );

    final blink = GymRatCharacter.blinkRect(const Size(320, 600));
    expect(blink.left, greaterThan(0));
    expect(blink.right, lessThan(320));
    expect(blink.top, greaterThan(0));
    expect(blink.bottom, lessThan(600 / 4));
  });

  test('every level-1 identity and view has authored motion', () {
    for (final gender in RatGender.values) {
      for (final view in RatCharacterView.values) {
        expect(
          GymRatCharacter.usesAuthoredSpriteFrames(
            gender: gender,
            view: view,
            level: 1,
          ),
          isTrue,
          reason: '${gender.name}/${view.name}',
        );
      }
    }
  });

  test('emote sequences are multi-frame and never cross gender', () {
    for (final gender in RatGender.values) {
      final set = RatAnimationCatalog.forCharacter(
        gender: gender,
        view: RatCharacterView.front,
        level: 1,
      );
      final genderFolder = switch (gender) {
        RatGender.male => '/male/',
        RatGender.female => '/female/',
        RatGender.nonBinary => '/non_binary/',
      };

      expect(set.emotes, isNotEmpty, reason: gender.name);
      for (final sequence in set.emotes) {
        expect(sequence.length, greaterThanOrEqualTo(5));
        expect(sequence.first, set.neutral);
        expect(sequence.last, set.neutral);
        expect(
          sequence,
          everyElement(contains(genderFolder)),
          reason: '${gender.name} must not use another identity',
        );
      }
    }
  });

  for (final gender in RatGender.values) {
    testWidgets('${gender.name} tap plays only its authored emote frames', (
      tester,
    ) async {
      final key = ValueKey('character-${gender.name}');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GymRatCharacter(
                key: key,
                height: 500,
                gender: gender,
                enableEmotes: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final gesture = find.descendant(
        of: find.byKey(key),
        matching: find.byType(GestureDetector),
      );
      final detector = tester.widget<GestureDetector>(gesture);
      expect(detector.onTap, isNotNull);
      detector.onTap!.call();
      await tester.pump(const Duration(milliseconds: 120));

      final image = tester.widget<Image>(find.byType(Image).last);
      final resized = image.image as ResizeImage;
      final asset = resized.imageProvider as AssetImage;
      final genderFolder = switch (gender) {
        RatGender.male => '/male/',
        RatGender.female => '/female/',
        RatGender.nonBinary => '/non_binary/',
      };

      expect(asset.assetName, contains('${genderFolder}level_01/emotes/'));
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'approved stage breathing frames cover every identity, view and level',
    () {
      for (var level = 1; level <= 100; level++) {
        for (final gender in RatGender.values) {
          for (final view in RatCharacterView.values) {
            expect(
              GymRatCharacter.usesAuthoredBreathingFrames(
                gender: gender,
                view: view,
                level: level,
              ),
              isTrue,
              reason: '$gender $view level $level',
            );
          }
        }
      }
    },
  );

  test(
    'front-only motion never leaks into a back view or another identity',
    () {
      for (final gender in RatGender.values) {
        final front = RatAnimationCatalog.forCharacter(
          gender: gender,
          view: RatCharacterView.front,
          level: 1,
        );
        final back = RatAnimationCatalog.forCharacter(
          gender: gender,
          view: RatCharacterView.back,
          level: 1,
        );
        final identityFolder = switch (gender) {
          RatGender.male => '/male/',
          RatGender.female => '/female/',
          RatGender.nonBinary => '/non_binary/',
        };

        expect(front.hasAuthoredBlink, isTrue, reason: gender.name);
        expect(front.hasAuthoredTail, isTrue, reason: gender.name);
        expect(front.hasAuthoredEmotes, isTrue, reason: gender.name);
        expect(front.isComplete, isTrue, reason: gender.name);
        expect(front.allFrames, everyElement(contains(identityFolder)));
        expect(back.hasAuthoredBreathing, isTrue, reason: gender.name);
        expect(back.hasAuthoredBlink, isFalse, reason: gender.name);
        expect(back.hasAuthoredTail, isFalse, reason: gender.name);
        expect(back.hasAuthoredEmotes, isFalse, reason: gender.name);
        expect(back.isComplete, isFalse, reason: gender.name);
        expect(back.allFrames, everyElement(contains(identityFolder)));
      }
    },
  );

  test('every evolution milestone resolves the approved breathing stage', () {
    for (final level in EvolutionMilestones.stages) {
      expect(
        GymRatCharacter.usesAuthoredBreathingFrames(
          gender: RatGender.nonBinary,
          view: RatCharacterView.back,
          level: level,
        ),
        isTrue,
      );
    }
  });

  for (final gender in RatGender.values) {
    testWidgets('${gender.name} supports front and back breathing views', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GymRatCharacter(
              height: 400,
              gender: gender,
              view: RatCharacterView.back,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 850));

      final images = tester.widgetList<Image>(find.byType(Image));
      final assetNames = images
          .map((image) => image.image)
          .whereType<ResizeImage>()
          .map((image) => image.imageProvider)
          .whereType<AssetImage>()
          .map((image) => image.assetName);

      expect(assetNames, contains(contains('level_01_back.png')));
      expect(
        assetNames.where((asset) => asset.startsWith('assets/items/')),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

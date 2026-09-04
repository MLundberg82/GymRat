import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/character/domain/rat_animation_set.dart';
import 'package:gymrat/features/character/presentation/gymrat_character.dart';
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

  test('power stance emote squats and settles without changing its asset', () {
    expect(GymRatCharacter.emoteScaleX(0), 1);
    expect(GymRatCharacter.emoteScaleX(.5), greaterThan(1));
    expect(GymRatCharacter.emoteScaleY(.5), lessThan(1));
    expect(GymRatCharacter.emoteDrop(.5), greaterThan(0));
    expect(GymRatCharacter.emoteScaleX(1), closeTo(1, .000001));
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

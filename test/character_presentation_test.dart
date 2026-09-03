import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/character/presentation/gymrat_character.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';

void main() {
  test('shared breathing curve expands and contracts', () {
    expect(GymRatCharacter.breathingScaleX(.25), greaterThan(1));
    expect(GymRatCharacter.breathingScaleX(.75), lessThan(1));

    final torso = GymRatCharacter.breathingTorsoRect(
      const Size(320, 600),
      RatCharacterView.front,
    );
    expect(torso.top, greaterThan(0));
    expect(torso.bottom, lessThan(600));
    expect(torso.height, lessThan(600 / 3));
  });

  test('power-flex emote grows every identity without changing its asset', () {
    expect(GymRatCharacter.emoteScaleX(0), 1);
    expect(GymRatCharacter.emoteScaleX(.5), greaterThan(1.03));
    expect(GymRatCharacter.emoteScaleY(.5), greaterThan(1));
    expect(GymRatCharacter.emoteScaleX(1), closeTo(1, .000001));
  });

  test('authored level-1 frames never leak across identity or view', () {
    expect(
      GymRatCharacter.usesAuthoredSpriteFrames(
        gender: RatGender.male,
        view: RatCharacterView.front,
        level: 1,
      ),
      isTrue,
    );
    expect(
      GymRatCharacter.usesAuthoredSpriteFrames(
        gender: RatGender.female,
        view: RatCharacterView.front,
        level: 1,
      ),
      isFalse,
    );
    expect(
      GymRatCharacter.usesAuthoredSpriteFrames(
        gender: RatGender.nonBinary,
        view: RatCharacterView.front,
        level: 1,
      ),
      isFalse,
    );
    expect(
      GymRatCharacter.usesAuthoredSpriteFrames(
        gender: RatGender.male,
        view: RatCharacterView.back,
        level: 1,
      ),
      isFalse,
    );
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

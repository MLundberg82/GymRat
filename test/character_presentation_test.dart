import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/character/domain/rat_animation_set.dart';
import 'package:gymrat/features/character/domain/rat_appearance.dart';
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

  test('emote playback uses a smooth blend without synthetic effects', () {
    final blink = GymRatCharacter.blinkRect(const Size(320, 600));
    expect(
      GymRatCharacter.frameBlendDuration,
      const Duration(milliseconds: 160),
    );
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

  test('all emotes are registered for every level, identity and view', () {
    for (var level = 1; level <= 100; level++) {
      for (final gender in RatGender.values) {
        for (final view in RatCharacterView.values) {
          final set = RatAnimationCatalog.forCharacter(
            gender: gender,
            view: view,
            level: level,
          );
          expect(
            set.emotes.map((emote) => emote.type).toSet(),
            RatEmoteType.values.toSet(),
            reason: '$level/${gender.name}/${view.name}',
          );
          expect(set.hasCompleteEmoteSet, isTrue);
          for (final emote in set.emotes) {
            expect(emote.frames, hasLength(48));
            expect(emote.frames.first, set.neutral);
            expect(emote.frames.last, set.neutral);
          }
        }
      }
    }
  });

  test('every release-ready appearance stage carries matching motion', () {
    for (final appearance in RatAppearanceCatalog.all) {
      if (!RatAppearanceCatalog.isReady(appearance.id)) continue;
      for (final stage in appearance.approvedStages) {
        for (final gender in RatGender.values) {
          for (final view in RatCharacterView.values) {
            final set = RatAnimationCatalog.forCharacter(
              gender: gender,
              view: view,
              level: stage,
              appearanceId: appearance.id,
            );
            expect(
              set.hasAuthoredBreathing,
              isTrue,
              reason: '${appearance.id}/$stage/${gender.name}/${view.name}',
            );
            expect(
              set.hasCompleteEmoteSet,
              isTrue,
              reason: '${appearance.id}/$stage/${gender.name}/${view.name}',
            );
          }
        }
      }
    }
  });

  for (final gender in RatGender.values) {
    testWidgets('${gender.name} plays an approved pose without body bounce', (
      tester,
    ) async {
      for (final view in RatCharacterView.values) {
        final key = ValueKey('${view.name}-character-${gender.name}');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: GymRatCharacter(
                  key: key,
                  height: 500,
                  gender: gender,
                  view: view,
                  enableEmotes: true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final character = find.byKey(key);
        final gesture = find.descendant(
          of: character,
          matching: find.byType(GestureDetector),
        );
        final detector = tester.widget<GestureDetector>(gesture);
        expect(detector.onTap, isNotNull);
        expect(
          find.descendant(
            of: character,
            matching: find.byType(AnimatedSwitcher),
          ),
          findsNothing,
        );
        detector.onTap!();
        await tester.pump(const Duration(milliseconds: 260));
        final animatedAssets = tester
            .widgetList<Image>(
              find.descendant(of: character, matching: find.byType(Image)),
            )
            .map((image) => image.image)
            .whereType<ResizeImage>()
            .map((image) => image.imageProvider)
            .whereType<AssetImage>()
            .map((image) => image.assetName);
        expect(animatedAssets, contains(contains('emote_')));
        expect(
          find.descendant(
            of: character,
            matching: find.byType(AnimatedSwitcher),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: character, matching: find.byType(CustomPaint)),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
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

  test('motion never leaks into another view or identity', () {
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
      expect(front.hasAuthoredTail, isFalse, reason: gender.name);
      expect(front.hasAuthoredEmotes, isTrue, reason: gender.name);
      expect(front.hasCompleteEmoteSet, isTrue, reason: gender.name);
      expect(front.isComplete, isFalse, reason: gender.name);
      expect(front.allFrames, everyElement(contains(identityFolder)));
      expect(back.hasAuthoredBreathing, isTrue, reason: gender.name);
      expect(back.hasAuthoredBlink, isFalse, reason: gender.name);
      expect(back.hasAuthoredTail, isFalse, reason: gender.name);
      expect(back.hasAuthoredEmotes, isTrue, reason: gender.name);
      expect(back.hasCompleteEmoteSet, isTrue, reason: gender.name);
      expect(back.isComplete, isFalse, reason: gender.name);
      expect(back.allFrames, everyElement(contains(identityFolder)));
    }
  });

  test('random emotes do not repeat when another authored pose exists', () {
    const doubleBiceps = RatEmoteSequence(
      type: RatEmoteType.doubleBiceps,
      frames: ['neutral', 'biceps', 'neutral'],
    );
    const chestFlex = RatEmoteSequence(
      type: RatEmoteType.chestFlex,
      frames: ['neutral', 'chest', 'neutral'],
    );

    final selected = GymRatCharacter.selectEmote(
      available: const [doubleBiceps, chestFlex],
      previousType: RatEmoteType.doubleBiceps,
      randomValue: 0,
    );

    expect(selected.type, RatEmoteType.chestFlex);
  });

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

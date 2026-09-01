import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/core/localization/gymrat_localizations.dart';
import 'package:gymrat/features/evolution/presentation/evolution_morph.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';

void main() {
  testWidgets('keeps opacity bounded while text reveal curve overshoots', (
    WidgetTester tester,
  ) async {
    expect(Curves.easeOutBack.transform(0.65), greaterThan(1.0));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GymRatLocalizations.delegate,
        ],
        home: EvolutionMorph(
          previousLevel: 4,
          newLevel: 5,
          duration: const Duration(seconds: 1),
          gender: RatGender.female,
          onComplete: () {},
        ),
      ),
    );

    for (var frame = 0; frame < 80; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull);
      for (final opacity in tester.widgetList<Opacity>(find.byType(Opacity))) {
        expect(opacity.opacity, inInclusiveRange(0.0, 1.0));
      }
    }

    final femaleAssets = tester
        .widgetList<Image>(find.byType(Image))
        .map(_assetName)
        .whereType<String>();
    expect(femaleAssets, contains('assets/characters/female/level_01.png'));
    expect(
      femaleAssets,
      isNot(contains('assets/characters/male/level_01.png')),
    );
  });
}

String? _assetName(Image image) {
  ImageProvider provider = image.image;
  while (provider is ResizeImage) {
    provider = provider.imageProvider;
  }
  return provider is AssetImage ? provider.assetName : null;
}

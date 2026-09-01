import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/core/localization/gymrat_localizations.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';
import 'package:gymrat/features/rewards/domain/gym_upgrade.dart';
import 'package:gymrat/features/rewards/presentation/level_up_celebration.dart';

void main() {
  testWidgets('level-up silhouette uses the selected rat identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GymRatLocalizations.delegate,
        ],
        home: LevelUpCelebration(
          previousLevel: 3,
          newLevel: 4,
          isEvolution: false,
          gender: RatGender.female,
          upgrade: GymUpgradeCatalog.forLevel(4),
        ),
      ),
    );
    await tester.pump();

    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>()
        .map((image) => image.assetName)
        .toList();

    expect(assets, contains('assets/characters/female/level_01.png'));
    expect(assets, isNot(contains('assets/characters/male/level_01.png')));
    expect(tester.takeException(), isNull);
  });
}

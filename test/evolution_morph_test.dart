import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/core/localization/gymrat_localizations.dart';
import 'package:gymrat/features/evolution/presentation/evolution_morph.dart';

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
  });
}

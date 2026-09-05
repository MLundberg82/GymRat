import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/core/localization/gymrat_localizations.dart';
import 'package:gymrat/core/theme/gymrat_theme.dart';
import 'package:gymrat/features/nutrition/data/nutrition_store.dart';
import 'package:gymrat/features/nutrition/presentation/nutrition_screen.dart';
import 'package:gymrat/features/profile/data/training_profile_store.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const profile = TrainingProfile(
    gender: RatGender.nonBinary,
    experience: TrainingExperience.intermediate,
    heightCm: 175,
    weightKg: 75,
    sessionsPerWeek: 4,
    goal: TrainingGoal.buildMuscle,
    ageYears: 30,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TrainingProfileStore.profile.value = profile;
  });

  tearDown(() {
    TrainingProfileStore.profile.value = null;
  });

  testWidgets('free Nutrition entry stays visibly gated', (tester) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(_testApp(premium: false));
    await tester.pumpAndSettle();

    expect(find.text('NUTRITION COMMAND CENTER'), findsOneWidget);
    expect(find.text('THE PREMIUM BLUEPRINT'), findsOneWidget);
    expect(find.text('LOG MEAL'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('Premium user can manually log a complete meal', (tester) async {
    await _setPhoneSurface(tester);
    await tester.pumpWidget(_testApp(premium: true));
    await tester.pumpAndSettle();

    expect(find.text('DAILY ENERGY TARGET'), findsOneWidget);
    await tester.tap(find.text('LOG MEAL'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Meal name'),
      'Power bowl',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calories (kcal)'),
      '650',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Protein (g)'),
      '45',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Carbohydrates (g)'),
      '70',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Fat (g)'), '20');
    await tester.tap(find.text('ADD TO TODAY'));
    await tester.pumpAndSettle();

    final saved = await NutritionStore.load();
    expect(saved, hasLength(1));
    expect(saved.single.calories, 650);
    expect(saved.single.proteinGrams, 45);
    await tester.drag(
      find.byType(ListView).last,
      const Offset(0, -650),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Power bowl'), findsOneWidget);
  });
}

Widget _testApp({required bool premium}) => MaterialApp(
  theme: GymRatTheme.dark,
  locale: const Locale('en'),
  supportedLocales: const <Locale>[Locale('en')],
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    GymRatLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: NutritionScreen(premiumOverride: premium),
);

Future<void> _setPhoneSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

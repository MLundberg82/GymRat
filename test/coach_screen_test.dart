import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/core/localization/gymrat_localizations.dart';
import 'package:gymrat/core/theme/gymrat_theme.dart';
import 'package:gymrat/features/coach/presentation/coach_screen.dart';
import 'package:gymrat/features/profile/data/training_profile_store.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('coach preview stays usable on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => TrainingProfileStore.profile.value = null);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TrainingProfileStore.profile.value = TrainingProfile.starter;

    await tester.pumpWidget(_app(const CoachScreen()));
    await tester.pumpAndSettle();

    expect(find.text('PREMIUM COACH PREVIEW'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.text('3 MISSIONS REMAINING'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('MISSION ROTATION'), 260);
    expect(find.text('MISSION ROTATION'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget home) => MaterialApp(
  theme: GymRatTheme.dark,
  locale: const Locale('en'),
  supportedLocales: const [Locale('en')],
  localizationsDelegates: const [
    GymRatLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

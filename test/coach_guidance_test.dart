import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/core/localization/gymrat_localizations.dart';
import 'package:gymrat/core/theme/gymrat_theme.dart';
import 'package:gymrat/features/workout/data/workout_presets.dart';
import 'package:gymrat/features/workout/domain/workout_models.dart';
import 'package:gymrat/features/workout/presentation/workout_preview_screen.dart';

void main() {
  testWidgets('coach guidance reaches preview and active workout sets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        const WorkoutPreviewScreen(
          preset: WorkoutPresets.chest,
          coachGuidance: WorkoutCoachGuidance(
            setCount: 2,
            repRange: '8–12',
            activeRecovery: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PREMIUM COACH MISSION'), findsOneWidget);
    expect(find.text('2 SETS · 8–12 REPS'), findsOneWidget);
    expect(find.text('2 SETS'), findsNWidgets(4));

    await tester.tap(find.text('START WORKOUT'));
    await tester.pumpAndSettle();

    expect(find.textContaining('COACH TARGET'), findsOneWidget);
    expect(find.textContaining('2 SETS · 8–12 REPS'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('recovery mission never invents a duration or load target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const WorkoutPreviewScreen(
          preset: WorkoutPresets.walk,
          coachGuidance: WorkoutCoachGuidance(
            setCount: 1,
            repRange: '—',
            activeRecovery: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('ACTIVE RECOVERY · MOVE AT YOUR OWN PACE'),
      findsOneWidget,
    );
    expect(find.textContaining('KG'), findsNothing);
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

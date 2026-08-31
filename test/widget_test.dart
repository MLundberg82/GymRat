import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/app/gymrat_app.dart';
import 'package:gymrat/core/localization/app_language_store.dart';
import 'package:gymrat/features/profile/data/training_profile_store.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';
import 'package:gymrat/features/workout/data/workout_session_store.dart';
import 'package:gymrat/features/workout/domain/workout_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('first launch creates a persistent training profile', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TrainingProfileStore.profile.value = null;
    AppLanguageStore.locale.value = const Locale('en');
    addTearDown(() => AppLanguageStore.locale.value = null);

    await tester.pumpWidget(const GymRatApp());
    await tester.pumpAndSettle();

    expect(find.text('FORGE YOUR GYMRAT'), findsOneWidget);
    await tester.tap(find.text('Female'));
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced'));
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build muscle'));
    await tester.tap(find.text('FORGE MY GYMRAT'));
    await tester.pumpAndSettle();

    expect(find.text('START WORKOUT'), findsOneWidget);
    expect(TrainingProfileStore.profile.value?.gender, RatGender.female);
    expect(
      TrainingProfileStore.profile.value?.experience,
      TrainingExperience.advanced,
    );
    expect(TrainingProfileStore.profile.value?.goal, TrainingGoal.buildMuscle);
  });

  testWidgets('GymRat app starts successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _prepareTrainingProfile();
    AppLanguageStore.locale.value = const Locale('en');
    addTearDown(() => AppLanguageStore.locale.value = null);
    await tester.pumpWidget(const GymRatApp());
    await tester.pump();

    expect(find.text('GYMRAT'), findsNothing);
    expect(find.text('START WORKOUT'), findsOneWidget);
    expect(find.text('LVL 1'), findsOneWidget);
  });

  testWidgets('GymRat hub uses the selected language', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _prepareTrainingProfile();
    AppLanguageStore.locale.value = const Locale('sv');
    addTearDown(() => AppLanguageStore.locale.value = null);
    await tester.pumpWidget(const GymRatApp());
    await tester.pump();

    expect(find.text('STARTA TRÄNING'), findsOneWidget);
    expect(find.text('NIVÅ 1'), findsOneWidget);
    expect(find.text('0 DAGAR'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Träning'), findsOneWidget);
    expect(find.text('Utveckling'), findsOneWidget);
    expect(find.text('Historik'), findsOneWidget);
    expect(find.text('Kost'), findsOneWidget);
    expect(find.text('Uppdrag'), findsOneWidget);
    expect(find.text('Gym Armory'), findsOneWidget);
    expect(find.text('Profil & Inställningar'), findsOneWidget);
    expect(find.text('GYMRAT PREMIUM COACH'), findsOneWidget);

    await tester.tap(find.text('Utveckling'));
    await tester.pumpAndSettle();

    expect(find.text('UTVECKLING'), findsOneWidget);
    expect(find.text('NIVÅ 1'), findsOneWidget);
    expect(find.text('TOTAL XP'), findsOneWidget);
    expect(find.text('PASS'), findsOneWidget);
    expect(find.text('SVIT'), findsOneWidget);
    expect(find.text('SENASTE PASSEN'), findsOneWidget);
    expect(
      find.text('Slutför ditt första pass för att starta historiken.'),
      findsOneWidget,
    );
  });

  testWidgets('Hub opens the real Quest Board and Gym Armory', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _prepareTrainingProfile();
    AppLanguageStore.locale.value = const Locale('en');
    addTearDown(() => AppLanguageStore.locale.value = null);

    await tester.pumpWidget(const GymRatApp());
    await tester.pumpAndSettle();

    expect(find.text('0/3'), findsOneWidget);
    await tester.tap(find.text('0/3'));
    await tester.pumpAndSettle();

    expect(find.text('QUEST BOARD'), findsOneWidget);
    expect(find.text('DAILY CONTRACTS'), findsOneWidget);
    expect(find.text('WEEKLY CAMPAIGN'), findsOneWidget);
    expect(find.text('ANSWER THE CALL'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gym Armory'));
    await tester.pumpAndSettle();

    expect(find.text('GYM ARMORY'), findsOneWidget);
    expect(find.text('YOUR GYM. YOUR LEGACY.'), findsOneWidget);
    expect(find.text('0 / 49'), findsOneWidget);

    await tester.tap(find.text('STORE'));
    await tester.pumpAndSettle();

    expect(find.text('THE PREMIUM VAULT'), findsOneWidget);
    expect(find.text('THE VAULT IS BEING FORGED'), findsOneWidget);
  });

  testWidgets('Progress shows persisted workout history', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _prepareTrainingProfile();
    await WorkoutSessionStore.complete(
      workoutName: 'CHEST',
      walk: false,
      durationSeconds: 1800,
      exercises: const <WorkoutExerciseResult>[
        WorkoutExerciseResult(
          name: 'Bench Press',
          muscleGroup: 'chest',
          sets: <WorkoutSetResult>[WorkoutSetResult(weight: 100, reps: 5)],
        ),
      ],
    );
    AppLanguageStore.locale.value = const Locale('en');
    addTearDown(() => AppLanguageStore.locale.value = null);

    await tester.pumpWidget(const GymRatApp());
    await tester.pump();
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();

    expect(find.text('PROGRESS'), findsOneWidget);
    expect(find.text('RECENT WORKOUTS'), findsOneWidget);
    expect(find.text('CHEST'), findsOneWidget);
    expect(find.textContaining('30 MIN'), findsOneWidget);
    expect(find.text('500 kg'), findsOneWidget);
  });

  testWidgets('History shows workout details and earned records', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _prepareTrainingProfile();
    await _completeHistoryWorkout(100);
    await _completeHistoryWorkout(105);
    AppLanguageStore.locale.value = const Locale('en');
    addTearDown(() => AppLanguageStore.locale.value = null);

    await tester.pumpWidget(const GymRatApp());
    await tester.pump();
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('TRAINING HISTORY'), findsOneWidget);
    expect(find.text('COMBAT LOG'), findsOneWidget);
    expect(find.text('RECORDS'), findsOneWidget);
    expect(find.text('TRAINING ARCHIVE'), findsOneWidget);
    expect(find.text('CHEST'), findsNWidgets(2));

    await tester.tap(find.text('CHEST').first);
    await tester.pumpAndSettle();

    expect(find.text('WORKOUT DETAILS'), findsOneWidget);
    expect(find.text('EXERCISE BREAKDOWN'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('105 kg'), findsOneWidget);
    expect(find.text('5 REPS'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RECORDS'));
    await tester.pumpAndSettle();

    expect(find.text('HALL OF RECORDS'), findsOneWidget);
    expect(find.text('1 RECORDS UNLOCKED'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('105 kg'), findsOneWidget);
    expect(find.text('+5 kg'), findsOneWidget);
  });

  testWidgets('History fits a narrow phone in Spanish', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _prepareTrainingProfile();
    AppLanguageStore.locale.value = const Locale('es');
    addTearDown(() => AppLanguageStore.locale.value = null);

    await tester.pumpWidget(const GymRatApp());
    await tester.pump();
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    expect(find.text('HISTORIAL DE ENTRENAMIENTO'), findsOneWidget);
    expect(find.text('REGISTRO DE COMBATE'), findsOneWidget);
    expect(find.text('RÉCORDS'), findsOneWidget);
    expect(find.text('NO HAY SESIONES REGISTRADAS'), findsOneWidget);
  });

  testWidgets('Workout entry flow uses the selected language', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _prepareTrainingProfile();
    AppLanguageStore.locale.value = const Locale('sv');
    addTearDown(() => AppLanguageStore.locale.value = null);
    await tester.pumpWidget(const GymRatApp());
    await tester.pump();

    await tester.tap(find.text('STARTA TRÄNING'));
    await tester.pumpAndSettle();

    expect(find.text('VÄLJ DITT\nPASS'), findsOneWidget);
    expect(find.text('Träna. Tjäna XP. Gå upp i nivå.'), findsOneWidget);
    expect(find.text('TRÄNING'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('WALK'), 300);

    expect(find.text('SVIT'), findsOneWidget);
    expect(
      find.text('Tidsinställd promenad · räknas mot din svit'),
      findsOneWidget,
    );

    await tester.tap(find.text('WALK'));
    await tester.pumpAndSettle();

    expect(find.text('FÖRHANDSVISNING'), findsOneWidget);
    expect(find.text('STARTA PROMENAD'), findsOneWidget);
    expect(find.text('TIDSINSTÄLLD PROMENAD'), findsOneWidget);
    expect(
      find.text('Gå så länge du vill. Passet räknas mot din svit.'),
      findsOneWidget,
    );

    await tester.tap(find.text('STARTA PROMENAD'));
    await tester.pumpAndSettle();

    expect(find.text('PROMENAD'), findsOneWidget);
    expect(find.text('REDO'), findsOneWidget);
    expect(find.text('STARTA'), findsOneWidget);
    expect(find.text('SLUTFÖR'), findsOneWidget);
  });

  testWidgets('Active strength workout uses the selected language', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _prepareTrainingProfile();
    AppLanguageStore.locale.value = const Locale('sv');
    addTearDown(() => AppLanguageStore.locale.value = null);
    await tester.pumpWidget(const GymRatApp());
    await tester.pump();

    await tester.tap(find.text('STARTA TRÄNING'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHEST'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('STARTA TRÄNING'));
    await tester.pumpAndSettle();

    expect(find.text('ÖVNING 1 / 4'), findsOneWidget);
    expect(find.text('VILA'), findsOneWidget);
    expect(find.text('REPS'), findsOneWidget);
    expect(find.text('NÄSTA ÖVNING'), findsOneWidget);

    final exerciseList = find.byType(ListView).last;
    await tester.drag(exerciseList, const Offset(0, -350));
    await tester.pump();
    expect(find.text('LÄGG TILL SET'), findsOneWidget);

    await tester.drag(exerciseList, const Offset(0, -150));
    await tester.pump();
    expect(find.text('TOTAL VOLYM'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('TIMERINSTÄLLNINGAR'), findsOneWidget);
    expect(find.text('SPARA'), findsOneWidget);
    expect(find.text('SETTIMER'), findsOneWidget);
    expect(find.text('VILOTIMER'), findsOneWidget);
    expect(find.text('AUTOMATISK VÄXLING'), findsOneWidget);
    expect(find.text('Växla automatiskt mellan set och vila.'), findsOneWidget);
  });
}

Future<WorkoutResult> _completeHistoryWorkout(double weight) {
  return WorkoutSessionStore.complete(
    workoutName: 'CHEST',
    walk: false,
    durationSeconds: 1800,
    exercises: <WorkoutExerciseResult>[
      WorkoutExerciseResult(
        name: 'Bench Press',
        muscleGroup: 'chest',
        sets: <WorkoutSetResult>[WorkoutSetResult(weight: weight, reps: 5)],
      ),
    ],
  );
}

Future<void> _prepareTrainingProfile() {
  return TrainingProfileStore.save(
    const TrainingProfile(
      gender: RatGender.nonBinary,
      experience: TrainingExperience.beginner,
      heightCm: 175,
      weightKg: 75,
      sessionsPerWeek: 3,
      goal: TrainingGoal.generalFitness,
    ),
  );
}

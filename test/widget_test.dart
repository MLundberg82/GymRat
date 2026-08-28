import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/app/gymrat_app.dart';
import 'package:gymrat/core/localization/app_language_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('GymRat app starts successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
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
    AppLanguageStore.locale.value = const Locale('sv');
    addTearDown(() => AppLanguageStore.locale.value = null);
    await tester.pumpWidget(const GymRatApp());
    await tester.pump();

    expect(find.text('STARTA TRÄNING'), findsOneWidget);
    expect(find.text('NIVÅ 1'), findsOneWidget);
    expect(find.text('0 DAGAR'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Träning'), findsOneWidget);
    expect(find.text('Utveckling'), findsOneWidget);
    expect(find.text('Historik'), findsOneWidget);
    expect(find.text('Kost'), findsOneWidget);
    expect(find.text('Utrustning & Butik'), findsOneWidget);
    expect(find.text('Profil & Inställningar'), findsOneWidget);
    expect(find.text('GymRat Premium'), findsOneWidget);
  });

  testWidgets('Workout entry flow uses the selected language', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
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
}

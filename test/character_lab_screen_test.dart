import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/core/localization/gymrat_localizations.dart';
import 'package:gymrat/features/character/presentation/character_lab_screen.dart';
import 'package:gymrat/features/character/presentation/gymrat_character.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';

void main() {
  testWidgets('character lab reviews every identity view and milestone', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const <Locale>[Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GymRatLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const CharacterLabScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Character Lab'), findsOneWidget);
    await tester.tap(find.text('Female'));
    await tester.pump();
    await tester.tap(find.text('Back view'));
    await tester.pump();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-900, 0),
    );
    await tester.pump();
    final level50 = find.byWidgetPredicate(
      (widget) => widget is Text && widget.data?.endsWith('50') == true,
    );
    await tester.tap(level50);
    await tester.pump();

    final character = tester.widget<GymRatCharacter>(
      find.byType(GymRatCharacter),
    );
    expect(character.gender, RatGender.female);
    expect(character.view, RatCharacterView.back);
    expect(character.level, 50);
    expect(find.textContaining('Approved asset stage:'), findsOneWidget);
    expect(
      find.text('assets/characters/female/level_01_back.png'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('character lab fits a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const <Locale>[Locale('es')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GymRatLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const CharacterLabScreen(),
      ),
    );
    await tester.pump();

    expect(find.byType(CharacterLabScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

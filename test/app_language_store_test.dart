import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/core/localization/app_language_store.dart';
import 'package:gymrat/core/localization/gymrat_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppLanguageStore.locale.value = null;
  });

  tearDown(() {
    AppLanguageStore.locale.value = null;
  });

  test('uses the system language by default', () async {
    await AppLanguageStore.initialize();

    expect(AppLanguageStore.locale.value, isNull);
    expect(AppLanguageStore.currentCode(), 'system');
  });

  test('persists and restores an explicit language', () async {
    await AppLanguageStore.setLanguage('sv');
    expect(AppLanguageStore.locale.value, const Locale('sv'));

    AppLanguageStore.locale.value = null;
    await AppLanguageStore.initialize();

    expect(AppLanguageStore.locale.value, const Locale('sv'));
    expect(AppLanguageStore.currentCode(), 'sv');
  });

  test('restores system language after clearing an override', () async {
    await AppLanguageStore.setLanguage('sv');
    await AppLanguageStore.setLanguage('system');

    AppLanguageStore.locale.value = const Locale('en');
    await AppLanguageStore.initialize();

    expect(AppLanguageStore.locale.value, isNull);
    expect(AppLanguageStore.currentCode(), 'system');
  });

  test('history and record copy exists in every supported language', () {
    const keys = <String>[
      'trainingHistory',
      'combatLog',
      'records',
      'trainingArchive',
      'emptyHistoryTitle',
      'workoutDetails',
      'exerciseBreakdown',
      'recordVault',
      'recordsUnlocked',
      'noRecordsTitle',
      'baseline',
      'previousBest',
      'totalGain',
      'recordBreaks',
      'historyLoadError',
    ];

    for (final locale in AppLanguageStore.supported) {
      final translations = GymRatLocalizations(locale);
      for (final key in keys) {
        expect(
          translations.t(key),
          isNot(key),
          reason: '$key is missing for ${locale.languageCode}',
        );
      }
    }
  });
}

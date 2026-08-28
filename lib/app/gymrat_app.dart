import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/localization/app_language_store.dart';
import '../core/localization/gymrat_localizations.dart';
import '../core/theme/gymrat_theme.dart';
import '../features/hub/presentation/hub_screen.dart';

class GymRatApp extends StatelessWidget {
  const GymRatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: AppLanguageStore.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'GymRat',
          debugShowCheckedModeBanner: false,
          theme: GymRatTheme.dark,
          locale: locale,
          supportedLocales: AppLanguageStore.supported,
          localizationsDelegates: const [
            GymRatLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (device, supported) {
            if (locale != null) return locale;
            if (device != null) {
              for (final supportedLocale in supported) {
                if (supportedLocale.languageCode == device.languageCode) {
                  return supportedLocale;
                }
              }
            }
            return const Locale('en');
          },
          home: const HubScreen(),
        );
      },
    );
  }
}

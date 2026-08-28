import 'package:flutter/material.dart';

import 'gymrat_colors.dart';

abstract final class GymRatTheme {
  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: GymRatColors.green,
          brightness: Brightness.dark,
        ).copyWith(
          primary: GymRatColors.green,
          onPrimary: GymRatColors.black,
          secondary: GymRatColors.gold,
          onSecondary: GymRatColors.black,
          tertiary: GymRatColors.premium,
          error: GymRatColors.danger,
          surface: GymRatColors.surface,
          onSurface: GymRatColors.textPrimary,
        );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: GymRatColors.background,
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: GymRatColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: GymRatColors.black,
        indicatorColor: GymRatColors.green.withValues(alpha: 0.14),
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final isSelected = states.contains(WidgetState.selected);

          return TextStyle(
            color: isSelected ? GymRatColors.green : GymRatColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          final isSelected = states.contains(WidgetState.selected);

          return IconThemeData(
            color: isSelected ? GymRatColors.green : GymRatColors.textMuted,
            size: 24,
          );
        }),
      ),
      dividerColor: GymRatColors.border,
    );
  }
}

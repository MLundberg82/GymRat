import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeightUnit { kilograms, pounds }

abstract final class WeightUnitStore {
  static const _key = 'gymrat-workout-weight-unit-v1';
  static const _poundsPerKilogram = 2.2046226218;

  static final ValueNotifier<WeightUnit> unit = ValueNotifier(
    WeightUnit.kilograms,
  );

  static WeightUnit get current => unit.value;
  static String get symbol => current == WeightUnit.kilograms ? 'kg' : 'lb';
  static String get symbolUpper => symbol.toUpperCase();

  static String codeFor(WeightUnit value) =>
      value == WeightUnit.pounds ? 'lb' : 'kg';

  static WeightUnit fromCode(String? value) =>
      value == 'lb' ? WeightUnit.pounds : WeightUnit.kilograms;

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    unit.value = fromCode(preferences.getString(_key));
  }

  static Future<void> setUnit(WeightUnit value) async {
    unit.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, codeFor(value));
  }

  static double fromKilograms(double value, {WeightUnit? unit}) {
    final selected = unit ?? current;
    return selected == WeightUnit.pounds ? value * _poundsPerKilogram : value;
  }

  static double toKilograms(double value, {WeightUnit? unit}) {
    final selected = unit ?? current;
    return selected == WeightUnit.pounds ? value / _poundsPerKilogram : value;
  }

  static String formatKilograms(
    double value, {
    bool includeUnit = true,
    int fractionDigits = 1,
  }) {
    final displayed = fromKilograms(value);
    final rounded = displayed.roundToDouble();
    final number = displayed == rounded
        ? displayed.toStringAsFixed(0)
        : displayed.toStringAsFixed(fractionDigits);
    return includeUnit ? '$number $symbol' : number;
  }

  static String formatVolume(double kilograms, {bool compact = false}) {
    final displayed = fromKilograms(kilograms);
    final number = compact ? _compact(displayed) : displayed.round().toString();
    return '$number $symbol';
  }

  static String _compact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.round().toString();
  }
}

import 'weight_unit_store.dart';

enum BodyMeasurementSystem { metric, imperial }

abstract final class BodyMeasurementUnits {
  static const centimetersPerInch = 2.54;
  static const inchesPerFoot = 12;

  static BodyMeasurementSystem systemFor(WeightUnit unit) =>
      unit == WeightUnit.pounds
      ? BodyMeasurementSystem.imperial
      : BodyMeasurementSystem.metric;

  static WeightUnit weightUnitFor(BodyMeasurementSystem system) =>
      system == BodyMeasurementSystem.imperial
      ? WeightUnit.pounds
      : WeightUnit.kilograms;

  static ({int feet, int inches}) feetAndInchesFromCentimeters(
    int centimeters,
  ) {
    final totalInches = (centimeters / centimetersPerInch).round();
    return (
      feet: totalInches ~/ inchesPerFoot,
      inches: totalInches % inchesPerFoot,
    );
  }

  static int centimetersFromFeetAndInches(int feet, int inches) =>
      ((feet * inchesPerFoot + inches) * centimetersPerInch).round();

  static String formatHeight(
    int centimeters, {
    required BodyMeasurementSystem system,
  }) {
    if (system == BodyMeasurementSystem.metric) return '$centimeters cm';
    final imperial = feetAndInchesFromCentimeters(centimeters);
    return '${imperial.feet} ft ${imperial.inches} in';
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/core/units/body_measurement_units.dart';
import 'package:gymrat/core/units/weight_unit_store.dart';

void main() {
  test('converts height between metric and imperial units', () {
    expect(BodyMeasurementUnits.feetAndInchesFromCentimeters(175), (
      feet: 5,
      inches: 9,
    ));
    expect(BodyMeasurementUnits.centimetersFromFeetAndInches(5, 9), 175);
  });

  test('maps the saved weight unit to the body measurement system', () {
    expect(
      BodyMeasurementUnits.systemFor(WeightUnit.kilograms),
      BodyMeasurementSystem.metric,
    );
    expect(
      BodyMeasurementUnits.systemFor(WeightUnit.pounds),
      BodyMeasurementSystem.imperial,
    );
  });
}

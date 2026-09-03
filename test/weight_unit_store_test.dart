import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/core/units/weight_unit_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await WeightUnitStore.initialize();
  });

  test('stores the selected workout weight unit', () async {
    await WeightUnitStore.setUnit(WeightUnit.pounds);
    await WeightUnitStore.initialize();

    expect(WeightUnitStore.current, WeightUnit.pounds);
    expect(WeightUnitStore.symbol, 'lb');
  });

  test('round trips canonical kilogram values through pounds', () {
    final pounds = WeightUnitStore.fromKilograms(100, unit: WeightUnit.pounds);
    final kilograms = WeightUnitStore.toKilograms(
      pounds,
      unit: WeightUnit.pounds,
    );

    expect(pounds, closeTo(220.462, .001));
    expect(kilograms, closeTo(100, .0001));
  });
}

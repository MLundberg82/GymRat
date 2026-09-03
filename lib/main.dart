import 'package:flutter/material.dart';

import 'app/gymrat_app.dart';
import 'core/localization/app_language_store.dart';
import 'core/units/weight_unit_store.dart';
import 'features/armory/data/armory_billing.dart';
import 'features/profile/data/training_profile_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguageStore.initialize();
  await WeightUnitStore.initialize();
  await TrainingProfileStore.initialize();
  await ArmoryBilling.initialize();
  runApp(const GymRatApp());
}

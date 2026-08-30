import 'package:flutter/material.dart';

import 'app/gymrat_app.dart';
import 'core/localization/app_language_store.dart';
import 'features/armory/data/armory_billing.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguageStore.initialize();
  await ArmoryBilling.initialize();
  runApp(const GymRatApp());
}

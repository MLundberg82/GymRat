import 'package:flutter/material.dart';

import 'app/gymrat_app.dart';
import 'core/localization/app_language_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguageStore.initialize();
  runApp(const GymRatApp());
}

import 'package:flutter/material.dart';

import '../core/theme/gymrat_theme.dart';
import 'gymrat_shell.dart';

class GymRatApp extends StatelessWidget {
  const GymRatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymRat',
      debugShowCheckedModeBanner: false,
      theme: GymRatTheme.dark,
      home: const GymRatShell(),
    );
  }
}
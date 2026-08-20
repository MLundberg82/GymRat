import 'package:flutter/material.dart';

import '../../../core/theme/gymrat_colors.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 56,
            color: GymRatColors.info,
          ),
          SizedBox(height: 18),
          Text(
            'PROGRESS',
            style: TextStyle(
              color: GymRatColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Levels, XP and progression come next',
            style: TextStyle(
              color: GymRatColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
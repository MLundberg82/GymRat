import 'package:flutter/material.dart';

import '../../../core/theme/gymrat_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_rounded,
            size: 56,
            color: GymRatColors.textSecondary,
          ),
          SizedBox(height: 18),
          Text(
            'PROFILE',
            style: TextStyle(
              color: GymRatColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Profile and settings come later',
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
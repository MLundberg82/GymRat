import 'package:flutter/material.dart';

import '../../../core/theme/gymrat_colors.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeaturePlaceholder(
      icon: Icons.fitness_center_rounded,
      title: 'WORKOUT',
      subtitle: 'Workout flow comes next',
      accentColor: GymRatColors.green,
    );
  }
}

class _FeaturePlaceholder extends StatelessWidget {
  const _FeaturePlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 56,
            color: accentColor,
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: GymRatColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: GymRatColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
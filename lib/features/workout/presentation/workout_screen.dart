import 'package:flutter/material.dart';

import '../../../core/theme/gymrat_colors.dart';
import '../data/workout_presets.dart';
import '../domain/workout_models.dart';
import 'workout_preview_screen.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  void _openPreset(BuildContext context, WorkoutPreset preset) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutPreviewScreen(preset: preset)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymRatColors.black,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  const Text(
                    'CHOOSE YOUR\nSESSION',
                    style: TextStyle(
                      color: GymRatColors.textPrimary,
                      fontSize: 30,
                      height: 0.98,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Train. Earn XP. Level up.',
                    style: TextStyle(
                      color: GymRatColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...WorkoutPresets.free.map(
                    (preset) => _WorkoutRow(
                      preset: preset,
                      onTap: () => _openPreset(context, preset),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _PremiumWorkoutRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: GymRatColors.textPrimary,
          ),
          const SizedBox(width: 2),
          const Text(
            'WORKOUT',
            style: TextStyle(
              color: GymRatColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({required this.preset, required this.onTap});

  final WorkoutPreset preset;
  final VoidCallback onTap;

  IconData get _icon {
    if (preset.isWalk) return Icons.directions_walk_rounded;

    switch (preset.id) {
      case 'chest':
        return Icons.fitness_center_rounded;
      case 'back':
        return Icons.vertical_align_center_rounded;
      case 'legs':
        return Icons.directions_run_rounded;
      case 'arms':
        return Icons.sports_gymnastics_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  String get _exerciseText {
    if (preset.isWalk) {
      return 'Timed walk · counts toward your streak';
    }

    return preset.exercises.map((exercise) => exercise.name).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: GymRatColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: GymRatColors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(_icon, color: GymRatColors.green, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        preset.title,
                        style: const TextStyle(
                          color: GymRatColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 9),
                      if (preset.isWalk) const _Tag(text: 'STREAK'),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preset.subtitle,
                    style: const TextStyle(
                      color: GymRatColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _exerciseText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GymRatColors.textMuted,
                      fontSize: 10.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              color: GymRatColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: GymRatColors.green.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: GymRatColors.green,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _PremiumWorkoutRow extends StatelessWidget {
  const _PremiumWorkoutRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: GymRatColors.premium.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: GymRatColors.premium),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUSTOM WORKOUT',
                  style: TextStyle(
                    color: GymRatColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Build your own session from the full exercise library.',
                  style: TextStyle(
                    color: GymRatColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'PREMIUM',
            style: TextStyle(
              color: GymRatColors.premium,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

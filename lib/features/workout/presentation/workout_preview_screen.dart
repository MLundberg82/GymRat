import 'package:flutter/material.dart';

import '../../../core/theme/gymrat_colors.dart';
import '../domain/workout_models.dart';
import 'active_workout_screen.dart';
import 'walk_workout_screen.dart';

class WorkoutPreviewScreen extends StatelessWidget {
  const WorkoutPreviewScreen({super.key, required this.preset});

  final WorkoutPreset preset;

  void _start(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => preset.isWalk
            ? WalkWorkoutScreen(preset: preset)
            : ActiveWorkoutScreen(preset: preset),
      ),
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  Text(
                    preset.title,
                    style: const TextStyle(
                      color: GymRatColors.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preset.subtitle,
                    style: const TextStyle(color: GymRatColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  if (preset.isWalk)
                    const _WalkPreview()
                  else
                    for (var i = 0; i < preset.exercises.length; i++)
                      _ExerciseRow(
                        number: i + 1,
                        exercise: preset.exercises[i],
                      ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: () => _start(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: GymRatColors.green,
                    foregroundColor: GymRatColors.black,
                  ),
                  child: Text(
                    preset.isWalk ? 'START WALK' : 'START WORKOUT',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
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
          ),
          const Text(
            'PREVIEW',
            style: TextStyle(
              color: GymRatColors.textSecondary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.number, required this.exercise});

  final int number;
  final WorkoutExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: GymRatColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              number.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: GymRatColors.green,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              exercise.name,
              style: const TextStyle(
                color: GymRatColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '${exercise.defaultSets} SETS',
            style: const TextStyle(
              color: GymRatColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkPreview extends StatelessWidget {
  const _WalkPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.directions_walk_rounded,
            color: GymRatColors.green,
            size: 34,
          ),
          SizedBox(height: 14),
          Text(
            'TIMED WALK',
            style: TextStyle(
              color: GymRatColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Walk for as long as you want. The session counts toward your streak.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GymRatColors.textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}

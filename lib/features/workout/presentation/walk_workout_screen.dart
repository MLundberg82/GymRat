import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/gymrat_colors.dart';
import '../data/workout_session_store.dart';
import '../domain/workout_models.dart';
import 'workout_complete_screen.dart';

class WalkWorkoutScreen extends StatefulWidget {
  const WalkWorkoutScreen({super.key, required this.preset});
  final WorkoutPreset preset;
  @override
  State<WalkWorkoutScreen> createState() => _WalkWorkoutScreenState();
}

class _WalkWorkoutScreenState extends State<WalkWorkoutScreen> {
  Timer? timer;
  int elapsed = 0;
  bool running = false, finishing = false;

  String get display {
    final h = elapsed ~/ 3600, m = (elapsed % 3600) ~/ 60, s = elapsed % 60;
    if (h > 0)
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toggle() {
    if (running) {
      timer?.cancel();
      setState(() => running = false);
      return;
    }
    setState(() => running = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => elapsed++);
    });
  }

  Future<void> _finish() async {
    if (finishing) return;
    timer?.cancel();
    setState(() {
      running = false;
      finishing = true;
    });
    final result = await WorkoutSessionStore.complete(
      workoutName: widget.preset.title,
      walk: true,
      durationSeconds: elapsed,
      exercises: const [],
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => WorkoutCompleteScreen(result: result)),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GymRatColors.black,
    appBar: AppBar(title: const Text('WALK')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            const Icon(
              Icons.directions_walk_rounded,
              color: GymRatColors.green,
              size: 48,
            ),
            const SizedBox(height: 22),
            Text(
              display,
              style: const TextStyle(
                color: GymRatColors.textPrimary,
                fontSize: 58,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              running ? 'WALK IN PROGRESS' : 'READY',
              style: const TextStyle(
                color: GymRatColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: FilledButton(
                      onPressed: finishing ? null : _toggle,
                      style: FilledButton.styleFrom(
                        backgroundColor: GymRatColors.green,
                        foregroundColor: GymRatColors.black,
                      ),
                      child: Text(
                        running ? 'PAUSE' : 'START',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 58,
                  child: OutlinedButton(
                    onPressed: elapsed > 0 && !finishing ? _finish : null,
                    child: Text(finishing ? 'SAVING...' : 'FINISH'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

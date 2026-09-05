import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../../core/units/weight_unit_store.dart';
import '../../armory/data/rat_inventory_store.dart';
import '../../premium/data/premium_access.dart';
import '../data/workout_draft_store.dart';
import '../data/workout_session_store.dart';
import '../domain/workout_draft.dart';
import '../domain/workout_models.dart';
import 'session_journal_card.dart';
import 'workout_complete_screen.dart';

class WalkWorkoutScreen extends StatefulWidget {
  const WalkWorkoutScreen({super.key, required this.preset});
  final WorkoutPreset preset;
  @override
  State<WalkWorkoutScreen> createState() => _WalkWorkoutScreenState();
}

class _WalkWorkoutScreenState extends State<WalkWorkoutScreen> {
  Timer? timer;
  Timer? draftSaveTimer;
  final TextEditingController noteController = TextEditingController();
  Future<void> draftSave = Future<void>.value();
  int elapsed = 0;
  int? effortRating;
  bool running = false, finishing = false;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final draft = await WorkoutDraftStore.loadForPreset(widget.preset.id);
    if (!mounted || draft == null) return;
    setState(() {
      elapsed = draft.elapsedSeconds.clamp(0, 60 * 60 * 24);
      noteController.text = draft.sessionNote;
      effortRating = draft.effortRating;
    });
    if (draft.hasEnteredData || draft.elapsedSeconds > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.t('workoutRestored'))),
        );
      });
    }
  }

  WorkoutDraft _draft() => WorkoutDraft(
    presetId: widget.preset.id,
    exerciseIndex: 0,
    elapsedSeconds: elapsed,
    savedAt: DateTime.now(),
    sets: const <String, List<WorkoutSetDraft>>{},
    sessionNote: noteController.text,
    effortRating: effortRating,
    weightUnit: WeightUnitStore.codeFor(WeightUnitStore.current),
  );

  Future<void> _saveDraft() {
    final snapshot = _draft();
    draftSave = draftSave
        .then((_) => WorkoutDraftStore.save(snapshot))
        .catchError((_) {});
    return draftSave;
  }

  void _scheduleDraftSave() {
    draftSaveTimer?.cancel();
    draftSaveTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_saveDraft()),
    );
  }

  String get display {
    final h = elapsed ~/ 3600, m = (elapsed % 3600) ~/ 60, s = elapsed % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
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
      if (!mounted) return;
      setState(() => elapsed++);
      if (elapsed % 10 == 0) unawaited(_saveDraft());
    });
  }

  Future<void> _finish() async {
    if (finishing) return;
    timer?.cancel();
    draftSaveTimer?.cancel();
    setState(() {
      running = false;
      finishing = true;
    });
    final inventoryFuture = RatInventoryStore.load();
    final result = await WorkoutSessionStore.complete(
      workoutName: widget.preset.title,
      walk: true,
      durationSeconds: elapsed,
      exercises: const [],
      sessionNote: noteController.text,
      effortRating: effortRating,
      premiumXPBoost: PremiumAccess.current,
    );
    try {
      await draftSave;
      await WorkoutDraftStore.clear();
    } catch (_) {
      // A stale draft must never block an otherwise completed walk.
    }
    RatInventoryState inventory;
    try {
      inventory = await inventoryFuture;
    } catch (_) {
      inventory = const RatInventoryState();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorkoutCompleteScreen(
          result: result,
          appearanceId: inventory.equippedAppearanceId,
          characterView: inventory.characterView,
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    draftSaveTimer?.cancel();
    if (!finishing) unawaited(_saveDraft());
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GymRatColors.black,
    appBar: AppBar(title: Text(context.tr.t('walkTitle'))),
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
              context.tr.t(running ? 'walkInProgress' : 'ready'),
              style: const TextStyle(
                color: GymRatColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 22),
            SessionJournalCard(
              noteController: noteController,
              effortRating: effortRating,
              onEffortChanged: (value) => setState(() => effortRating = value),
              onChanged: _scheduleDraftSave,
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
                        context.tr.t(running ? 'pause' : 'start'),
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
                    child: Text(context.tr.t(finishing ? 'saving' : 'finish')),
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

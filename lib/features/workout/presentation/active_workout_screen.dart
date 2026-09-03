import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../../core/units/weight_unit_store.dart';
import '../../armory/data/rat_inventory_store.dart';
import '../data/workout_draft_store.dart';
import '../data/workout_session_store.dart';
import '../domain/workout_draft.dart';
import '../domain/workout_models.dart';
import '../domain/workout_result.dart';
import '../domain/workout_timer_settings.dart';
import 'session_journal_card.dart';
import 'timer_settings_screen.dart';
import 'workout_copy.dart';
import 'workout_complete_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({
    super.key,
    required this.preset,
    this.coachGuidance,
  });
  final WorkoutPreset preset;
  final WorkoutCoachGuidance? coachGuidance;
  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

enum _TimerMode { set, rest }

class _SetEntry {
  _SetEntry()
    : weight = TextEditingController(),
      reps = TextEditingController();
  final TextEditingController weight, reps;
  void dispose() {
    weight.dispose();
    reps.dispose();
  }
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final Map<String, List<_SetEntry>> sets = {};
  final TextEditingController noteController = TextEditingController();
  Timer? workoutTimer, intervalTimer;
  Timer? draftSaveTimer;
  Future<void> draftSave = Future<void>.value();
  late final WeightUnit weightUnit;
  int exerciseIndex = 0, elapsedSeconds = 0;
  int? effortRating;
  late WorkoutTimerSettings timerSettings;
  late int remainingSeconds;
  _TimerMode timerMode = _TimerMode.rest;
  bool timerRunning = false, finishing = false, draftRestored = false;
  WorkoutExercise get exercise => widget.preset.exercises[exerciseIndex];

  @override
  void initState() {
    super.initState();
    weightUnit = WeightUnitStore.current;
    timerSettings = WorkoutTimerStore.current;
    remainingSeconds = timerSettings.restSeconds;
    for (final e in widget.preset.exercises) {
      sets[e.name] = List.generate(
        widget.coachGuidance?.setCount ?? e.defaultSets,
        (_) => _SetEntry(),
      );
    }
    _restoreDraft();
    workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => elapsedSeconds++);
      if (elapsedSeconds % 10 == 0) unawaited(_saveDraft());
    });
  }

  Future<void> _restoreDraft() async {
    final draft = await WorkoutDraftStore.loadForPreset(widget.preset.id);
    if (!mounted || draft == null) return;
    for (final exercise in widget.preset.exercises) {
      final saved = draft.sets[exercise.name];
      if (saved == null || saved.isEmpty) continue;
      final current = sets[exercise.name]!;
      for (final entry in current) {
        entry.dispose();
      }
      sets[exercise.name] = saved
          .map(
            (value) => _SetEntry()
              ..weight.text = _restoredWeight(value.weight, draft.weightUnit)
              ..reps.text = value.reps,
          )
          .toList();
    }
    setState(() {
      elapsedSeconds = draft.elapsedSeconds.clamp(0, 60 * 60 * 24);
      exerciseIndex = draft.exerciseIndex.clamp(
        0,
        widget.preset.exercises.length - 1,
      );
      noteController.text = draft.sessionNote;
      effortRating = draft.effortRating;
      draftRestored = draft.hasEnteredData || draft.elapsedSeconds > 0;
    });
  }

  String _restoredWeight(String raw, String savedUnitCode) {
    if (raw.trim().isEmpty) return raw;
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null) return raw;
    final kilograms = WeightUnitStore.toKilograms(
      value,
      unit: WeightUnitStore.fromCode(savedUnitCode),
    );
    final displayed = WeightUnitStore.fromKilograms(
      kilograms,
      unit: weightUnit,
    );
    return displayed == displayed.roundToDouble()
        ? displayed.toStringAsFixed(0)
        : displayed.toStringAsFixed(1);
  }

  WorkoutDraft _draft() => WorkoutDraft(
    presetId: widget.preset.id,
    exerciseIndex: exerciseIndex,
    elapsedSeconds: elapsedSeconds,
    savedAt: DateTime.now(),
    sessionNote: noteController.text,
    effortRating: effortRating,
    weightUnit: WeightUnitStore.codeFor(weightUnit),
    sets: sets.map(
      (name, entries) => MapEntry(
        name,
        entries
            .map(
              (entry) => WorkoutSetDraft(
                weight: entry.weight.text,
                reps: entry.reps.text,
              ),
            )
            .toList(growable: false),
      ),
    ),
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

  String get sessionTime =>
      '${elapsedSeconds ~/ 60}:${(elapsedSeconds % 60).toString().padLeft(2, '0')}';
  String get timerTime =>
      '${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}';

  double get totalVolume {
    var total = 0.0;
    for (final list in sets.values) {
      for (final e in list) {
        total +=
            (double.tryParse(e.weight.text.replaceAll(',', '.')) ?? 0) *
            (int.tryParse(e.reps.text) ?? 0);
      }
    }
    return total;
  }

  void _addSet() {
    setState(() => sets[exercise.name]!.add(_SetEntry()));
    _scheduleDraftSave();
  }

  void _removeSet(int i) {
    final l = sets[exercise.name]!;
    if (l.length <= 1) return;
    l[i].dispose();
    setState(() => l.removeAt(i));
    _scheduleDraftSave();
  }

  void _resetIntervalTimer() {
    intervalTimer?.cancel();
    setState(() {
      timerRunning = false;
      remainingSeconds = timerMode == _TimerMode.set
          ? timerSettings.setSeconds
          : timerSettings.restSeconds;
    });
  }

  void _toggleIntervalTimer() {
    if (timerRunning) {
      intervalTimer?.cancel();
      setState(() => timerRunning = false);
      return;
    }
    setState(() => timerRunning = true);
    intervalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (remainingSeconds > 1) {
        setState(() => remainingSeconds--);
        return;
      }
      if (!timerSettings.autoLoop) {
        intervalTimer?.cancel();
        setState(() {
          remainingSeconds = 0;
          timerRunning = false;
        });
        return;
      }
      setState(() {
        timerMode = timerMode == _TimerMode.set
            ? _TimerMode.rest
            : _TimerMode.set;
        remainingSeconds = timerMode == _TimerMode.set
            ? timerSettings.setSeconds
            : timerSettings.restSeconds;
      });
    });
  }

  void _switchTimerMode() {
    intervalTimer?.cancel();
    setState(() {
      timerRunning = false;
      timerMode = timerMode == _TimerMode.set
          ? _TimerMode.rest
          : _TimerMode.set;
      remainingSeconds = timerMode == _TimerMode.set
          ? timerSettings.setSeconds
          : timerSettings.restSeconds;
    });
  }

  Future<void> _openTimerSettings() async {
    intervalTimer?.cancel();
    setState(() => timerRunning = false);
    final r = await Navigator.of(context).push<WorkoutTimerSettings>(
      MaterialPageRoute(builder: (_) => const TimerSettingsScreen()),
    );
    if (!mounted || r == null) return;
    setState(() {
      timerSettings = r;
      remainingSeconds = timerMode == _TimerMode.set
          ? r.setSeconds
          : r.restSeconds;
    });
  }

  Future<void> _finish() async {
    if (finishing) return;
    final results = widget.preset.exercises
        .map((e) {
          final completed = sets[e.name]!
              .map(
                (s) => WorkoutSetResult(
                  weight: WeightUnitStore.toKilograms(
                    double.tryParse(s.weight.text.replaceAll(',', '.')) ?? 0,
                    unit: weightUnit,
                  ),
                  reps: int.tryParse(s.reps.text) ?? 0,
                ),
              )
              .where((s) => s.weight > 0 && s.reps > 0)
              .toList();
          return WorkoutExerciseResult(
            name: e.name,
            muscleGroup: widget.preset.id,
            sets: completed,
          );
        })
        .where((exercise) => exercise.sets.isNotEmpty)
        .toList(growable: false);
    if (results.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr.t('completeOneSet'))));
      return;
    }
    setState(() => finishing = true);
    draftSaveTimer?.cancel();
    workoutTimer?.cancel();
    intervalTimer?.cancel();
    final inventoryFuture = RatInventoryStore.load();
    final result = await WorkoutSessionStore.complete(
      workoutName: widget.preset.title,
      walk: false,
      durationSeconds: elapsedSeconds,
      exercises: results,
      sessionNote: noteController.text,
      effortRating: effortRating,
    );
    try {
      await draftSave;
      await WorkoutDraftStore.clear();
    } catch (_) {
      // A stale draft must never block an otherwise completed workout.
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
    workoutTimer?.cancel();
    intervalTimer?.cancel();
    draftSaveTimer?.cancel();
    if (!finishing) unawaited(_saveDraft());
    noteController.dispose();
    for (final l in sets.values) {
      for (final e in l) {
        e.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSets = sets[exercise.name]!;
    return Scaffold(
      backgroundColor: GymRatColors.black,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: WorkoutCopy.workout(context, widget.preset.title),
              time: sessionTime,
              onBack: () => Navigator.of(context).pop(),
            ),
            _TimerBar(
              mode: timerMode,
              time: timerTime,
              running: timerRunning,
              onStartPause: _toggleIntervalTimer,
              onReset: _resetIntervalTimer,
              onMode: _switchTimerMode,
              onSettings: _openTimerSettings,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                children: [
                  Text(
                    '${context.tr.t('exercise')} ${exerciseIndex + 1} / '
                    '${widget.preset.exercises.length}',
                    style: const TextStyle(
                      color: GymRatColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    WorkoutCopy.exercise(context, exercise.name),
                    style: const TextStyle(
                      color: GymRatColors.textPrimary,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.7,
                    ),
                  ),
                  if (widget.coachGuidance case final guidance?) ...[
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: GymRatColors.premium,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${context.tr.t('coachTargetLabel')}  '
                            '${guidance.setCount} ${context.tr.t('sets')} · '
                            '${guidance.repRange} ${context.tr.t('reps')}',
                            style: const TextStyle(
                              color: GymRatColors.premium,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (draftRestored) ...[
                    const SizedBox(height: 10),
                    _DraftRestoredBadge(
                      onDismiss: () => setState(() => draftRestored = false),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SetHeader(unit: weightUnit),
                  for (var i = 0; i < currentSets.length; i++)
                    _SetRow(
                      index: i,
                      entry: currentSets[i],
                      onRemove: () => _removeSet(i),
                      onChanged: () {
                        setState(() {});
                        _scheduleDraftSave();
                      },
                    ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _addSet,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.tr.t('addSet')),
                    style: TextButton.styleFrom(
                      foregroundColor: GymRatColors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SessionJournalCard(
                    noteController: noteController,
                    effortRating: effortRating,
                    onEffortChanged: (value) =>
                        setState(() => effortRating = value),
                    onChanged: _scheduleDraftSave,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        context.tr.t('totalVolume'),
                        style: const TextStyle(
                          color: GymRatColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${totalVolume.round()} '
                        '${weightUnit == WeightUnit.kilograms ? 'KG' : 'LB'}',
                        style: const TextStyle(
                          color: GymRatColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _WorkoutNavigation(
              canBack: exerciseIndex > 0,
              isLast: exerciseIndex == widget.preset.exercises.length - 1,
              loading: finishing,
              onBack: () {
                setState(() => exerciseIndex--);
                _scheduleDraftSave();
              },
              onNext: () {
                if (exerciseIndex < widget.preset.exercises.length - 1) {
                  setState(() => exerciseIndex++);
                  _scheduleDraftSave();
                } else {
                  _finish();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftRestoredBadge extends StatelessWidget {
  const _DraftRestoredBadge({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
      decoration: BoxDecoration(
        color: GymRatColors.green.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GymRatColors.greenDark),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.restore_rounded,
            color: GymRatColors.green,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr.t('workoutRestored'),
              style: const TextStyle(
                color: GymRatColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 16),
          ),
        ],
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.time,
    required this.onBack,
  });
  final String title, time;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const Spacer(),
        Text(
          time,
          style: const TextStyle(
            color: GymRatColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _TimerBar extends StatelessWidget {
  const _TimerBar({
    required this.mode,
    required this.time,
    required this.running,
    required this.onStartPause,
    required this.onReset,
    required this.onMode,
    required this.onSettings,
  });
  final _TimerMode mode;
  final String time;
  final bool running;
  final VoidCallback onStartPause, onReset, onMode, onSettings;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        InkWell(
          onTap: onMode,
          child: Text(
            context.tr.t(mode == _TimerMode.set ? 'setLabel' : 'rest'),
            style: const TextStyle(
              color: GymRatColors.green,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          time,
          style: const TextStyle(
            color: GymRatColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onStartPause,
          icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded),
        ),
        IconButton(onPressed: onReset, icon: const Icon(Icons.stop_rounded)),
        IconButton(onPressed: onSettings, icon: const Icon(Icons.tune_rounded)),
      ],
    ),
  );
}

class _SetHeader extends StatelessWidget {
  const _SetHeader({required this.unit});

  final WeightUnit unit;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 40, child: Text(context.tr.t('setLabel'))),
      Expanded(child: Text(unit == WeightUnit.kilograms ? 'KG' : 'LB')),
      const SizedBox(width: 12),
      Expanded(child: Text(context.tr.t('reps'))),
      const SizedBox(width: 42),
    ],
  );
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });
  final int index;
  final _SetEntry entry;
  final VoidCallback onRemove, onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: _Input(
            controller: entry.weight,
            decimal: true,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Input(
            controller: entry.reps,
            decimal: false,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 42,
          child: IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              size: 17,
              color: GymRatColors.textMuted,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.decimal,
    required this.onChanged,
  });
  final TextEditingController controller;
  final bool decimal;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: (_) => onChanged(),
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        decimal ? RegExp(r'^\d{0,4}([.,]\d{0,2})?') : RegExp(r'^\d{0,4}'),
      ),
    ],
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: GymRatColors.textPrimary,
      fontWeight: FontWeight.w800,
    ),
    decoration: InputDecoration(
      isDense: true,
      filled: true,
      fillColor: GymRatColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class _WorkoutNavigation extends StatelessWidget {
  const _WorkoutNavigation({
    required this.canBack,
    required this.isLast,
    required this.loading,
    required this.onBack,
    required this.onNext,
  });
  final bool canBack, isLast, loading;
  final VoidCallback onBack, onNext;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
    child: Row(
      children: [
        SizedBox(
          width: 54,
          height: 54,
          child: OutlinedButton(
            onPressed: canBack && !loading ? onBack : null,
            child: const Icon(Icons.chevron_left_rounded),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: loading ? null : onNext,
              style: FilledButton.styleFrom(
                backgroundColor: GymRatColors.green,
                foregroundColor: GymRatColors.black,
              ),
              child: Text(
                loading
                    ? context.tr.t('saving')
                    : isLast
                    ? context.tr.t('finishWorkout')
                    : context.tr.t('nextExercise'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../domain/workout_timer_settings.dart';

class TimerSettingsScreen extends StatefulWidget {
  const TimerSettingsScreen({super.key});

  @override
  State<TimerSettingsScreen> createState() => _TimerSettingsScreenState();
}

class _TimerSettingsScreenState extends State<TimerSettingsScreen> {
  late WorkoutTimerSettings settings;

  @override
  void initState() {
    super.initState();
    settings = WorkoutTimerStore.current;
  }

  void _save() {
    WorkoutTimerStore.current = settings;
    Navigator.of(context).pop(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymRatColors.black,
      appBar: AppBar(
        title: Text(context.tr.t('timerSettings')),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              context.tr.t('save'),
              style: const TextStyle(
                color: GymRatColors.green,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _TimerSetting(
            title: context.tr.t('setTimer'),
            value: settings.setSeconds,
            min: 30,
            max: 120,
            step: 15,
            onChanged: (value) =>
                setState(() => settings = settings.copyWith(setSeconds: value)),
          ),
          const SizedBox(height: 28),
          _TimerSetting(
            title: context.tr.t('restTimer'),
            value: settings.restSeconds,
            min: 30,
            max: 180,
            step: 15,
            onChanged: (value) => setState(
              () => settings = settings.copyWith(restSeconds: value),
            ),
          ),
          const SizedBox(height: 30),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: GymRatColors.green,
            title: Text(
              context.tr.t('autoLoop'),
              style: const TextStyle(
                color: GymRatColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              context.tr.t('autoLoopDescription'),
              style: const TextStyle(color: GymRatColors.textSecondary),
            ),
            value: settings.autoLoop,
            onChanged: (value) =>
                setState(() => settings = settings.copyWith(autoLoop: value)),
          ),
        ],
      ),
    );
  }
}

class _TimerSetting extends StatelessWidget {
  const _TimerSetting({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final steps = ((max - min) / step).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: GymRatColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${value}s',
          style: const TextStyle(
            color: GymRatColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: steps,
          activeColor: GymRatColors.green,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

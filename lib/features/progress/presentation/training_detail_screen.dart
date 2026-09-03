import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../../core/units/weight_unit_store.dart';
import '../../workout/data/workout_session_store.dart';
import '../../workout/presentation/workout_copy.dart';
import '../domain/training_analytics.dart';
import 'progress_line_chart.dart';

class WorkoutCategoryDetailScreen extends StatelessWidget {
  const WorkoutCategoryDetailScreen({
    super.key,
    required this.history,
    required this.category,
  });

  final TrainingHistorySnapshot history;
  final WorkoutCategoryTrend category;

  @override
  Widget build(BuildContext context) {
    final unit = category.isWalk
        ? context.tr.t('minutesShort')
        : WeightUnitStore.symbolUpper;
    return Scaffold(
      backgroundColor: GymRatColors.black,
      appBar: AppBar(
        backgroundColor: GymRatColors.black,
        foregroundColor: GymRatColors.textPrimary,
        title: Text(
          WorkoutCopy.workout(context, category.name),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _HeroPanel(category: category, unit: unit),
          const SizedBox(height: 24),
          if (category.exerciseNames.isNotEmpty) ...[
            _SectionTitle(context.tr.t('exerciseProgress')),
            const SizedBox(height: 12),
            for (final exerciseName in category.exerciseNames) ...[
              _ExerciseTile(
                trend: TrainingAnalytics.exercise(history, exerciseName),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExerciseProgressScreen(
                      trend: TrainingAnalytics.exercise(history, exerciseName),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 14),
          _SectionTitle(context.tr.t('sessionHistory')),
          const SizedBox(height: 12),
          if (category.sessions.isEmpty)
            _Empty(message: context.tr.t('noCategoryHistory'))
          else
            for (final session in category.sessions.reversed) ...[
              _SessionTile(session: session),
              const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }
}

enum _ExerciseMetricType { personalBest, estimatedStrength, volume }

enum _TrainingWindow { fourWeeks, threeMonths, oneYear, all }

class ExerciseProgressScreen extends StatefulWidget {
  const ExerciseProgressScreen({super.key, required this.trend});

  final ExerciseTrend trend;

  @override
  State<ExerciseProgressScreen> createState() => _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends State<ExerciseProgressScreen> {
  _ExerciseMetricType metric = _ExerciseMetricType.personalBest;
  _TrainingWindow window = _TrainingWindow.all;

  ExerciseTrend get trend => widget.trend;

  List<TrainingPoint> _visible(List<TrainingPoint> points) {
    if (points.isEmpty || window == _TrainingWindow.all) return points;
    final latest = points.last.date;
    final cutoff = switch (window) {
      _TrainingWindow.fourWeeks => latest.subtract(const Duration(days: 28)),
      _TrainingWindow.threeMonths => latest.subtract(const Duration(days: 92)),
      _TrainingWindow.oneYear => latest.subtract(const Duration(days: 365)),
      _TrainingWindow.all => DateTime.fromMillisecondsSinceEpoch(0),
    };
    return points.where((point) => !point.date.isBefore(cutoff)).toList();
  }

  List<TrainingPoint> get _metricPoints => _visible(
    switch (metric) {
      _ExerciseMetricType.personalBest => trend.personalBestPath,
      _ExerciseMetricType.estimatedStrength => trend.estimatedStrength,
      _ExerciseMetricType.volume => trend.sessionVolumes,
    }.map(_displayWeightPoint).toList(growable: false),
  );

  Color get _metricColor => switch (metric) {
    _ExerciseMetricType.personalBest => GymRatColors.gold,
    _ExerciseMetricType.estimatedStrength => GymRatColors.premium,
    _ExerciseMetricType.volume => GymRatColors.green,
  };

  String _metricLabel(BuildContext context) => switch (metric) {
    _ExerciseMetricType.personalBest => context.tr.t('personalBestJourney'),
    _ExerciseMetricType.estimatedStrength => context.tr.t('estimatedStrength'),
    _ExerciseMetricType.volume => context.tr.t('sessionVolume'),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GymRatColors.black,
    appBar: AppBar(
      backgroundColor: GymRatColors.black,
      foregroundColor: GymRatColors.textPrimary,
      title: Text(
        WorkoutCopy.exercise(context, trend.exerciseName),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2B2208),
                GymRatColors.surface,
                Color(0xFF0C0B08),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: GymRatColors.goldDark),
            boxShadow: [
              BoxShadow(
                color: GymRatColors.gold.withValues(alpha: .10),
                blurRadius: 28,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.t('personalBestJourney'),
                style: const TextStyle(
                  color: GymRatColors.gold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Metric(
                    label: context.tr.t('personalBest'),
                    value: WeightUnitStore.formatKilograms(trend.currentBest),
                  ),
                  _Metric(
                    label: context.tr.t('estimatedStrength'),
                    value: WeightUnitStore.formatKilograms(
                      trend.currentEstimatedStrength,
                    ),
                  ),
                  _Metric(
                    label: context.tr.t('sessionVolume'),
                    value: WeightUnitStore.formatVolume(
                      trend.latestVolume,
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MetricSelector(
                value: metric,
                onChanged: (value) => setState(() => metric = value),
              ),
              const SizedBox(height: 10),
              _WindowSelector(
                value: window,
                onChanged: (value) => setState(() => window = value),
              ),
              const SizedBox(height: 18),
              ProgressLineChart(
                points: _metricPoints,
                color: _metricColor,
                height: 210,
                semanticLabel: _metricLabel(context),
              ),
              if (metric == _ExerciseMetricType.estimatedStrength) ...[
                const SizedBox(height: 10),
                Text(
                  context.tr.t('estimatedStrengthInfo'),
                  style: const TextStyle(
                    color: GymRatColors.textMuted,
                    fontSize: 9,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        _SectionTitle(context.tr.t('sessionBestHistory')),
        const SizedBox(height: 12),
        for (final point in _visible(trend.sessionBests).reversed)
          _PointTile(
            point: point,
            isPersonalBest:
                point.value == WeightUnitStore.fromKilograms(trend.currentBest),
          ),
      ],
    ),
  );
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({required this.value, required this.onChanged});

  final _ExerciseMetricType value;
  final ValueChanged<_ExerciseMetricType> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<_ExerciseMetricType>(
    segments: [
      ButtonSegment(
        value: _ExerciseMetricType.personalBest,
        label: Text(context.tr.t('personalBestShort')),
      ),
      ButtonSegment(
        value: _ExerciseMetricType.estimatedStrength,
        label: Text(context.tr.t('estimatedStrengthShort')),
      ),
      ButtonSegment(
        value: _ExerciseMetricType.volume,
        label: Text(context.tr.t('volumeShort')),
      ),
    ],
    selected: {value},
    showSelectedIcon: false,
    onSelectionChanged: (selection) => onChanged(selection.single),
    style: const ButtonStyle(visualDensity: VisualDensity.compact),
  );
}

class _WindowSelector extends StatelessWidget {
  const _WindowSelector({required this.value, required this.onChanged});

  final _TrainingWindow value;
  final ValueChanged<_TrainingWindow> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    children: _TrainingWindow.values
        .map((option) {
          final selected = option == value;
          final label = switch (option) {
            _TrainingWindow.fourWeeks => context.tr.t('fourWeeks'),
            _TrainingWindow.threeMonths => context.tr.t('threeMonths'),
            _TrainingWindow.oneYear => context.tr.t('oneYear'),
            _TrainingWindow.all => context.tr.t('allTime'),
          };
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onChanged(option),
            labelStyle: TextStyle(
              color: selected ? GymRatColors.black : GymRatColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
            selectedColor: GymRatColors.gold,
            backgroundColor: GymRatColors.surfaceElevated,
            side: BorderSide(
              color: selected ? GymRatColors.gold : GymRatColors.border,
            ),
            visualDensity: VisualDensity.compact,
          );
        })
        .toList(growable: false),
  );
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.category, required this.unit});

  final WorkoutCategoryTrend category;
  final String unit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D281A), GymRatColors.surface, Color(0xFF090D0B)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: GymRatColors.greenDark),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              category.isWalk
                  ? context.tr.t('durationTrend')
                  : context.tr.t('volumeTrend'),
              style: const TextStyle(
                color: GymRatColors.green,
                fontWeight: FontWeight.w900,
                letterSpacing: .9,
              ),
            ),
            const Spacer(),
            Text(
              '${category.sessions.length} ${context.tr.t('sessions')}',
              style: const TextStyle(
                color: GymRatColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          category.isWalk
              ? '${_compact(category.latestValue)} $unit'
              : WeightUnitStore.formatVolume(
                  category.latestValue,
                  compact: true,
                ),
          style: const TextStyle(
            color: GymRatColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ProgressLineChart(
          points: category.isWalk
              ? category.primaryMetric
              : category.primaryMetric
                    .map(_displayWeightPoint)
                    .toList(growable: false),
          semanticLabel: WorkoutCopy.workout(context, category.name),
        ),
      ],
    ),
  );
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.trend, required this.onTap});

  final ExerciseTrend trend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: GymRatColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.show_chart_rounded, color: GymRatColors.gold),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    WorkoutCopy.exercise(context, trend.exerciseName),
                    style: const TextStyle(
                      color: GymRatColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trend.sessionBests.length} ${context.tr.t('sessions')} · '
                    '+${WeightUnitStore.formatKilograms(trend.totalGain)}',
                    style: const TextStyle(
                      color: GymRatColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              WeightUnitStore.formatKilograms(trend.currentBest),
              style: const TextStyle(
                color: GymRatColors.gold,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: GymRatColors.textMuted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final WorkoutHistoryEntry session;

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(session.completedAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GymRatColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              date,
              style: const TextStyle(
                color: GymRatColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            session.isWalk
                ? '${(session.durationSeconds / 60).round()} ${context.tr.t('minutesShort')}'
                : WeightUnitStore.formatVolume(session.volume, compact: true),
            style: const TextStyle(
              color: GymRatColors.green,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointTile extends StatelessWidget {
  const _PointTile({required this.point, required this.isPersonalBest});
  final TrainingPoint point;
  final bool isPersonalBest;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPersonalBest ? GymRatColors.goldDark : GymRatColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              MaterialLocalizations.of(context).formatMediumDate(point.date),
              style: const TextStyle(
                color: GymRatColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${_weight(point.value)} ${WeightUnitStore.symbol}',
            style: TextStyle(
              color: isPersonalBest
                  ? GymRatColors.gold
                  : GymRatColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: GymRatColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: GymRatColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: GymRatColors.textPrimary,
      fontSize: 13,
      fontWeight: FontWeight.w900,
      letterSpacing: 1,
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: GymRatColors.textSecondary),
    ),
  );
}

String _weight(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

String _compact(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return _weight(value);
}

TrainingPoint _displayWeightPoint(TrainingPoint point) => TrainingPoint(
  date: point.date,
  value: WeightUnitStore.fromKilograms(point.value),
);

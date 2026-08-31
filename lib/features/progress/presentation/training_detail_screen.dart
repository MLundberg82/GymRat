import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../workout/data/workout_session_store.dart';
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
    final unit = category.isWalk ? context.tr.t('minutesShort') : 'KG';
    return Scaffold(
      backgroundColor: GymRatColors.black,
      appBar: AppBar(
        backgroundColor: GymRatColors.black,
        foregroundColor: GymRatColors.textPrimary,
        title: Text(
          category.name,
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

class ExerciseProgressScreen extends StatelessWidget {
  const ExerciseProgressScreen({super.key, required this.trend});

  final ExerciseTrend trend;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GymRatColors.black,
    appBar: AppBar(
      backgroundColor: GymRatColors.black,
      foregroundColor: GymRatColors.textPrimary,
      title: Text(
        trend.exerciseName,
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
                    label: context.tr.t('baseline'),
                    value: '${_weight(trend.baseline)} kg',
                  ),
                  _Metric(
                    label: context.tr.t('personalBest'),
                    value: '${_weight(trend.currentBest)} kg',
                  ),
                  _Metric(
                    label: context.tr.t('totalGain'),
                    value: '+${_weight(trend.totalGain)} kg',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ProgressLineChart(
                points: trend.personalBestPath,
                color: GymRatColors.gold,
                height: 210,
                semanticLabel: context.tr.t('personalBestJourney'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _SectionTitle(context.tr.t('sessionBestHistory')),
        const SizedBox(height: 12),
        for (final point in trend.sessionBests.reversed)
          _PointTile(
            point: point,
            isPersonalBest: point.value == trend.currentBest,
          ),
      ],
    ),
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
          '${_compact(category.latestValue)} $unit',
          style: const TextStyle(
            color: GymRatColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ProgressLineChart(
          points: category.primaryMetric,
          semanticLabel: category.name,
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
                    trend.exerciseName,
                    style: const TextStyle(
                      color: GymRatColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trend.sessionBests.length} ${context.tr.t('sessions')} · +${_weight(trend.totalGain)} kg',
                    style: const TextStyle(
                      color: GymRatColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${_weight(trend.currentBest)} kg',
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
                : '${_compact(session.volume)} kg',
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
            '${_weight(point.value)} kg',
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

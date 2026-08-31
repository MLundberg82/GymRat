import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../progress/domain/training_analytics.dart';
import '../../progress/presentation/progress_line_chart.dart';
import '../../progress/presentation/training_detail_screen.dart';
import '../../workout/data/workout_session_store.dart';

class PersonalBestsView extends StatelessWidget {
  const PersonalBestsView({
    super.key,
    required this.history,
    required this.onRefresh,
  });

  final TrainingHistorySnapshot history;
  final Future<void> Function() onRefresh;

  List<PersonalBestRecord> get records => history.personalBests;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: GymRatColors.gold,
      backgroundColor: GymRatColors.surfaceElevated,
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey<String>('personal-bests'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          _RecordVaultHeader(recordCount: records.length),
          const SizedBox(height: 22),
          if (records.isEmpty)
            _EmptyRecords(
              title: context.tr.t('noRecordsTitle'),
              message: context.tr.t('noRecordsMessage'),
            )
          else
            for (var index = 0; index < records.length; index++) ...[
              _RecordCard(
                record: records[index],
                rank: index + 1,
                trend: TrainingAnalytics.exercise(
                  history,
                  records[index].exerciseName,
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _RecordVaultHeader extends StatelessWidget {
  const _RecordVaultHeader({required this.recordCount});

  final int recordCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2A2108), GymRatColors.surface, Color(0xFF11100A)],
      ),
      border: Border.all(color: GymRatColors.goldDark),
      boxShadow: [
        BoxShadow(
          color: GymRatColors.gold.withValues(alpha: .11),
          blurRadius: 28,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GymRatColors.gold.withValues(alpha: .12),
            border: Border.all(color: GymRatColors.gold.withValues(alpha: .6)),
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: GymRatColors.gold,
            size: 33,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.t('recordVault'),
                style: const TextStyle(
                  color: GymRatColors.gold,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.tr.t('recordVaultSubtitle'),
                style: const TextStyle(
                  color: GymRatColors.textSecondary,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$recordCount ${context.tr.t('recordsUnlocked')}',
                style: const TextStyle(
                  color: GymRatColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.rank,
    required this.trend,
  });

  final PersonalBestRecord record;
  final int rank;
  final ExerciseTrend trend;

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(record.achievedAt);
    return Material(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExerciseProgressScreen(trend: trend),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: GymRatColors.goldDark.withValues(alpha: .7),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: GymRatColors.gold.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: GymRatColors.gold.withValues(alpha: .35),
                      ),
                    ),
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                        color: GymRatColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.exerciseName,
                          style: const TextStyle(
                            color: GymRatColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          date,
                          style: const TextStyle(
                            color: GymRatColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_weight(record.weight)} kg',
                        style: const TextStyle(
                          color: GymRatColors.gold,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '+${_weight(record.totalImprovement)} kg',
                        style: const TextStyle(
                          color: GymRatColors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        context.tr.t('totalGain'),
                        style: const TextStyle(
                          color: GymRatColors.textMuted,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .4,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: GymRatColors.goldDark,
                        size: 19,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: GymRatColors.gold.withValues(alpha: .15),
              ),
              const SizedBox(height: 14),
              ProgressLineChart(
                points: trend.personalBestPath,
                color: GymRatColors.gold,
                height: 92,
                semanticLabel: context.tr.t('personalBestJourney'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RecordMetric(
                      label: context.tr.t('baseline'),
                      value: '${_weight(record.baselineWeight)} kg',
                    ),
                  ),
                  Expanded(
                    child: _RecordMetric(
                      label: context.tr.t('previousBest'),
                      value: '${_weight(record.previousBest)} kg',
                    ),
                  ),
                  Expanded(
                    child: _RecordMetric(
                      label: context.tr.t('recordBreaks'),
                      value: '${record.improvementCount}',
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

  static String _weight(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class _RecordMetric extends StatelessWidget {
  const _RecordMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: GymRatColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: GymRatColors.textMuted,
          fontSize: 7,
          fontWeight: FontWeight.w800,
          letterSpacing: .35,
        ),
      ),
    ],
  );
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.military_tech_outlined,
          color: GymRatColors.goldDark,
          size: 42,
        ),
        const SizedBox(height: 13),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GymRatColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GymRatColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

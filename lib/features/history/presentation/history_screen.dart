import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../premium/data/premium_access.dart';
import '../../premium/presentation/premium_gate_card.dart';
import '../../workout/data/workout_session_store.dart';
import '../../workout/presentation/workout_copy.dart';
import 'personal_bests_view.dart';
import 'workout_history_detail_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryData {
  const _HistoryData({required this.history, required this.isPremium});
  final TrainingHistorySnapshot history;
  final bool isPremium;
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<_HistoryData> _history;

  @override
  void initState() {
    super.initState();
    _history = _load();
  }

  Future<_HistoryData> _load() async {
    final values = await Future.wait<Object>([
      WorkoutSessionStore.getTrainingHistory(),
      PremiumAccess.isActive(),
    ]);
    return _HistoryData(
      history: values[0] as TrainingHistorySnapshot,
      isPremium: values[1] as bool,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _history = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: GymRatColors.black,
        appBar: AppBar(
          backgroundColor: GymRatColors.black,
          foregroundColor: GymRatColors.textPrimary,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr.t('trainingHistory'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
          bottom: TabBar(
            indicatorColor: GymRatColors.gold,
            indicatorWeight: 3,
            labelColor: GymRatColors.gold,
            unselectedLabelColor: GymRatColors.textMuted,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
            ),
            tabs: [
              Tab(text: context.tr.t('combatLog')),
              Tab(text: context.tr.t('records')),
            ],
          ),
        ),
        body: FutureBuilder<_HistoryData>(
          future: _history,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: GymRatColors.gold),
              );
            }
            if (!snapshot.hasData) {
              return Center(
                child: Text(
                  context.tr.t('historyLoadError'),
                  style: const TextStyle(color: GymRatColors.textSecondary),
                ),
              );
            }
            final data = snapshot.requireData;
            final history = PremiumAccess.visibleHistory(
              data.history,
              isPremium: data.isPremium,
            );
            return TabBarView(
              children: [
                _CombatLog(
                  history: history,
                  isPremium: data.isPremium,
                  onRefresh: _refresh,
                ),
                PersonalBestsView(
                  history: history,
                  isPremium: data.isPremium,
                  onRefresh: _refresh,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CombatLog extends StatelessWidget {
  const _CombatLog({
    required this.history,
    required this.isPremium,
    required this.onRefresh,
  });

  final TrainingHistorySnapshot history;
  final bool isPremium;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: GymRatColors.green,
    backgroundColor: GymRatColors.surfaceElevated,
    onRefresh: onRefresh,
    child: ListView(
      key: const PageStorageKey<String>('combat-log'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        _ArchiveHeader(history: history),
        const SizedBox(height: 22),
        if (history.workouts.isEmpty)
          _EmptyHistory(
            title: context.tr.t('emptyHistoryTitle'),
            message: context.tr.t('emptyHistoryMessage'),
          )
        else
          for (var index = 0; index < history.workouts.length; index++) ...[
            _HistoryCard(
              workout: history.workouts[index],
              isLatest: index == 0,
            ),
            const SizedBox(height: 10),
          ],
        if (!isPremium) ...[
          const SizedBox(height: 12),
          const PremiumGateCard(),
        ],
      ],
    ),
  );
}

class _ArchiveHeader extends StatelessWidget {
  const _ArchiveHeader({required this.history});

  final TrainingHistorySnapshot history;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D2619), GymRatColors.surface, Color(0xFF0A100D)],
      ),
      border: Border.all(color: GymRatColors.greenDark),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: GymRatColors.green.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: GymRatColors.green.withValues(alpha: .32),
                ),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: GymRatColors.green,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr.t('trainingArchive'),
                    style: const TextStyle(
                      color: GymRatColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr.t('trainingArchiveSubtitle'),
                    style: const TextStyle(
                      color: GymRatColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _ArchiveMetric(
                value: '${history.workouts.length}',
                label: context.tr.t('totalWorkouts'),
              ),
            ),
            Expanded(
              child: _ArchiveMetric(
                value:
                    '${(history.totalDurationSeconds / 60).round()} ${context.tr.t('minutesShort')}',
                label: context.tr.t('time'),
              ),
            ),
            Expanded(
              child: _ArchiveMetric(
                value: '${_compact(history.totalVolume)} kg',
                label: context.tr.t('totalVolume'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  static String _compact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.round().toString();
  }
}

class _ArchiveMetric extends StatelessWidget {
  const _ArchiveMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: GymRatColors.green,
          fontSize: 15,
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
          letterSpacing: .5,
        ),
      ),
    ],
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.workout, required this.isLatest});

  final WorkoutHistoryEntry workout;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final date = material.formatMediumDate(workout.completedAt);
    final time = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(workout.completedAt),
    );
    final minutes = (workout.durationSeconds / 60).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () => showWorkoutHistoryDetails(context, workout),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GymRatColors.surface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: isLatest
                  ? GymRatColors.green.withValues(alpha: .34)
                  : GymRatColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: workout.isWalk
                      ? GymRatColors.info.withValues(alpha: .12)
                      : GymRatColors.green.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  workout.isWalk
                      ? Icons.directions_walk_rounded
                      : Icons.fitness_center_rounded,
                  color: workout.isWalk
                      ? GymRatColors.info
                      : GymRatColors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      WorkoutCopy.workout(context, workout.workoutName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: GymRatColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$date  ·  $time',
                      style: const TextStyle(
                        color: GymRatColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$minutes ${context.tr.t('minutesShort')}  ·  ${workout.volume.round()} kg',
                      style: const TextStyle(
                        color: GymRatColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: GymRatColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.t('tapForDetails'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GymRatColors.textMuted,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .3,
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
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.title, required this.message});

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
          Icons.shield_outlined,
          color: GymRatColors.greenDark,
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

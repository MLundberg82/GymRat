import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../../core/units/weight_unit_store.dart';
import '../../armory/domain/rat_item.dart';
import '../../evolution/domain/evolution_milestones.dart';
import '../../workout/data/workout_session_store.dart';
import '../../workout/presentation/workout_copy.dart';
import '../../premium/data/premium_access.dart';
import '../../premium/presentation/premium_gate_card.dart';
import '../domain/training_analytics.dart';
import '../domain/achievement_progress.dart';
import 'progress_line_chart.dart';
import 'training_detail_screen.dart';

class _ProgressData {
  const _ProgressData({
    required this.snapshot,
    required this.history,
    required this.isPremium,
  });

  final ProgressSnapshot snapshot;
  final TrainingHistorySnapshot history;
  final bool isPremium;
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<_ProgressData> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = _load();
  }

  Future<_ProgressData> _load() async {
    final values = await Future.wait<Object>([
      WorkoutSessionStore.getProgressSnapshot(),
      WorkoutSessionStore.getTrainingHistory(),
      PremiumAccess.isActive(),
    ]);
    return _ProgressData(
      snapshot: values[0] as ProgressSnapshot,
      history: values[1] as TrainingHistorySnapshot,
      isPremium: values[2] as bool,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _snapshot = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymRatColors.black,
      appBar: AppBar(
        backgroundColor: GymRatColors.black,
        foregroundColor: GymRatColors.textPrimary,
        title: Text(
          context.tr.t('progressTitle'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: FutureBuilder<_ProgressData>(
        future: _snapshot,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: GymRatColors.gold),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text(
                context.tr.t('progressLoadError'),
                style: const TextStyle(color: GymRatColors.textSecondary),
              ),
            );
          }
          return _ProgressContent(
            data: snapshot.requireData.snapshot,
            history: PremiumAccess.visibleHistory(
              snapshot.requireData.history,
              isPremium: snapshot.requireData.isPremium,
            ),
            isPremium: snapshot.requireData.isPremium,
            onRefresh: _refresh,
          );
        },
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({
    required this.data,
    required this.history,
    required this.isPremium,
    required this.onRefresh,
  });

  final ProgressSnapshot data;
  final TrainingHistorySnapshot history;
  final bool isPremium;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final player = data.player;
    return RefreshIndicator(
      color: GymRatColors.gold,
      backgroundColor: GymRatColors.surfaceElevated,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _LevelCard(player: player),
          const SizedBox(height: 12),
          _EvolutionRoadmapCard(player: player),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.bolt_rounded,
                  label: context.tr.t('totalXp'),
                  value: '${player.totalXP}',
                  color: GymRatColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.fitness_center_rounded,
                  label: context.tr.t('totalWorkouts'),
                  value: '${data.totalWorkouts}',
                  color: GymRatColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  label: context.tr.t('streak'),
                  value: '${player.streak}',
                  color: GymRatColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            context.tr.t('trainingByArea'),
            style: const TextStyle(
              color: GymRatColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            context.tr.t('trainingByAreaHelp'),
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          for (final category in TrainingAnalytics.categories(history)) ...[
            _CategoryCard(
              category: category,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorkoutCategoryDetailScreen(
                    history: history,
                    category: category,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (!isPremium) ...[
            const SizedBox(height: 4),
            const PremiumGateCard(),
          ],
          const SizedBox(height: 18),
          Text(
            context.tr.t('recentWorkouts'),
            style: const TextStyle(
              color: GymRatColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          if (data.recentWorkouts.isEmpty)
            _EmptyHistory(message: context.tr.t('noWorkoutsYet'))
          else
            for (final workout in data.recentWorkouts) ...[
              _WorkoutCard(workout: workout),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 12),
          _TrainingLoadCard(
            insight: TrainingAnalytics.loadInsight(history),
            isPremium: isPremium,
          ),
          const SizedBox(height: 12),
          _AchievementVault(
            achievements: AchievementProgress.derive(
              progress: data,
              history: history,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementVault extends StatelessWidget {
  const _AchievementVault({required this.achievements});

  final List<GymRatAchievement> achievements;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((item) => item.isUnlocked).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GymRatColors.goldDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: GymRatColors.gold,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.tr.t('achievementVault'),
                  style: const TextStyle(
                    color: GymRatColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                  ),
                ),
              ),
              Text(
                '$unlocked/${achievements.length}',
                style: const TextStyle(
                  color: GymRatColors.gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.tr.t('achievementVaultHelp'),
            style: const TextStyle(
              color: GymRatColors.textMuted,
              fontSize: 9,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 9) / 2;
              return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final achievement in achievements)
                    SizedBox(
                      width: width,
                      height: width / 1.45,
                      child: _AchievementTile(achievement: achievement),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final GymRatAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final icon = switch (achievement.kind) {
      AchievementKind.workout => Icons.fitness_center_rounded,
      AchievementKind.streak => Icons.local_fire_department_rounded,
      AchievementKind.record => Icons.military_tech_rounded,
      AchievementKind.evolution => Icons.auto_awesome_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: unlocked
            ? GymRatColors.gold.withValues(alpha: .09)
            : GymRatColors.surfaceElevated,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: unlocked ? GymRatColors.goldDark : GymRatColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                unlocked ? icon : Icons.lock_rounded,
                color: unlocked ? GymRatColors.gold : GymRatColors.textMuted,
                size: 17,
              ),
              const Spacer(),
              Text(
                '${achievement.current.clamp(0, achievement.target)}/${achievement.target}',
                style: TextStyle(
                  color: unlocked ? GymRatColors.gold : GymRatColors.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            context.tr.t(achievement.titleKey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked
                  ? GymRatColors.textPrimary
                  : GymRatColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              context.tr.t(achievement.descriptionKey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GymRatColors.textMuted,
                fontSize: 8,
                height: 1.25,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 3,
              value: achievement.progress,
              color: GymRatColors.gold,
              backgroundColor: GymRatColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingLoadCard extends StatelessWidget {
  const _TrainingLoadCard({required this.insight, required this.isPremium});

  final TrainingLoadInsight insight;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final readinessKey = switch (insight.readiness) {
      TrainingReadiness.noData => 'readinessNoData',
      TrainingReadiness.ready => 'readinessReady',
      TrainingReadiness.balanced => 'readinessBalanced',
      TrainingReadiness.recover => 'readinessRecover',
    };
    final change = insight.weeklyChangePercent;
    final changeText = change == null
        ? context.tr.t('coachBaseline')
        : '${change > 0 ? '+' : ''}${change.round()}%';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF291B48), GymRatColors.surface],
        ),
        border: Border.all(color: GymRatColors.premium.withValues(alpha: .48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monitor_heart_rounded,
                color: GymRatColors.premium,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.tr.t('trainingLoad'),
                  style: const TextStyle(
                    color: GymRatColors.premium,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .9,
                  ),
                ),
              ),
              if (!isPremium)
                const Icon(
                  Icons.lock_rounded,
                  color: GymRatColors.premium,
                  size: 17,
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            context.tr.t(isPremium ? readinessKey : 'trainingLoadLocked'),
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              fontSize: 10,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _LoadMetric(
                label: context.tr.t('thisWeekLoad'),
                value: isPremium ? '${insight.currentWeekLoad}' : '•••',
              ),
              const SizedBox(width: 9),
              _LoadMetric(
                label: context.tr.t('loadTrend'),
                value: isPremium ? changeText : '•••',
              ),
              const SizedBox(width: 9),
              _LoadMetric(
                label: context.tr.t('latestEffort'),
                value: isPremium && insight.latestEffort != null
                    ? '${insight.latestEffort}/5'
                    : '—',
              ),
            ],
          ),
          if (isPremium && insight.ratedSessions > 0) ...[
            const SizedBox(height: 14),
            ProgressLineChart(
              points: insight.weeklyLoad,
              height: 82,
              color: GymRatColors.premium,
              semanticLabel: context.tr.t('trainingLoad'),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadMetric extends StatelessWidget {
  const _LoadMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: GymRatColors.black.withValues(alpha: .28),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: GymRatColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GymRatColors.textMuted,
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EvolutionRoadmapCard extends StatelessWidget {
  const _EvolutionRoadmapCard({required this.player});

  final PlayerProgress player;

  @override
  Widget build(BuildContext context) {
    final currentStage = EvolutionMilestones.stageForLevel(player.level);
    final nextMilestone = EvolutionMilestones.nextMilestoneAfter(player.level);
    final startXP = WorkoutSessionStore.totalXPToReachLevel(currentStage);
    final targetXP = nextMilestone == null
        ? player.totalXP
        : WorkoutSessionStore.totalXPToReachLevel(nextMilestone);
    final span = targetXP - startXP;
    final progress = nextMilestone == null || span <= 0
        ? 1.0
        : ((player.totalXP - startXP) / span).clamp(0.0, 1.0).toDouble();
    final remainingXP = nextMilestone == null || targetXP <= player.totalXP
        ? 0
        : targetXP - player.totalXP;
    final reward = nextMilestone == null
        ? null
        : RatItemCatalog.forLevel(nextMilestone);

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF332707), GymRatColors.surface, Color(0xFF0B0C0C)],
        ),
        border: Border.all(color: GymRatColors.goldDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: GymRatColors.gold.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: GymRatColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.t('evolutionRoadmap'),
                      style: const TextStyle(
                        color: GymRatColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nextMilestone == null
                          ? context.tr.t('finalEvolutionReached')
                          : '${context.tr.t('level')} $currentStage  →  '
                                '${context.tr.t('level')} $nextMilestone',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              color: GymRatColors.gold,
              backgroundColor: GymRatColors.surfaceElevated,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            nextMilestone == null
                ? context.tr.t('olympiaFormComplete')
                : '$remainingXP XP ${context.tr.t('untilEvolution')}',
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (reward != null) ...[
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: GymRatColors.black.withValues(alpha: .38),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: GymRatColors.gold.withValues(alpha: .24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_open_rounded,
                    size: 15,
                    color: GymRatColors.gold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${context.tr.t('nextEvolutionReward')}: '
                      '${context.tr.t(reward.nameKey)}',
                      style: const TextStyle(
                        color: GymRatColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final WorkoutCategoryTrend category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: GymRatColors.surface,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        height: 104,
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: GymRatColors.greenDark.withValues(alpha: .55),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: GymRatColors.green.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                category.isWalk
                    ? Icons.directions_walk_rounded
                    : Icons.fitness_center_rounded,
                color: GymRatColors.green,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    WorkoutCopy.workout(context, category.name),
                    style: const TextStyle(
                      color: GymRatColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${category.sessions.length} ${context.tr.t('sessions')}',
                    style: const TextStyle(
                      color: GymRatColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 92,
              child: ProgressLineChart(
                points: category.primaryMetric,
                height: 62,
                semanticLabel: WorkoutCopy.workout(context, category.name),
              ),
            ),
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.player});

  final PlayerProgress player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GymRatColors.goldDark.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${context.tr.t('level')} ${player.level}',
                style: const TextStyle(
                  color: GymRatColors.gold,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                context.tr.t('nextLevel'),
                style: const TextStyle(
                  color: GymRatColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: player.progress,
              color: GymRatColors.gold,
              backgroundColor: GymRatColors.surfaceElevated,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${player.currentLevelXP} / ${player.requiredLevelXP} XP',
              style: const TextStyle(
                color: GymRatColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GymRatColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: GymRatColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
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
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GymRatColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history_rounded,
            color: GymRatColors.textMuted,
            size: 30,
          ),
          const SizedBox(height: 10),
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
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.workout});

  final WorkoutHistoryEntry workout;

  @override
  Widget build(BuildContext context) {
    final date = workout.completedAt;
    final dateText =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    final minutes = (workout.durationSeconds / 60).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GymRatColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: GymRatColors.greenDark.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              workout.isWalk
                  ? Icons.directions_walk_rounded
                  : Icons.fitness_center_rounded,
              color: GymRatColors.green,
              size: 21,
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
                  '$dateText  ·  $minutes ${context.tr.t('minutesShort')}',
                  style: const TextStyle(
                    color: GymRatColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (workout.volume > 0)
            Text(
              WeightUnitStore.formatVolume(workout.volume),
              style: const TextStyle(
                color: GymRatColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

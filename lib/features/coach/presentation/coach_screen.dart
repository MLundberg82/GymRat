import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../premium/data/premium_access.dart';
import '../../premium/presentation/premium_gate_card.dart';
import '../../profile/data/training_profile_store.dart';
import '../../profile/domain/training_profile.dart';
import '../../workout/data/workout_presets.dart';
import '../../workout/data/workout_session_store.dart';
import '../../workout/domain/workout_models.dart';
import '../../workout/presentation/workout_copy.dart';
import '../../workout/presentation/workout_preview_screen.dart';
import '../domain/coach_recommendation.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachData {
  const _CoachData({required this.recommendation, required this.isPremium});

  final CoachRecommendation recommendation;
  final bool isPremium;
}

class _CoachScreenState extends State<CoachScreen> {
  late Future<_CoachData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_CoachData> _load() async {
    final profile =
        TrainingProfileStore.profile.value ?? TrainingProfile.starter;
    final results = await Future.wait<Object>([
      WorkoutSessionStore.getTrainingHistory(),
      PremiumAccess.isActive(),
    ]);
    return _CoachData(
      recommendation: CoachRecommendationEngine.build(
        profile: profile,
        history: results[0] as TrainingHistorySnapshot,
      ),
      isPremium: results[1] as bool,
    );
  }

  void _retry() => setState(() => _data = _load());

  void _openMission(CoachRecommendation recommendation) {
    final preset = WorkoutPresets.free.firstWhere(
      (candidate) => candidate.title == recommendation.workoutName,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutPreviewScreen(
          preset: preset,
          coachGuidance: WorkoutCoachGuidance(
            setCount: recommendation.recommendedSetCount,
            repRange: recommendation.repRange,
            activeRecovery:
                recommendation.missionMode == CoachMissionMode.activeRecovery,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GymRatColors.black,
    appBar: AppBar(
      backgroundColor: GymRatColors.black,
      title: Text(
        context.tr.t('premiumCoach'),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: FutureBuilder<_CoachData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: GymRatColors.premium),
          );
        }
        if (!snapshot.hasData) {
          return _CoachLoadError(onRetry: _retry);
        }
        final data = snapshot.requireData;
        final recommendation = data.recommendation;
        final weeklyProgress =
            (recommendation.weeklyCompleted / recommendation.weeklyTarget)
                .clamp(0.0, 1.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                gradient: const LinearGradient(
                  colors: [Color(0xFF35205D), GymRatColors.surface],
                ),
                border: Border.all(
                  color: GymRatColors.premium.withValues(alpha: .60),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology_alt_rounded,
                        color: GymRatColors.premium,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr.t(
                            data.isPremium
                                ? 'adaptivePlanReady'
                                : 'premiumCoachPreview',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Text(
                    context.tr.t('coachNextMission'),
                    style: const TextStyle(
                      color: GymRatColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.isPremium
                        ? WorkoutCopy.workout(
                            context,
                            recommendation.workoutName,
                          )
                        : '•••',
                    style: const TextStyle(
                      color: GymRatColors.premium,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    context.tr.t(
                      data.isPremium
                          ? recommendation.reasonKey
                          : 'premiumCoachLockedHelp',
                    ),
                    style: const TextStyle(
                      color: GymRatColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  if (data.isPremium) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openMission(recommendation),
                        style: FilledButton.styleFrom(
                          backgroundColor: GymRatColors.green,
                          foregroundColor: GymRatColors.black,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          context.tr.t('coachLaunchMission'),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CoachMetric(
                    label: context.tr.t('recommendedSets'),
                    value: data.isPremium ? recommendation.setRange : '—',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CoachMetric(
                    label: context.tr.t('recommendedReps'),
                    value: data.isPremium ? recommendation.repRange : '—',
                  ),
                ),
              ],
            ),
            if (data.isPremium) ...[
              const SizedBox(height: 8),
              Text(
                context.tr.t('coachVolumeHelp'),
                style: const TextStyle(
                  color: GymRatColors.textMuted,
                  fontSize: 9,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: GymRatColors.surface,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: GymRatColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr.t('weeklyTrainingTarget'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: weeklyProgress,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(20),
                    color: GymRatColors.premium,
                    backgroundColor: GymRatColors.surfaceElevated,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${recommendation.weeklyCompleted} / '
                    '${recommendation.weeklyTarget}',
                    style: const TextStyle(
                      color: GymRatColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CampaignPips(
                    completed: recommendation.weeklyCompleted,
                    target: recommendation.weeklyTarget,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recommendation.weeklyRemaining == 0
                        ? context.tr.t('coachCampaignComplete')
                        : '${recommendation.weeklyRemaining} '
                              '${context.tr.t('coachMissionsRemaining')}',
                    style: const TextStyle(
                      color: GymRatColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CoachMetric(
                    label: context.tr.t('coachRecoveryWindow'),
                    value: data.isPremium
                        ? _recoveryValue(context, recommendation)
                        : '—',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CoachMetric(
                    label: context.tr.t('volumeTrend'),
                    value: data.isPremium
                        ? _volumeValue(context, recommendation)
                        : '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _RotationCard(
              recommendation: recommendation,
              isPremium: data.isPremium,
            ),
            const SizedBox(height: 18),
            Text(
              context.tr.t('coachSafetyNote'),
              style: const TextStyle(
                color: GymRatColors.textMuted,
                fontSize: 10,
                height: 1.4,
              ),
            ),
            if (!data.isPremium) ...[
              const SizedBox(height: 18),
              const PremiumGateCard(),
            ],
          ],
        );
      },
    ),
  );

  String _recoveryValue(
    BuildContext context,
    CoachRecommendation recommendation,
  ) {
    final days = recommendation.recoveryDays;
    return days == null
        ? context.tr.t('coachFreshRoute')
        : '$days${context.tr.t('coachDaySuffix')}';
  }

  String _volumeValue(
    BuildContext context,
    CoachRecommendation recommendation,
  ) {
    final change = recommendation.volumeChangePercent;
    if (change == null) return context.tr.t('coachBaseline');
    final rounded = change.round();
    return '${rounded > 0 ? '+' : ''}$rounded%';
  }
}

class _CoachLoadError extends StatelessWidget {
  const _CoachLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: GymRatColors.premium,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr.t('coachLoadError'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.tr.t('tryAgain')),
          ),
        ],
      ),
    ),
  );
}

class _CampaignPips extends StatelessWidget {
  const _CampaignPips({required this.completed, required this.target});

  final int completed;
  final int target;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(target, (index) {
      final done = index < completed;
      return Expanded(
        child: Container(
          height: 8,
          margin: EdgeInsets.only(right: index == target - 1 ? 0 : 6),
          decoration: BoxDecoration(
            color: done ? GymRatColors.green : GymRatColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            boxShadow: done
                ? [
                    BoxShadow(
                      color: GymRatColors.green.withValues(alpha: .25),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      );
    }),
  );
}

class _RotationCard extends StatelessWidget {
  const _RotationCard({required this.recommendation, required this.isPremium});

  final CoachRecommendation recommendation;
  final bool isPremium;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: GymRatColors.premium.withValues(alpha: .3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr.t('coachRotationTitle'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          context.tr.t('coachRotationHelp'),
          style: const TextStyle(
            color: GymRatColors.textMuted,
            fontSize: 10,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (
              var index = 0;
              index < recommendation.rotationQueue.length;
              index++
            )
              _RotationToken(
                index: index,
                name: isPremium
                    ? WorkoutCopy.workout(
                        context,
                        recommendation.rotationQueue[index],
                      )
                    : '•••',
              ),
          ],
        ),
      ],
    ),
  );
}

class _RotationToken extends StatelessWidget {
  const _RotationToken({required this.index, required this.name});

  final int index;
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: index == 0
          ? GymRatColors.premium.withValues(alpha: .14)
          : GymRatColors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: index == 0
            ? GymRatColors.premium.withValues(alpha: .55)
            : GymRatColors.border,
      ),
    ),
    child: Text(
      '${index + 1}  $name',
      style: TextStyle(
        color: index == 0 ? GymRatColors.premium : GymRatColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _CoachMetric extends StatelessWidget {
  const _CoachMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GymRatColors.premium.withValues(alpha: .3)),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: GymRatColors.premium,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GymRatColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../premium/data/premium_access.dart';
import '../../premium/presentation/premium_gate_card.dart';
import '../../profile/data/training_profile_store.dart';
import '../../profile/domain/training_profile.dart';
import '../../workout/data/workout_session_store.dart';
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
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: GymRatColors.premium),
          );
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
                      Text(
                        context.tr.t(
                          data.isPremium
                              ? 'adaptivePlanReady'
                              : 'premiumCoachPreview',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w900),
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
                    data.isPremium ? recommendation.workoutName : '•••',
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
                ],
              ),
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

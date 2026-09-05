import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../armory/data/rat_inventory_store.dart';
import '../../workout/data/workout_session_store.dart';
import '../domain/quest_progress.dart';

class QuestBoardScreen extends StatefulWidget {
  const QuestBoardScreen({super.key});

  @override
  State<QuestBoardScreen> createState() => _QuestBoardScreenState();
}

class _QuestBoardScreenState extends State<QuestBoardScreen> {
  late Future<QuestSnapshot> _quests;
  final Set<String> _claiming = <String>{};
  Timer? _claimCelebrationTimer;
  _QuestClaimVisual? _claimVisual;

  @override
  void initState() {
    super.initState();
    _quests = _load();
  }

  Future<QuestSnapshot> _load() async {
    final results = await Future.wait<Object>([
      WorkoutSessionStore.getTrainingHistory(),
      RatInventoryStore.load(),
    ]);
    final inventory = results[1] as RatInventoryState;
    return QuestProgressCalculator.fromHistory(
      results[0] as TrainingHistorySnapshot,
      claimedQuestIds: inventory.claimedQuests,
      credits: inventory.credits,
    );
  }

  Future<void> _claim(QuestProgress quest) async {
    if (!quest.isComplete || quest.isClaimed || _claiming.contains(quest.id)) {
      return;
    }
    setState(() => _claiming.add(quest.id));
    final claimed = await RatInventoryStore.claimQuest(
      quest.claimId,
      quest.rewardCredits,
    );
    if (!mounted) return;
    _claiming.remove(quest.id);
    if (!claimed) {
      setState(() {});
      return;
    }
    final inventory = await RatInventoryStore.load();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _claimCelebrationTimer?.cancel();
    setState(() {
      _claimVisual = _QuestClaimVisual(
        titleKey: quest.titleKey,
        rewardCredits: quest.rewardCredits,
        totalCredits: inventory.credits,
      );
    });
    _claimCelebrationTimer = Timer(const Duration(milliseconds: 1350), () {
      if (mounted) setState(() => _claimVisual = null);
    });
    await _refresh();
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _quests = next;
    });
    await next;
  }

  @override
  void dispose() {
    _claimCelebrationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GymRatColors.black,
    appBar: AppBar(
      backgroundColor: GymRatColors.black,
      foregroundColor: GymRatColors.textPrimary,
      title: Text(
        context.tr.t('questBoardTitle'),
        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    ),
    body: Stack(
      children: [
        Positioned.fill(
          child: FutureBuilder<QuestSnapshot>(
            future: _quests,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: GymRatColors.green),
                );
              }
              if (!snapshot.hasData) {
                return Center(
                  child: Text(
                    context.tr.t('questLoadError'),
                    style: const TextStyle(color: GymRatColors.textSecondary),
                  ),
                );
              }
              final quests = snapshot.requireData;
              return RefreshIndicator(
                color: GymRatColors.green,
                backgroundColor: GymRatColors.surfaceElevated,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  children: [
                    _QuestBoardHeader(snapshot: quests),
                    const SizedBox(height: 22),
                    _QuestSection(
                      title: context.tr.t('dailyContracts'),
                      subtitle: context.tr.t('dailyContractsSubtitle'),
                      quests: quests.daily,
                      claiming: _claiming,
                      onClaim: _claim,
                    ),
                    const SizedBox(height: 24),
                    _QuestSection(
                      title: context.tr.t('weeklyCampaign'),
                      subtitle: context.tr.t('weeklyCampaignSubtitle'),
                      quests: quests.weekly,
                      claiming: _claiming,
                      onClaim: _claim,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_claimVisual case final visual?)
          Positioned.fill(
            child: _QuestClaimCelebration(
              key: ValueKey('${visual.titleKey}-${visual.totalCredits}'),
              visual: visual,
            ),
          ),
      ],
    ),
  );
}

class _QuestClaimVisual {
  const _QuestClaimVisual({
    required this.titleKey,
    required this.rewardCredits,
    required this.totalCredits,
  });

  final String titleKey;
  final int rewardCredits;
  final int totalCredits;
}

class _QuestBoardHeader extends StatelessWidget {
  const _QuestBoardHeader({required this.snapshot});

  final QuestSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final dailyComplete = snapshot.completedDaily == snapshot.daily.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dailyComplete
              ? const [
                  Color(0xFF352708),
                  GymRatColors.surface,
                  Color(0xFF0B0C0C),
                ]
              : const [
                  Color(0xFF0D281A),
                  GymRatColors.surface,
                  Color(0xFF0A0D0B),
                ],
        ),
        border: Border.all(
          color: dailyComplete ? GymRatColors.goldDark : GymRatColors.greenDark,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (dailyComplete ? GymRatColors.gold : GymRatColors.green)
                  .withValues(alpha: .12),
              border: Border.all(
                color: (dailyComplete ? GymRatColors.gold : GymRatColors.green)
                    .withValues(alpha: .42),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${snapshot.completedDaily}/${snapshot.daily.length}',
              style: TextStyle(
                color: dailyComplete ? GymRatColors.gold : GymRatColors.green,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.t(
                    dailyComplete ? 'dailyComplete' : 'questsInProgress',
                  ),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr.t(
                    dailyComplete
                        ? 'dailyCompleteMessage'
                        : 'questBoardSubtitle',
                  ),
                  style: const TextStyle(
                    color: GymRatColors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.hexagon_rounded, color: GymRatColors.gold),
              const SizedBox(height: 3),
              Text(
                '${snapshot.credits}',
                style: const TextStyle(
                  color: GymRatColors.gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestSection extends StatelessWidget {
  const _QuestSection({
    required this.title,
    required this.subtitle,
    required this.quests,
    required this.claiming,
    required this.onClaim,
  });

  final String title;
  final String subtitle;
  final List<QuestProgress> quests;
  final Set<String> claiming;
  final Future<void> Function(QuestProgress quest) onClaim;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: GymRatColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(color: GymRatColors.textMuted, fontSize: 10),
      ),
      const SizedBox(height: 11),
      for (final quest in quests) ...[
        _QuestCard(
          quest: quest,
          busy: claiming.contains(quest.id),
          onClaim: () => onClaim(quest),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.busy,
    required this.onClaim,
  });

  final QuestProgress quest;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final complete = quest.isComplete;
    final color = complete ? GymRatColors.gold : GymRatColors.green;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: complete
              ? GymRatColors.gold.withValues(alpha: .42)
              : GymRatColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  complete ? Icons.check_rounded : _questIcon(quest.unit),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.t(quest.titleKey),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.tr.t(quest.descriptionKey),
                      style: const TextStyle(
                        color: GymRatColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${quest.visibleCurrent}/${quest.target}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: quest.progress,
                backgroundColor: GymRatColors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.hexagon_rounded,
                color: GymRatColors.gold,
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                '+${quest.rewardCredits}',
                style: const TextStyle(
                  color: GymRatColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (quest.isClaimed)
                Text(
                  context.tr.t('claimed'),
                  style: const TextStyle(
                    color: GymRatColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else if (quest.isComplete)
                FilledButton(
                  onPressed: busy ? null : onClaim,
                  style: FilledButton.styleFrom(
                    backgroundColor: GymRatColors.gold,
                    foregroundColor: GymRatColors.black,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: busy
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GymRatColors.black,
                          ),
                        )
                      : Text(
                          context.tr.t('claimReward'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestClaimCelebration extends StatelessWidget {
  const _QuestClaimCelebration({super.key, required this.visual});

  final _QuestClaimVisual visual;

  @override
  Widget build(BuildContext context) => AbsorbPointer(
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        final fadeIn = (progress / .16).clamp(0.0, 1.0);
        final fadeOut = ((1 - progress) / .22).clamp(0.0, 1.0);
        final opacity = math.min(fadeIn, fadeOut).toDouble();
        final scale =
            .72 +
            Curves.easeOutBack.transform((progress / .48).clamp(0.0, 1.0)) *
                .28;
        return Opacity(
          opacity: opacity,
          child: ColoredBox(
            color: GymRatColors.black.withValues(alpha: .82),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _CreditBurstPainter(progress)),
                SafeArea(
                  child: Center(
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const RadialGradient(
                            center: Alignment.topCenter,
                            radius: 1.15,
                            colors: [
                              Color(0xFF4A3506),
                              Color(0xFF171508),
                              GymRatColors.surface,
                            ],
                          ),
                          border: Border.all(
                            color: GymRatColors.gold,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: GymRatColors.gold.withValues(alpha: .30),
                              blurRadius: 48,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFFFFF3B0),
                                    GymRatColors.gold,
                                    Color(0xFFFF8F00),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: GymRatColors.gold.withValues(
                                      alpha: .55,
                                    ),
                                    blurRadius: 34,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.hexagon_rounded,
                                color: GymRatColors.black,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              context.tr.t('claimed'),
                              style: const TextStyle(
                                color: GymRatColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr.t(visual.titleKey),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: GymRatColors.textPrimary,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '+${visual.rewardCredits} '
                              '${context.tr.t('armoryCredits')}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              '${visual.totalCredits}',
                              style: const TextStyle(
                                color: GymRatColors.gold,
                                fontSize: 34,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _CreditBurstPainter extends CustomPainter {
  const _CreditBurstPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final burst = Curves.easeOutQuart.transform(
      (progress / .72).clamp(0.0, 1.0),
    );
    final opacity = (1 - progress).clamp(0.0, 1.0).toDouble();
    for (var index = 0; index < 34; index++) {
      final angle = index / 34 * math.pi * 2 + (index % 5) * .035;
      final distance = size.shortestSide * (.12 + .62 * burst);
      final point =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              distance *
              (.58 + (index % 7) * .065);
      canvas.drawCircle(
        point,
        1.8 + (index % 4) * 1.1,
        Paint()
          ..color = (index.isEven ? GymRatColors.gold : const Color(0xFFFFF3B0))
              .withValues(alpha: opacity * .92),
      );
    }
    canvas.drawCircle(
      center,
      size.shortestSide * (.10 + .48 * burst),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * (1 - burst) + 1
        ..color = GymRatColors.gold.withValues(alpha: opacity * .60),
    );
  }

  @override
  bool shouldRepaint(_CreditBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

IconData _questIcon(QuestUnit unit) => switch (unit) {
  QuestUnit.sessions => Icons.fitness_center_rounded,
  QuestUnit.minutes => Icons.timer_outlined,
  QuestUnit.exercises => Icons.format_list_numbered_rounded,
};

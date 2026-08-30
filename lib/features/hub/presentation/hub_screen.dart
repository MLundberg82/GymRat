import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../armory/presentation/armory_screen.dart';
import '../../character/presentation/gymrat_character.dart';
import '../../history/presentation/history_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../quests/domain/quest_progress.dart';
import '../../quests/presentation/quest_board_screen.dart';
import '../../rewards/presentation/gym_upgrade_layer.dart';
import '../../workout/data/workout_session_store.dart';
import '../../workout/presentation/workout_screen.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key, this.animationFromXP, this.unlockedUpgradeLevel});
  final int? animationFromXP, unlockedUpgradeLevel;
  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  PlayerProgress? progress;
  QuestSnapshot? quests;
  int animationFromXP = 0, animationVersion = 0;
  int? get previousGymLevel => widget.unlockedUpgradeLevel == null
      ? null
      : WorkoutSessionStore.levelFromXP(animationFromXP);

  @override
  void initState() {
    super.initState();
    _loadInitialProgress();
  }

  Future<void> _loadInitialProgress() async {
    final results = await Future.wait<Object>([
      WorkoutSessionStore.getPlayerProgress(),
      WorkoutSessionStore.getTrainingHistory(),
    ]);
    final loaded = results[0] as PlayerProgress;
    final loadedQuests = QuestProgressCalculator.fromHistory(
      results[1] as TrainingHistorySnapshot,
    );
    if (!mounted) return;
    setState(() {
      progress = loaded;
      quests = loadedQuests;
      animationFromXP =
          widget.animationFromXP ?? loaded.totalXP - loaded.currentLevelXP;
      animationVersion++;
    });
  }

  Future<void> _open(Widget page) async {
    final before = progress;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    final results = await Future.wait<Object>([
      WorkoutSessionStore.getPlayerProgress(),
      WorkoutSessionStore.getTrainingHistory(),
    ]);
    final loaded = results[0] as PlayerProgress;
    final loadedQuests = QuestProgressCalculator.fromHistory(
      results[1] as TrainingHistorySnapshot,
    );
    if (!mounted) return;
    setState(() {
      animationFromXP = before?.totalXP ?? loaded.totalXP;
      progress = loaded;
      quests = loadedQuests;
      animationVersion++;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GymRatColors.black,
    endDrawer: _GymRatMenu(
      onWorkout: () => _open(const WorkoutScreen()),
      onProgress: () => _open(const ProgressScreen()),
      onHistory: () => _open(const HistoryScreen()),
      onMissions: () => _open(const QuestBoardScreen()),
      onArmory: () => _open(const ArmoryScreen()),
      onProfile: () => _open(const ProfileScreen()),
      onPremium: () => _open(const ArmoryScreen(initialTab: 1)),
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        GymUpgradeLayer(
          level: progress?.level ?? 1,
          previousLevel: previousGymLevel,
          animateUnlock: widget.unlockedUpgradeLevel != null,
        ),
        const _Atmosphere(),
        const _GroundShadow(),
        _CharacterLayer(level: progress?.level ?? 1),
        const _ForegroundHaze(),
        const _ScreenOverlay(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              children: [
                const _Header(),
                const SizedBox(height: 10),
                _LevelProgress(
                  key: ValueKey(animationVersion),
                  progress: progress,
                  fromTotalXP: animationFromXP,
                ),
                const Spacer(),
                _StatusRow(
                  streak: progress?.streak ?? 0,
                  completedQuests: quests?.completedDaily ?? 0,
                  totalQuests: quests?.daily.length ?? 3,
                  onQuests: () => _open(const QuestBoardScreen()),
                ),
                const SizedBox(height: 12),
                _StartButton(onPressed: () => _open(const WorkoutScreen())),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Atmosphere extends StatelessWidget {
  const _Atmosphere();
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -.12),
                radius: .72,
                colors: [
                  Colors.white.withValues(alpha: .055),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFF07100B).withValues(alpha: .08),
          ),
        ),
      ],
    ),
  );
}

class _GroundShadow extends StatelessWidget {
  const _GroundShadow();
  @override
  Widget build(BuildContext context) => Align(
    alignment: const Alignment(0, .56),
    child: Container(
      width: 220,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: RadialGradient(
          colors: [
            Colors.black.withValues(alpha: .72),
            Colors.black.withValues(alpha: .34),
            Colors.transparent,
          ],
        ),
      ),
    ),
  );
}

class _CharacterLayer extends StatelessWidget {
  const _CharacterLayer({required this.level});

  final int level;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final h = (c.maxHeight * .70).clamp(440.0, 720.0).toDouble();
      return Align(
        alignment: const Alignment(0, .25),
        child: SizedBox(
          width: c.maxWidth * .92,
          height: h,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              .90,
              0,
              0,
              0,
              0,
              0,
              .94,
              0,
              0,
              0,
              0,
              0,
              .90,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: GymRatCharacter(height: h, level: level),
          ),
        ),
      );
    },
  );
}

class _ForegroundHaze extends StatelessWidget {
  const _ForegroundHaze();
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: .34,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                GymRatColors.black.withValues(alpha: .08),
                GymRatColors.black.withValues(alpha: .38),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ScreenOverlay extends StatelessWidget {
  const _ScreenOverlay();
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, .18, .66, 1],
          colors: [
            GymRatColors.black.withValues(alpha: .72),
            GymRatColors.black.withValues(alpha: .16),
            Colors.transparent,
            GymRatColors.black.withValues(alpha: .80),
          ],
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'GYM',
              style: TextStyle(
                color: GymRatColors.textPrimary,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -1.4,
              ),
            ),
            TextSpan(
              text: 'RAT',
              style: TextStyle(
                color: GymRatColors.green,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -1.4,
              ),
            ),
          ],
        ),
      ),
      const Spacer(),
      Builder(
        builder: (context) => IconButton(
          onPressed: () => Scaffold.of(context).openEndDrawer(),
          icon: const Icon(Icons.menu_rounded),
          color: GymRatColors.textSecondary,
        ),
      ),
    ],
  );
}

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({
    super.key,
    required this.progress,
    required this.fromTotalXP,
  });
  final PlayerProgress? progress;
  final int fromTotalXP;
  @override
  Widget build(BuildContext context) {
    final target =
        progress ??
        const PlayerProgress(
          totalXP: 0,
          level: 1,
          currentLevelXP: 0,
          requiredLevelXP: 90,
          streak: 0,
        );
    final start = math.min(fromTotalXP, target.totalXP);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: start.toDouble(), end: target.totalXP.toDouble()),
      duration: target.totalXP == start
          ? const Duration(milliseconds: 500)
          : const Duration(milliseconds: 2100),
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        final total = value.round(),
            level = WorkoutSessionStore.levelFromXP(total);
        final current = WorkoutSessionStore.currentLevelXP(total),
            required = WorkoutSessionStore.levelSpan(level);
        final fill = required <= 0
            ? 0.0
            : (current / required).clamp(0.0, 1.0).toDouble();
        final energy = target.totalXP == start
            ? 0.0
            : math
                  .sin(
                    ((value - start) / (target.totalXP - start)).clamp(
                          0.0,
                          1.0,
                        ) *
                        math.pi,
                  )
                  .abs();
        return Column(
          children: [
            Row(
              children: [
                Text(
                  '${context.tr.t('level')} $level',
                  style: TextStyle(
                    color: Color.lerp(
                      GymRatColors.textPrimary,
                      GymRatColors.gold,
                      energy,
                    ),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: GymRatColors.gold.withValues(
                          alpha: .38 * energy,
                        ),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '$current / $required XP',
                  style: const TextStyle(
                    color: GymRatColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: GymRatColors.gold.withValues(alpha: .28 * energy),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: GymRatColors.surfaceElevated),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fill,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFF8F00),
                              GymRatColors.gold,
                              Color(0xFFFFF3B0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.streak,
    required this.completedQuests,
    required this.totalQuests,
    required this.onQuests,
  });
  final int streak;
  final int completedQuests;
  final int totalQuests;
  final VoidCallback onQuests;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onQuests,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Row(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 17,
              color: GymRatColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              '$streak ${context.tr.t(streak == 1 ? 'day' : 'days')}',
              style: const TextStyle(
                color: GymRatColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.check_rounded,
              size: 17,
              color: completedQuests == totalQuests
                  ? GymRatColors.gold
                  : GymRatColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              '$completedQuests/$totalQuests',
              style: TextStyle(
                color: completedQuests == totalQuests
                    ? GymRatColors.gold
                    : GymRatColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: GymRatColors.textMuted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 58,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.fitness_center_rounded),
      label: Text(
        context.tr.t('startWorkout'),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: .9,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: GymRatColors.green,
        foregroundColor: GymRatColors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
    ),
  );
}

class _GymRatMenu extends StatelessWidget {
  const _GymRatMenu({
    required this.onWorkout,
    required this.onProgress,
    required this.onHistory,
    required this.onMissions,
    required this.onArmory,
    required this.onProfile,
    required this.onPremium,
  });
  final VoidCallback onWorkout,
      onProgress,
      onHistory,
      onMissions,
      onArmory,
      onProfile,
      onPremium;
  void _open(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    Future<void>.delayed(const Duration(milliseconds: 120), action);
  }

  @override
  Widget build(BuildContext context) => Drawer(
    width: MediaQuery.sizeOf(context).width * .92,
    backgroundColor: GymRatColors.black,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'GYMRAT',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _MenuItem(
              icon: Icons.fitness_center_rounded,
              title: context.tr.t('workout'),
              onTap: () => _open(context, onWorkout),
            ),
            _MenuItem(
              icon: Icons.show_chart_rounded,
              title: context.tr.t('progress'),
              onTap: () => _open(context, onProgress),
            ),
            _MenuItem(
              icon: Icons.history_rounded,
              title: context.tr.t('history'),
              onTap: () => _open(context, onHistory),
            ),
            _MenuItem(
              icon: Icons.assignment_turned_in_outlined,
              title: context.tr.t('missions'),
              onTap: () => _open(context, onMissions),
            ),
            _MenuItem(
              icon: Icons.restaurant_rounded,
              title: context.tr.t('nutrition'),
            ),
            _MenuItem(
              icon: Icons.inventory_2_outlined,
              title: context.tr.t('inventoryShop'),
              onTap: () => _open(context, onArmory),
            ),
            _MenuItem(
              icon: Icons.person_outline_rounded,
              title: context.tr.t('profileSettings'),
              onTap: () => _open(context, onProfile),
            ),
            const Spacer(),
            const Divider(),
            _MenuItem(
              icon: Icons.workspace_premium_outlined,
              title: context.tr.t('premium'),
              premium: true,
              onTap: () => _open(context, onPremium),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.premium = false,
  });
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool premium;
  @override
  Widget build(BuildContext context) {
    final color = premium ? GymRatColors.premium : GymRatColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      trailing: onTap == null
          ? Text(
              context.tr.t('soon'),
              style: const TextStyle(
                color: GymRatColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            )
          : const Icon(
              Icons.chevron_right_rounded,
              color: GymRatColors.textMuted,
            ),
    );
  }
}

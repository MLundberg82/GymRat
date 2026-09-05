import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../../core/units/weight_unit_store.dart';
import '../../armory/presentation/armory_screen.dart';
import '../../armory/data/rat_inventory_store.dart';
import '../../character/presentation/character_lab_screen.dart';
import '../../character/presentation/gymrat_character.dart';
import '../../coach/presentation/coach_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../nutrition/presentation/nutrition_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/data/training_profile_store.dart';
import '../../profile/domain/training_profile.dart';
import '../../progress/domain/training_analytics.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../progress/presentation/training_detail_screen.dart';
import '../../quests/domain/quest_progress.dart';
import '../../quests/presentation/quest_board_screen.dart';
import '../../rewards/presentation/gym_upgrade_layer.dart';
import '../../support/presentation/contact_screen.dart';
import '../../workout/data/workout_session_store.dart';
import '../../workout/presentation/workout_screen.dart';
import '../../workout/presentation/workout_copy.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key, this.animationFromXP, this.unlockedUpgradeLevel});
  final int? animationFromXP, unlockedUpgradeLevel;
  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  PlayerProgress? progress;
  QuestSnapshot? quests;
  RatInventoryState? inventory;
  TrainingHistorySnapshot? history;
  int animationFromXP = 0, animationVersion = 0;
  RatCharacterView characterView = RatCharacterView.front;
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
      RatInventoryStore.load(),
    ]);
    final loaded = results[0] as PlayerProgress;
    final loadedQuests = QuestProgressCalculator.fromHistory(
      results[1] as TrainingHistorySnapshot,
    );
    final loadedInventory = results[2] as RatInventoryState;
    final loadedHistory = results[1] as TrainingHistorySnapshot;
    if (!mounted) return;
    setState(() {
      progress = loaded;
      quests = loadedQuests;
      inventory = loadedInventory;
      characterView = loadedInventory.characterView;
      history = loadedHistory;
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
      RatInventoryStore.load(),
    ]);
    final loaded = results[0] as PlayerProgress;
    final loadedQuests = QuestProgressCalculator.fromHistory(
      results[1] as TrainingHistorySnapshot,
    );
    final loadedInventory = results[2] as RatInventoryState;
    final loadedHistory = results[1] as TrainingHistorySnapshot;
    if (!mounted) return;
    setState(() {
      animationFromXP = before?.totalXP ?? loaded.totalXP;
      progress = loaded;
      quests = loadedQuests;
      inventory = loadedInventory;
      characterView = loadedInventory.characterView;
      history = loadedHistory;
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
      onNutrition: () => _open(const NutritionScreen()),
      onArmory: () => _open(const ArmoryScreen()),
      onProfile: () => _open(const ProfileScreen()),
      onContact: () => _open(const ContactScreen()),
      onPremium: () => _open(const CoachScreen()),
      onCharacterLab: () => _open(const CharacterLabScreen()),
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
        _CharacterLayer(
          level: progress?.level ?? 1,
          gender:
              TrainingProfileStore.profile.value?.gender ?? RatGender.nonBinary,
          appearanceId:
              (inventory ?? const RatInventoryState()).equippedAppearanceId,
          view: characterView,
          emoteSemanticLabel: context.tr.t('tapRatToFlex'),
        ),
        if (history case final loadedHistory?)
          _GymRecordHotspots(history: loadedHistory),
        SafeArea(
          child: Align(
            alignment: const Alignment(.92, -.55),
            child: _CharacterViewToggle(
              view: characterView,
              onChanged: _setCharacterView,
            ),
          ),
        ),
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
                  completedWeeklySessions: quests?.completedWeeklySessions ?? 0,
                  weeklySessionTarget: quests?.weeklySessionTarget ?? 3,
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

  Future<void> _setCharacterView(RatCharacterView view) async {
    if (view == characterView) return;
    setState(() => characterView = view);
    await RatInventoryStore.setCharacterView(view);
  }
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
  const _CharacterLayer({
    required this.level,
    required this.gender,
    required this.appearanceId,
    required this.view,
    required this.emoteSemanticLabel,
  });

  final int level;
  final RatGender gender;
  final String appearanceId;
  final RatCharacterView view;
  final String emoteSemanticLabel;
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
            child: GymRatCharacter(
              height: h,
              level: level,
              gender: gender,
              appearanceId: appearanceId,
              view: view,
              enableEmotes: true,
              emoteSemanticLabel: emoteSemanticLabel,
            ),
          ),
        ),
      );
    },
  );
}

class _GymRecordHotspots extends StatelessWidget {
  const _GymRecordHotspots({required this.history});

  final TrainingHistorySnapshot history;

  static const _stations = <_GymRecordStation>[
    _GymRecordStation(
      exerciseName: 'Bench Press',
      alignment: Alignment(-.82, -.20),
    ),
    _GymRecordStation(
      exerciseName: 'Barbell Row',
      alignment: Alignment(.82, -.08),
    ),
    _GymRecordStation(exerciseName: 'Squat', alignment: Alignment(.80, .43)),
    _GymRecordStation(
      exerciseName: 'Barbell Curl',
      alignment: Alignment(-.80, .38),
    ),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 116, 14, 150),
      child: Stack(
        children: [
          for (final station in _stations)
            if (TrainingAnalytics.exercise(
              history,
              station.exerciseName,
            ).sessionBests.isNotEmpty)
              Align(
                alignment: station.alignment,
                child: _GymRecordHotspot(
                  key: ValueKey('gym-record-${station.exerciseName}'),
                  semanticLabel:
                      '${WorkoutCopy.exercise(context, station.exerciseName)} ${context.tr.t('personalBest')}',
                  onTap: () => _showRecord(context, station.exerciseName),
                ),
              ),
        ],
      ),
    ),
  );

  void _showRecord(BuildContext context, String exerciseName) {
    final trend = TrainingAnalytics.exercise(history, exerciseName);
    PersonalBestRecord? record;
    for (final candidate in history.personalBests) {
      if (candidate.exerciseName == exerciseName) {
        record = candidate;
        break;
      }
    }
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _GymRecordSheet(
        trend: trend,
        recordBreaks: record?.improvementCount ?? 0,
        onOpenProgress: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExerciseProgressScreen(trend: trend),
            ),
          );
        },
      ),
    );
  }
}

class _GymRecordStation {
  const _GymRecordStation({
    required this.exerciseName,
    required this.alignment,
  });

  final String exerciseName;
  final Alignment alignment;
}

class _GymRecordHotspot extends StatelessWidget {
  const _GymRecordHotspot({
    super.key,
    required this.semanticLabel,
    required this.onTap,
  });

  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: Tooltip(
      message: semanticLabel,
      triggerMode: TooltipTriggerMode.longPress,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          radius: 42,
          splashColor: GymRatColors.gold.withValues(alpha: .24),
          highlightColor: GymRatColors.gold.withValues(alpha: .10),
          child: const SizedBox.square(dimension: 76),
        ),
      ),
    ),
  );
}

class _GymRecordSheet extends StatelessWidget {
  const _GymRecordSheet({
    required this.trend,
    required this.recordBreaks,
    required this.onOpenProgress,
  });

  final ExerciseTrend trend;
  final int recordBreaks;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
    decoration: const BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      border: Border(top: BorderSide(color: GymRatColors.goldDark)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: GymRatColors.border,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr.t('gymRecordStation'),
          style: const TextStyle(
            color: GymRatColors.gold,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          WorkoutCopy.exercise(context, trend.exerciseName),
          style: const TextStyle(
            color: GymRatColors.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _RecordMetric(
              label: context.tr.t('baseline'),
              value: WeightUnitStore.formatKilograms(trend.baseline),
            ),
            _RecordMetric(
              label: context.tr.t('personalBest'),
              value: WeightUnitStore.formatKilograms(trend.currentBest),
              highlighted: recordBreaks > 0,
            ),
            _RecordMetric(
              label: context.tr.t('recordBreaks'),
              value: '$recordBreaks',
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onOpenProgress,
            style: FilledButton.styleFrom(
              backgroundColor: GymRatColors.gold,
              foregroundColor: GymRatColors.black,
            ),
            icon: const Icon(Icons.show_chart_rounded),
            label: Text(
              context.tr.t('openFullProgress'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RecordMetric extends StatelessWidget {
  const _RecordMetric({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlighted ? GymRatColors.gold : GymRatColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
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

class _CharacterViewToggle extends StatelessWidget {
  const _CharacterViewToggle({required this.view, required this.onChanged});

  final RatCharacterView view;
  final ValueChanged<RatCharacterView> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: GymRatColors.black.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ViewButton(
          selected: view == RatCharacterView.front,
          icon: Icons.accessibility_new_rounded,
          tooltip: context.tr.t('frontView'),
          onTap: () => onChanged(RatCharacterView.front),
        ),
        _ViewButton(
          selected: view == RatCharacterView.back,
          icon: Icons.rotate_90_degrees_ccw_rounded,
          tooltip: context.tr.t('backView'),
          onTap: () => onChanged(RatCharacterView.back),
        ),
      ],
    ),
  );
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    required this.selected,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    iconSize: 18,
    color: selected ? GymRatColors.gold : GymRatColors.textMuted,
    icon: Icon(icon),
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
    required this.completedWeeklySessions,
    required this.weeklySessionTarget,
    required this.onQuests,
  });
  final int streak;
  final int completedWeeklySessions;
  final int weeklySessionTarget;
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
              Icons.calendar_today_rounded,
              size: 17,
              color: completedWeeklySessions == weeklySessionTarget
                  ? GymRatColors.gold
                  : GymRatColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              '${context.tr.t('weeklyShort')} '
              '$completedWeeklySessions/$weeklySessionTarget',
              style: TextStyle(
                color: completedWeeklySessions == weeklySessionTarget
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
    required this.onNutrition,
    required this.onArmory,
    required this.onProfile,
    required this.onContact,
    required this.onPremium,
    required this.onCharacterLab,
  });
  final VoidCallback onWorkout,
      onProgress,
      onHistory,
      onMissions,
      onNutrition,
      onArmory,
      onProfile,
      onContact,
      onPremium,
      onCharacterLab;
  void _open(BuildContext context, VoidCallback action) {
    action();
  }

  @override
  Widget build(BuildContext context) => Drawer(
    width: MediaQuery.sizeOf(context).width * .92,
    backgroundColor: GymRatColors.black,
    child: SafeArea(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, reveal, child) => Opacity(
          opacity: reveal.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(24 * (1 - reveal), 0),
            child: child,
          ),
        ),
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
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
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
                      premium: true,
                      onTap: () => _open(context, onNutrition),
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
                    _MenuItem(
                      icon: Icons.support_agent_rounded,
                      title: context.tr.t('contactSupport'),
                      onTap: () => _open(context, onContact),
                    ),
                    if (kDebugMode)
                      _MenuItem(
                        icon: Icons.science_outlined,
                        title: context.tr.t('characterLab'),
                        onTap: () => _open(context, onCharacterLab),
                      ),
                  ],
                ),
              ),
              const Divider(),
              _MenuItem(
                icon: Icons.workspace_premium_outlined,
                title: context.tr.t('premiumCoach'),
                premium: true,
                onTap: () => _open(context, onPremium),
              ),
            ],
          ),
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

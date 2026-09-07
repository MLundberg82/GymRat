import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../armory/data/armory_billing.dart';
import '../../premium/data/premium_access.dart';
import '../../premium/data/premium_local_access.dart';
import '../../premium/presentation/premium_gate_card.dart';
import '../../premium/presentation/premium_paywall_sheet.dart';
import '../../profile/data/training_profile_store.dart';
import '../../profile/domain/training_profile.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/nutrition_store.dart';
import '../domain/food_product.dart';
import '../domain/nutrition_models.dart';
import 'barcode_scanner_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key, this.premiumOverride});

  final bool? premiumOverride;

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  late Future<List<NutritionEntry>> _entries;

  bool get _isPremium => widget.premiumOverride ?? PremiumAccess.current;

  @override
  void initState() {
    super.initState();
    _entries = _isPremium
        ? NutritionStore.load()
        : Future.value(const <NutritionEntry>[]);
    ArmoryBilling.activeEntitlements.addListener(_accessChanged);
    PremiumLocalAccess.active.addListener(_accessChanged);
    if (!_isPremium && widget.premiumOverride == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isPremium) showPremiumPaywall(context);
      });
    }
  }

  void _accessChanged() {
    if (!mounted || widget.premiumOverride != null) return;
    setState(() {
      _entries = _isPremium
          ? NutritionStore.load()
          : Future.value(const <NutritionEntry>[]);
    });
  }

  @override
  void dispose() {
    ArmoryBilling.activeEntitlements.removeListener(_accessChanged);
    PremiumLocalAccess.active.removeListener(_accessChanged);
    super.dispose();
  }

  Future<void> _reload() async {
    final next = NutritionStore.load();
    setState(() {
      _entries = next;
    });
    await next;
  }

  Future<void> _addMeal() async {
    final draft = await showModalBottomSheet<_NutritionDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GymRatColors.surface,
      useSafeArea: true,
      builder: (_) => const _AddNutritionSheet(),
    );
    if (draft == null) return;
    await _saveDraft(draft);
  }

  Future<void> _scanFood() async {
    final product = await Navigator.of(context).push<FoodProduct>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (product == null || !mounted) return;
    final calculated = await showModalBottomSheet<_NutritionDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GymRatColors.surface,
      useSafeArea: true,
      builder: (_) => _ScannedFoodSheet(product: product),
    );
    if (calculated == null || !mounted) return;
    final reviewed = await showModalBottomSheet<_NutritionDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GymRatColors.surface,
      useSafeArea: true,
      builder: (_) => _AddNutritionSheet(initial: calculated),
    );
    if (reviewed == null) return;
    await _saveDraft(reviewed);
  }

  Future<void> _saveDraft(_NutritionDraft draft) async {
    await NutritionStore.add(
      name: draft.name,
      calories: draft.calories,
      proteinGrams: draft.proteinGrams,
      carbohydrateGrams: draft.carbohydrateGrams,
      fatGrams: draft.fatGrams,
    );
    HapticFeedback.mediumImpact();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final profile = TrainingProfileStore.profile.value;
    return Scaffold(
      backgroundColor: GymRatColors.black,
      appBar: AppBar(
        backgroundColor: GymRatColors.black,
        foregroundColor: GymRatColors.textPrimary,
        title: Text(
          context.tr.t('nutritionTitle'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (_isPremium)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: GymRatColors.premium,
              ),
            ),
        ],
      ),
      floatingActionButton: _isPremium && (profile?.ageYears ?? 0) >= 18
          ? FloatingActionButton.extended(
              onPressed: _addMeal,
              backgroundColor: GymRatColors.green,
              foregroundColor: GymRatColors.black,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                context.tr.t('logMeal'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
      body: _isPremium
          ? _PremiumNutritionBody(
              profile: profile,
              entries: _entries,
              onReload: _reload,
              onScan: _scanFood,
            )
          : const _LockedNutritionBody(),
    );
  }
}

class _LockedNutritionBody extends StatelessWidget {
  const _LockedNutritionBody();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
    children: [
      const _NutritionHero(locked: true),
      const SizedBox(height: 18),
      GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.20,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _LockedMetric(label: context.tr.t('calories')),
          _LockedMetric(label: context.tr.t('protein')),
          _LockedMetric(label: context.tr.t('carbohydrates')),
          _LockedMetric(label: context.tr.t('fat')),
        ],
      ),
      const SizedBox(height: 18),
      const PremiumGateCard(),
    ],
  );
}

class _PremiumNutritionBody extends StatefulWidget {
  const _PremiumNutritionBody({
    required this.profile,
    required this.entries,
    required this.onReload,
    required this.onScan,
  });

  final TrainingProfile? profile;
  final Future<List<NutritionEntry>> entries;
  final Future<void> Function() onReload;
  final VoidCallback onScan;

  @override
  State<_PremiumNutritionBody> createState() => _PremiumNutritionBodyState();
}

class _PremiumNutritionBodyState extends State<_PremiumNutritionBody> {
  NutritionHistoryPeriod _historyPeriod = NutritionHistoryPeriod.week;

  @override
  Widget build(BuildContext context) {
    if (widget.profile == null ||
        widget.profile!.ageYears == null ||
        widget.profile!.ageYears! < 18) {
      final adultOnly =
          widget.profile?.ageYears != null && widget.profile!.ageYears! < 18;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        children: [
          const _NutritionHero(locked: false),
          const SizedBox(height: 18),
          _AgeRequiredCard(
            adultOnly: adultOnly,
            onOpenProfile: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
              await widget.onReload();
            },
          ),
        ],
      );
    }
    final target = NutritionCalculator.targetsFor(widget.profile!)!;
    return FutureBuilder<List<NutritionEntry>>(
      future: widget.entries,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: GymRatColors.green),
          );
        }
        final allEntries = snapshot.data ?? const <NutritionEntry>[];
        final now = DateTime.now();
        final todayEntries = allEntries
            .where((entry) => NutritionCalculator.sameDay(entry.loggedAt, now))
            .toList(growable: false);
        final totals = NutritionTotals.fromEntries(todayEntries);
        return RefreshIndicator(
          onRefresh: widget.onReload,
          color: GymRatColors.green,
          backgroundColor: GymRatColors.surfaceElevated,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
            children: [
              const _NutritionHero(locked: false),
              const SizedBox(height: 18),
              _DailyEnergyCard(totals: totals, target: target),
              const SizedBox(height: 12),
              _MacroGrid(totals: totals, target: target),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(
                    context.tr.t('scanBarcode'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.tr.t('barcodeDataNotice'),
                style: const TextStyle(
                  color: GymRatColors.textMuted,
                  fontSize: 9,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              _SectionTitle(
                title: context.tr.t('dailyMealPlan'),
                subtitle: context.tr.t('dailyMealPlanHelp'),
              ),
              const SizedBox(height: 10),
              _MealPlanCard(suggestions: NutritionMealPlanner.planFor(target)),
              const SizedBox(height: 22),
              _SectionTitle(
                title: context.tr.t('nutritionHistory'),
                subtitle: context.tr.t('nutritionHistoryHelp'),
              ),
              const SizedBox(height: 10),
              _NutritionPeriodSelector(
                selected: _historyPeriod,
                onChanged: (period) => setState(() => _historyPeriod = period),
              ),
              const SizedBox(height: 10),
              _NutritionHistoryChart(
                entries: allEntries,
                target: target,
                period: _historyPeriod,
              ),
              const SizedBox(height: 22),
              _SectionTitle(
                title: context.tr.t('todaysMeals'),
                subtitle: context.tr.t('manualNutritionHelp'),
              ),
              const SizedBox(height: 10),
              if (todayEntries.isEmpty)
                const _EmptyMeals()
              else
                for (final entry in todayEntries)
                  _MealCard(entry: entry, onReload: widget.onReload),
              const SizedBox(height: 18),
              const _NutritionSafetyNote(),
            ],
          ),
        );
      },
    );
  }
}

class _NutritionHero extends StatelessWidget {
  const _NutritionHero({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2B1B4B), Color(0xFF132019), GymRatColors.surface],
      ),
      border: Border.all(color: GymRatColors.premium.withValues(alpha: .62)),
      boxShadow: [
        BoxShadow(
          color: GymRatColors.premium.withValues(alpha: .10),
          blurRadius: 32,
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GymRatColors.green.withValues(alpha: .12),
            border: Border.all(color: GymRatColors.greenDark),
          ),
          child: Icon(
            locked ? Icons.lock_rounded : Icons.restaurant_menu_rounded,
            color: locked ? GymRatColors.premium : GymRatColors.green,
            size: 31,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.t('nutritionCommandCenter'),
                style: const TextStyle(
                  color: GymRatColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.tr.t('nutritionHeroHelp'),
                style: const TextStyle(
                  color: GymRatColors.textSecondary,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LockedMetric extends StatelessWidget {
  const _LockedMetric({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline_rounded, color: GymRatColors.premium),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        const Text(
          '•••',
          style: TextStyle(color: GymRatColors.textMuted, fontSize: 18),
        ),
      ],
    ),
  );
}

class _AgeRequiredCard extends StatelessWidget {
  const _AgeRequiredCard({required this.onOpenProfile, this.adultOnly = false});

  final VoidCallback onOpenProfile;
  final bool adultOnly;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: GymRatColors.goldDark),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr.t(
            adultOnly ? 'nutritionAdultOnlyTitle' : 'ageRequiredTitle',
          ),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Text(
          context.tr.t(
            adultOnly ? 'nutritionAdultOnlyHelp' : 'ageRequiredHelp',
          ),
          style: const TextStyle(
            color: GymRatColors.textSecondary,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        if (!adultOnly) ...[
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: onOpenProfile,
            icon: const Icon(Icons.person_outline_rounded),
            label: Text(context.tr.t('openProfile')),
          ),
        ],
      ],
    ),
  );
}

class _DailyEnergyCard extends StatelessWidget {
  const _DailyEnergyCard({required this.totals, required this.target});

  final NutritionTotals totals;
  final NutritionTargets target;

  @override
  Widget build(BuildContext context) {
    final progress = target.calories == 0
        ? 0.0
        : (totals.calories / target.calories).clamp(0.0, 1.0);
    final remaining = math.max(0, target.calories - totals.calories);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: GymRatColors.greenDark),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: GymRatColors.surfaceElevated,
                  color: GymRatColors.green,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${totals.calories}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '/ ${target.calories}',
                        style: const TextStyle(
                          color: GymRatColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.t('dailyEnergyTarget'),
                  style: const TextStyle(
                    color: GymRatColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$remaining ${context.tr.t('kcalRemaining')}',
                  style: const TextStyle(
                    color: GymRatColors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr.t('nutritionTargetHelp'),
                  style: const TextStyle(
                    color: GymRatColors.textMuted,
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroGrid extends StatelessWidget {
  const _MacroGrid({required this.totals, required this.target});

  final NutritionTotals totals;
  final NutritionTargets target;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _MacroCard(
          label: context.tr.t('protein'),
          current: totals.proteinGrams,
          target: target.proteinGrams,
          color: GymRatColors.gold,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _MacroCard(
          label: context.tr.t('carbohydrates'),
          current: totals.carbohydrateGrams,
          target: target.carbohydrateGrams,
          color: GymRatColors.green,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _MacroCard(
          label: context.tr.t('fat'),
          current: totals.fatGrams,
          target: target.fatGrams,
          color: GymRatColors.premium,
        ),
      ),
    ],
  );
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  final String label;
  final double current;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 13),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${current.round()} / $target g',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: GymRatColors.surfaceElevated,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(
          color: GymRatColors.textMuted,
          fontSize: 10,
          height: 1.35,
        ),
      ),
    ],
  );
}

class _MealPlanCard extends StatelessWidget {
  const _MealPlanCard({required this.suggestions});

  final List<MealPlanSuggestion> suggestions;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: GymRatColors.greenDark),
    ),
    child: Column(
      children: [
        for (var index = 0; index < suggestions.length; index++) ...[
          _MealPlanRow(suggestion: suggestions[index]),
          if (index != suggestions.length - 1)
            const Divider(height: 22, color: GymRatColors.border),
        ],
        const SizedBox(height: 12),
        Text(
          context.tr.t('mealPlanSafety'),
          style: const TextStyle(
            color: GymRatColors.textMuted,
            fontSize: 9,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _MealPlanRow extends StatelessWidget {
  const _MealPlanRow({required this.suggestion});

  final MealPlanSuggestion suggestion;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: GymRatColors.green.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(
          Icons.restaurant_menu_rounded,
          color: GymRatColors.green,
          size: 18,
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.t(suggestion.titleKey),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              context.tr.t(suggestion.descriptionKey),
              style: const TextStyle(
                color: GymRatColors.textMuted,
                fontSize: 9,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${suggestion.calories} kcal',
            style: const TextStyle(
              color: GymRatColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${suggestion.proteinGrams} P · '
            '${suggestion.carbohydrateGrams} C · ${suggestion.fatGrams} F',
            style: const TextStyle(color: GymRatColors.textMuted, fontSize: 8),
          ),
        ],
      ),
    ],
  );
}

class _NutritionPeriodSelector extends StatelessWidget {
  const _NutritionPeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  final NutritionHistoryPeriod selected;
  final ValueChanged<NutritionHistoryPeriod> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<NutritionHistoryPeriod>(
    showSelectedIcon: false,
    segments: [
      for (final period in NutritionHistoryPeriod.values)
        ButtonSegment(
          value: period,
          label: Text(
            context.tr.t(
              'nutritionPeriod${period.name[0].toUpperCase()}${period.name.substring(1)}',
            ),
          ),
        ),
    ],
    selected: {selected},
    onSelectionChanged: (value) => onChanged(value.first),
    style: const ButtonStyle(visualDensity: VisualDensity.compact),
  );
}

class _NutritionHistoryChart extends StatelessWidget {
  const _NutritionHistoryChart({
    required this.entries,
    required this.target,
    required this.period,
  });

  final List<NutritionEntry> entries;
  final NutritionTargets target;
  final NutritionHistoryPeriod period;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final buckets = NutritionHistory.buckets(
      entries: entries,
      period: period,
      now: now,
      dailyCalorieTarget: target.calories,
    );
    final periodTotals = NutritionTotals.fromEntries(
      NutritionHistory.entriesFor(entries: entries, period: period, now: now),
    );
    return Container(
      height: 208,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: GymRatColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${periodTotals.calories} kcal · '
            '${periodTotals.proteinGrams.round()} g '
            '${context.tr.t('protein').toLowerCase()}',
            style: const TextStyle(
              color: GymRatColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bucket in buckets)
                  Expanded(
                    child: _HistoryBar(
                      label: bucket.label,
                      calories: bucket.totals.calories,
                      target: bucket.targetCalories,
                      highlighted:
                          !now.isBefore(bucket.start) &&
                          now.isBefore(bucket.end),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBar extends StatelessWidget {
  const _HistoryBar({
    required this.label,
    required this.calories,
    required this.target,
    required this.highlighted,
  });

  final String label;
  final int calories;
  final int target;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final ratio = target == 0 ? 0.0 : (calories / target).clamp(0.0, 1.15);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            calories == 0 ? '—' : '$calories',
            style: TextStyle(
              color: highlighted ? GymRatColors.green : GymRatColors.textMuted,
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: math.max(5, 96 * ratio),
            decoration: BoxDecoration(
              color: highlighted ? GymRatColors.green : GymRatColors.goldDark,
              borderRadius: BorderRadius.circular(7),
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: GymRatColors.green.withValues(alpha: .22),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              color: highlighted
                  ? GymRatColors.textPrimary
                  : GymRatColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.entry, required this.onReload});

  final NutritionEntry entry;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey(entry.id),
    direction: DismissDirection.endToStart,
    confirmDismiss: (_) => showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr.t('deleteMealTitle')),
        content: Text(context.tr.t('deleteMealHelp')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: GymRatColors.danger),
            child: Text(context.tr.t('deleteLabel')),
          ),
        ],
      ),
    ),
    onDismissed: (_) async {
      await NutritionStore.delete(entry.id);
      await onReload();
    },
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: GymRatColors.danger.withValues(alpha: .20),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: GymRatColors.danger,
      ),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GymRatColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: GymRatColors.green.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: GymRatColors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.proteinGrams.round()} P · '
                  '${entry.carbohydrateGrams.round()} C · '
                  '${entry.fatGrams.round()} F',
                  style: const TextStyle(
                    color: GymRatColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.calories} kcal',
            style: const TextStyle(
              color: GymRatColors.gold,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.add_circle_outline_rounded,
          color: GymRatColors.textMuted,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr.t('noMealsLogged'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GymRatColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _NutritionSafetyNote extends StatelessWidget {
  const _NutritionSafetyNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: GymRatColors.textMuted),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            context.tr.t('nutritionSafetyNote'),
            style: const TextStyle(
              color: GymRatColors.textMuted,
              fontSize: 9,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ScannedFoodSheet extends StatefulWidget {
  const _ScannedFoodSheet({required this.product});

  final FoodProduct product;

  @override
  State<_ScannedFoodSheet> createState() => _ScannedFoodSheetState();
}

class _ScannedFoodSheetState extends State<_ScannedFoodSheet> {
  late final TextEditingController _grams;

  @override
  void initState() {
    super.initState();
    final suggested = widget.product.servingGrams;
    _grams = TextEditingController(
      text: _displayNutritionNumber(
        suggested != null && suggested > 0 ? suggested : 100,
      ),
    );
  }

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  double get _amount =>
      double.tryParse(_grams.text.trim().replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final nutrition = widget.product.nutritionForGrams(_amount);
    final productName = widget.product.brand == null
        ? widget.product.name
        : '${widget.product.brand} · ${widget.product.name}';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: GymRatColors.green,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr.t('barcodeProductFound'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              productName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              widget.product.barcode,
              style: const TextStyle(
                color: GymRatColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _grams,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.tr.t('consumedAmount'),
                suffixText: 'g',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ScannedMacro(
                  label: context.tr.t('calories'),
                  value: '${nutrition.calories}',
                ),
                _ScannedMacro(
                  label: context.tr.t('protein'),
                  value: '${nutrition.proteinGrams.round()} g',
                ),
                _ScannedMacro(
                  label: context.tr.t('carbohydrates'),
                  value: '${nutrition.carbohydrateGrams.round()} g',
                ),
                _ScannedMacro(
                  label: context.tr.t('fat'),
                  value: '${nutrition.fatGrams.round()} g',
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              context.tr.t('barcodeReviewNotice'),
              style: const TextStyle(
                color: GymRatColors.textMuted,
                fontSize: 10,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _amount <= 0 || _amount > 5000
                    ? null
                    : () => Navigator.of(context).pop(
                        _NutritionDraft(
                          name: widget.product.name,
                          calories: nutrition.calories,
                          proteinGrams: nutrition.proteinGrams,
                          carbohydrateGrams: nutrition.carbohydrateGrams,
                          fatGrams: nutrition.fatGrams,
                        ),
                      ),
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(
                  context.tr.t('reviewNutritionValues'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannedMacro extends StatelessWidget {
  const _ScannedMacro({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: GymRatColors.gold,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: GymRatColors.textMuted, fontSize: 8),
        ),
      ],
    ),
  );
}

class _NutritionDraft {
  const _NutritionDraft({
    required this.name,
    required this.calories,
    required this.proteinGrams,
    required this.carbohydrateGrams,
    required this.fatGrams,
  });

  final String name;
  final int calories;
  final double proteinGrams;
  final double carbohydrateGrams;
  final double fatGrams;
}

class _AddNutritionSheet extends StatefulWidget {
  const _AddNutritionSheet({this.initial});

  final _NutritionDraft? initial;

  @override
  State<_AddNutritionSheet> createState() => _AddNutritionSheetState();
}

class _AddNutritionSheetState extends State<_AddNutritionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbohydrates;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name);
    _calories = TextEditingController(text: initial?.calories.toString());
    _protein = TextEditingController(
      text: initial == null
          ? null
          : _displayNutritionNumber(initial.proteinGrams),
    );
    _carbohydrates = TextEditingController(
      text: initial == null
          ? null
          : _displayNutritionNumber(initial.carbohydrateGrams),
    );
    _fat = TextEditingController(
      text: initial == null ? null : _displayNutritionNumber(initial.fatGrams),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbohydrates.dispose();
    _fat.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _NutritionDraft(
        name: _name.text.trim(),
        calories: _number(_calories).round(),
        proteinGrams: _number(_protein),
        carbohydrateGrams: _number(_carbohydrates),
        fatGrams: _number(_fat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      18,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr.t('logMealTitle'),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.tr.t('manualNutritionHelp'),
              style: const TextStyle(
                color: GymRatColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: context.tr.t('mealName')),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.tr.t('requiredField')
                  : null,
            ),
            const SizedBox(height: 10),
            _NumberField(
              controller: _calories,
              label: context.tr.t('caloriesKcal'),
              required: true,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _protein,
                    label: '${context.tr.t('protein')} (g)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: _carbohydrates,
                    label: '${context.tr.t('carbohydrates')} (g)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: _fat,
                    label: '${context.tr.t('fat')} (g)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  context.tr.t('addMeal'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
      if (required && (number == null || number <= 0)) {
        return context.tr.t('requiredField');
      }
      if (number != null && (number < 0 || number > 10000)) {
        return context.tr.t('invalidNumber');
      }
      return null;
    },
  );
}

String _displayNutritionNumber(double value) {
  final rounded = value.roundToDouble();
  return value == rounded ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

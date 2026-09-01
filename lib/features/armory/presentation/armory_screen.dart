import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../rewards/domain/gym_upgrade.dart';
import '../../character/domain/rat_appearance.dart';
import '../../character/presentation/gymrat_character.dart';
import '../../profile/data/training_profile_store.dart';
import '../../profile/domain/training_profile.dart';
import '../../workout/data/workout_session_store.dart';
import '../data/armory_billing.dart';
import '../data/rat_inventory_store.dart';
import '../domain/rat_item.dart';

class ArmoryScreen extends StatefulWidget {
  const ArmoryScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ArmoryScreen> createState() => _ArmoryScreenState();
}

class _ArmoryData {
  const _ArmoryData({
    required this.player,
    required this.store,
    required this.inventory,
  });

  final PlayerProgress player;
  final ArmoryStoreSnapshot store;
  final RatInventoryState inventory;
}

class _ArmoryScreenState extends State<ArmoryScreen> {
  late Future<_ArmoryData> _data;
  String? _busyOffer;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_ArmoryData> _load() async {
    final results = await Future.wait<Object>([
      WorkoutSessionStore.getPlayerProgress(),
      ArmoryBilling.loadStore(),
      RatInventoryStore.load(),
    ]);
    return _ArmoryData(
      player: results[0] as PlayerProgress,
      store: results[1] as ArmoryStoreSnapshot,
      inventory: results[2] as RatInventoryState,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _data = next);
    await next;
  }

  Future<void> _purchase(ArmoryOffer offer) async {
    final cosmetic = RatItemCatalog.byStoreProductId(offer.identifier);
    if (cosmetic != null &&
        (!cosmetic.hasCompleteAppearance ||
            !RatAppearanceCatalog.isReady(cosmetic.appearanceId))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.t('appearancePurchaseBlocked'))),
      );
      return;
    }
    setState(() => _busyOffer = offer.identifier);
    final result = await ArmoryBilling.purchase(offer);
    if (!mounted) return;
    setState(() => _busyOffer = null);
    if (result == ArmoryPurchaseStatus.cancelled) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr.t(
            result == ArmoryPurchaseStatus.purchased
                ? 'armoryPurchaseComplete'
                : 'armoryPurchaseFailed',
          ),
        ),
      ),
    );
    if (result == ArmoryPurchaseStatus.purchased) {
      final item = RatItemCatalog.byStoreProductId(offer.identifier);
      if (item != null) await RatInventoryStore.grantPurchased(item);
      if (mounted) await _refresh();
    }
  }

  Future<void> _restore() async {
    final restored = await ArmoryBilling.restore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr.t(
            restored ? 'armoryRestoreComplete' : 'armoryRestoreFailed',
          ),
        ),
      ),
    );
    if (restored) await _refresh();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    initialIndex: widget.initialTab.clamp(0, 1),
    child: Scaffold(
      backgroundColor: GymRatColors.black,
      appBar: AppBar(
        backgroundColor: GymRatColors.black,
        foregroundColor: GymRatColors.textPrimary,
        title: Text(
          context.tr.t('armoryTitle'),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
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
            Tab(text: context.tr.t('armoryCollection')),
            Tab(text: context.tr.t('armoryStore')),
          ],
        ),
      ),
      body: FutureBuilder<_ArmoryData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: GymRatColors.gold),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text(
                context.tr.t('armoryLoadError'),
                style: const TextStyle(color: GymRatColors.textSecondary),
              ),
            );
          }
          final data = snapshot.requireData;
          return TabBarView(
            children: [
              _CollectionTab(
                player: data.player,
                inventory: data.inventory,
                onRefresh: _refresh,
              ),
              _StoreTab(
                store: data.store,
                busyOffer: _busyOffer,
                onPurchase: _purchase,
                onRestore: _restore,
                onRefresh: _refresh,
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _CollectionTab extends StatelessWidget {
  const _CollectionTab({
    required this.player,
    required this.inventory,
    required this.onRefresh,
  });

  final PlayerProgress player;
  final RatInventoryState inventory;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final upgrades = GymUpgradeCatalog.all;
    final unlocked = upgrades
        .where((upgrade) => upgrade.level <= player.level)
        .length;
    final next = upgrades.where((upgrade) => upgrade.level > player.level);
    final nextUpgrade = next.isEmpty ? null : next.first;

    return RefreshIndicator(
      color: GymRatColors.gold,
      backgroundColor: GymRatColors.surfaceElevated,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          _CollectionHeader(
            level: player.level,
            unlocked: unlocked,
            total: upgrades.length,
            nextUpgrade: nextUpgrade,
          ),
          const SizedBox(height: 20),
          _RatAppearanceSection(
            level: player.level,
            inventory: inventory,
            gender:
                TrainingProfileStore.profile.value?.gender ??
                RatGender.nonBinary,
          ),
          const SizedBox(height: 20),
          Text(
            context.tr.t('armoryEarnedUpgrades'),
            style: const TextStyle(
              color: GymRatColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          for (final upgrade in upgrades) ...[
            _UpgradeCard(
              upgrade: upgrade,
              unlocked: upgrade.level <= player.level,
            ),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.level,
    required this.unlocked,
    required this.total,
    required this.nextUpgrade,
  });

  final int level;
  final int unlocked;
  final int total;
  final GymUpgrade? nextUpgrade;

  @override
  Widget build(BuildContext context) {
    final nextLevel = nextUpgrade?.level;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF30230B), GymRatColors.surface, Color(0xFF0B0C0C)],
        ),
        border: Border.all(color: GymRatColors.goldDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: GymRatColors.gold.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: GymRatColors.gold.withValues(alpha: .35),
                  ),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: GymRatColors.gold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.t('armoryCollectionTitle'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr.t('armoryCollectionSubtitle'),
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
              _HeaderMetric(
                value: '$unlocked / $total',
                label: context.tr.t('armoryUnlockedCount'),
              ),
              const SizedBox(width: 22),
              _HeaderMetric(
                value: '${context.tr.t('level')} $level',
                label: nextLevel == null
                    ? context.tr.t('armoryComplete')
                    : '${context.tr.t('armoryNext')} $nextLevel',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          style: const TextStyle(
            color: GymRatColors.gold,
            fontSize: 16,
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
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.upgrade, required this.unlocked});

  final GymUpgrade upgrade;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? GymRatColors.gold : GymRatColors.textMuted;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? GymRatColors.gold.withValues(alpha: .34)
              : GymRatColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: unlocked ? .12 : .07),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_upgradeIcon(upgrade.type), color: color, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.t(upgrade.nameKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unlocked
                        ? GymRatColors.textPrimary
                        : GymRatColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${context.tr.t('level')} ${upgrade.level}',
                  style: const TextStyle(
                    color: GymRatColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _RatAppearanceSection extends StatefulWidget {
  const _RatAppearanceSection({
    required this.level,
    required this.inventory,
    required this.gender,
  });

  final int level;
  final RatInventoryState inventory;
  final RatGender gender;

  @override
  State<_RatAppearanceSection> createState() => _RatAppearanceSectionState();
}

class _RatAppearanceSectionState extends State<_RatAppearanceSection> {
  RatItem? previewItem;
  RatCharacterView view = RatCharacterView.front;

  @override
  Widget build(BuildContext context) {
    final appearance = RatAppearanceCatalog.byId(
      widget.inventory.equippedAppearanceId,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr.t('ratLoadout'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Icon(
              Icons.hexagon_rounded,
              color: GymRatColors.gold,
              size: 17,
            ),
            const SizedBox(width: 5),
            Text(
              '${widget.inventory.credits}',
              style: const TextStyle(
                color: GymRatColors.gold,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _RankTrack(level: widget.level),
        const SizedBox(height: 12),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: GymRatColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: GymRatColors.goldDark),
            gradient: const RadialGradient(
              center: Alignment(0, .15),
              radius: .75,
              colors: [Color(0xFF253021), GymRatColors.surface],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: GymRatCharacter(
                  height: 285,
                  level: widget.level,
                  gender: widget.gender,
                  view: view,
                  appearanceId: appearance.id,
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: SegmentedButton<RatCharacterView>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    ButtonSegment(
                      value: RatCharacterView.front,
                      icon: const Icon(
                        Icons.accessibility_new_rounded,
                        size: 17,
                      ),
                      tooltip: context.tr.t('frontView'),
                    ),
                    ButtonSegment(
                      value: RatCharacterView.back,
                      icon: const Icon(
                        Icons.rotate_90_degrees_ccw_rounded,
                        size: 17,
                      ),
                      tooltip: context.tr.t('backView'),
                    ),
                  ],
                  selected: {view},
                  onSelectionChanged: (value) =>
                      setState(() => view = value.first),
                ),
              ),
              if (previewItem != null)
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: GymRatColors.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      context.tr.t('itemConcept'),
                      style: const TextStyle(
                        color: GymRatColors.black,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr.t('ratItemsHelp'),
          style: const TextStyle(color: GymRatColors.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 10),
        if (previewItem case final item?) ...[
          _ItemConceptPreview(item: item),
          const SizedBox(height: 10),
        ],
        for (final item in RatItemCatalog.featuredItems) ...[
          _RatItemCard(
            item: item,
            level: widget.level,
            owned: widget.inventory.owns(item, widget.level),
            selected: previewItem?.id == item.id,
            onPreview: () => setState(() => previewItem = item),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ItemConceptPreview extends StatelessWidget {
  const _ItemConceptPreview({required this.item});

  final RatItem item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: GymRatColors.surfaceElevated,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GymRatColors.goldDark),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 78,
          height: 78,
          child: item.previewAssetPath == null
              ? Icon(
                  _ratItemIcon(item.slot),
                  color: GymRatColors.gold,
                  size: 34,
                )
              : Image.asset(
                  item.previewAssetPath!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.t(item.nameKey),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                context.tr.t('appearanceInForgeMessage'),
                style: const TextStyle(
                  color: GymRatColors.textSecondary,
                  fontSize: 10,
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

class _RankTrack extends StatelessWidget {
  const _RankTrack({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr.t('levelRewards')} · ${level.clamp(1, 50)} / 50',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: 31,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 49,
            separatorBuilder: (_, _) => const SizedBox(width: 5),
            itemBuilder: (context, index) {
              final rewardLevel = index + 2;
              final unlocked = rewardLevel <= level;
              return Container(
                width: 31,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked
                      ? GymRatColors.gold.withValues(alpha: .16)
                      : GymRatColors.surfaceElevated,
                  border: Border.all(
                    color: unlocked ? GymRatColors.gold : GymRatColors.border,
                  ),
                ),
                child: Text(
                  '$rewardLevel',
                  style: TextStyle(
                    color: unlocked
                        ? GymRatColors.gold
                        : GymRatColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _RatItemCard extends StatelessWidget {
  const _RatItemCard({
    required this.item,
    required this.level,
    required this.owned,
    required this.selected,
    required this.onPreview,
  });

  final RatItem item;
  final int level;
  final bool owned;
  final bool selected;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPreview,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: selected
              ? GymRatColors.gold
              : owned
              ? GymRatColors.greenDark
              : GymRatColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (owned ? GymRatColors.gold : GymRatColors.green)
                  .withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.previewAssetPath != null
                ? Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(
                      item.previewAssetPath!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  )
                : Icon(
                    _ratItemIcon(item.slot),
                    color: owned ? GymRatColors.gold : GymRatColors.textMuted,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.t(item.nameKey),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.unlockLevel != null
                      ? '${context.tr.t('level')} ${item.unlockLevel}'
                      : context.tr.t('appearanceInForge'),
                  style: const TextStyle(
                    color: GymRatColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (owned)
            Text(
              context.tr.t('armoryOwned'),
              style: const TextStyle(
                color: GymRatColors.gold,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            )
          else if (item.unlockLevel == null)
            Text(
              context.tr.t('appearanceInForge'),
              style: const TextStyle(
                color: GymRatColors.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            )
          else
            const Icon(Icons.lock_rounded, color: GymRatColors.textMuted),
        ],
      ),
    ),
  );
}

IconData _ratItemIcon(RatItemSlot slot) => switch (slot) {
  RatItemSlot.head => Icons.sports_martial_arts_rounded,
  RatItemSlot.neck => Icons.link_rounded,
  RatItemSlot.top => Icons.checkroom_rounded,
  RatItemSlot.bottom => Icons.dry_cleaning_rounded,
  RatItemSlot.feet => Icons.directions_run_rounded,
  RatItemSlot.belt => Icons.shield_rounded,
  RatItemSlot.collectible => Icons.military_tech_rounded,
  RatItemSlot.aura => Icons.auto_awesome_rounded,
};

class _StoreTab extends StatelessWidget {
  const _StoreTab({
    required this.store,
    required this.busyOffer,
    required this.onPurchase,
    required this.onRestore,
    required this.onRefresh,
  });

  final ArmoryStoreSnapshot store;
  final String? busyOffer;
  final Future<void> Function(ArmoryOffer offer) onPurchase;
  final Future<void> Function() onRestore;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final visibleOffers = store.offers
        .where((offer) {
          final cosmetic = RatItemCatalog.byStoreProductId(offer.identifier);
          if (cosmetic == null) return true;
          return cosmetic.hasCompleteAppearance &&
              RatAppearanceCatalog.byProductId(offer.identifier) != null;
        })
        .toList(growable: false);
    final visibleStatus =
        store.status == ArmoryStoreStatus.ready && visibleOffers.isEmpty
        ? ArmoryStoreStatus.empty
        : store.status;

    return RefreshIndicator(
      color: GymRatColors.premium,
      backgroundColor: GymRatColors.surfaceElevated,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          _StoreHeader(
            onRestore: onRestore,
            canRestore: ArmoryBilling.isConfigured,
          ),
          const SizedBox(height: 18),
          if (visibleStatus == ArmoryStoreStatus.ready)
            for (final offer in visibleOffers) ...[
              _OfferCard(
                offer: offer,
                busy: busyOffer == offer.identifier,
                onPurchase: () => onPurchase(offer),
              ),
              const SizedBox(height: 10),
            ]
          else
            _StoreState(status: visibleStatus),
        ],
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.onRestore, required this.canRestore});

  final Future<void> Function() onRestore;
  final bool canRestore;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF241A3D), GymRatColors.surface, Color(0xFF0B0C0C)],
      ),
      border: Border.all(color: GymRatColors.premium.withValues(alpha: .5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome_rounded, color: GymRatColors.premium),
        const SizedBox(height: 12),
        Text(
          context.tr.t('armoryVaultTitle'),
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr.t('armoryVaultSubtitle'),
          style: const TextStyle(
            color: GymRatColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: canRestore ? onRestore : null,
          icon: const Icon(Icons.restore_rounded, size: 18),
          label: Text(context.tr.t('restorePurchases')),
          style: TextButton.styleFrom(foregroundColor: GymRatColors.premium),
        ),
      ],
    ),
  );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.busy,
    required this.onPurchase,
  });

  final ArmoryOffer offer;
  final bool busy;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: GymRatColors.premium.withValues(alpha: .34)),
    ),
    child: Row(
      children: [
        const Icon(Icons.diamond_outlined, color: GymRatColors.premium),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (offer.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  offer.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GymRatColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: busy || offer.isOwned ? null : onPurchase,
          style: FilledButton.styleFrom(
            backgroundColor: GymRatColors.premium,
            foregroundColor: GymRatColors.black,
          ),
          child: busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  offer.isOwned ? context.tr.t('armoryOwned') : offer.price,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
        ),
      ],
    ),
  );
}

class _StoreState extends StatelessWidget {
  const _StoreState({required this.status});

  final ArmoryStoreStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, titleKey, messageKey) = switch (status) {
      ArmoryStoreStatus.notConfigured => (
        Icons.lock_clock_rounded,
        'armoryStorePreparing',
        'armoryStorePreparingMessage',
      ),
      ArmoryStoreStatus.empty => (
        Icons.inventory_2_outlined,
        'armoryStoreEmpty',
        'armoryStoreEmptyMessage',
      ),
      _ => (
        Icons.cloud_off_rounded,
        'armoryStoreUnavailable',
        'armoryStoreUnavailableMessage',
      ),
    };
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GymRatColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GymRatColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: GymRatColors.textMuted),
          const SizedBox(height: 12),
          Text(
            context.tr.t(titleKey),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            context.tr.t(messageKey),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _upgradeIcon(GymUpgradeType type) => switch (type) {
  GymUpgradeType.dumbbellRack ||
  GymUpgradeType.weightPlates => Icons.fitness_center_rounded,
  GymUpgradeType.neonLights ||
  GymUpgradeType.spotlights => Icons.lightbulb_rounded,
  GymUpgradeType.powerRack ||
  GymUpgradeType.liftingPlatform => Icons.foundation_rounded,
  GymUpgradeType.banner => Icons.flag_rounded,
  GymUpgradeType.speakers => Icons.speaker_rounded,
  GymUpgradeType.championPlaque => Icons.emoji_events_rounded,
  GymUpgradeType.cardio => Icons.directions_run_rounded,
  GymUpgradeType.recovery => Icons.health_and_safety_rounded,
  GymUpgradeType.strongman => Icons.sports_mma_rounded,
  GymUpgradeType.architecture => Icons.castle_rounded,
};

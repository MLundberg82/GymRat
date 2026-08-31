import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../rewards/domain/gym_upgrade.dart';
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
    if (result == ArmoryPurchaseStatus.purchased) await _refresh();
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

  Future<void> _equip(RatItem item, int level) async {
    await RatInventoryStore.equip(item, level: level);
    if (mounted) await _refresh();
  }

  Future<void> _buyWithCredits(RatItem item, int level) async {
    final result = await RatInventoryStore.purchase(item, level: level);
    if (!mounted) return;
    final key = switch (result) {
      RatItemPurchaseResult.purchased => 'armoryCreditPurchaseComplete',
      RatItemPurchaseResult.insufficientCredits => 'notEnoughCredits',
      RatItemPurchaseResult.alreadyOwned => 'armoryAlreadyOwned',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr.t(key))));
    await _refresh();
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
                onEquip: _equip,
                onBuy: _buyWithCredits,
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
    required this.onEquip,
    required this.onBuy,
    required this.onRefresh,
  });

  final PlayerProgress player;
  final RatInventoryState inventory;
  final Future<void> Function(RatItem item, int level) onEquip;
  final Future<void> Function(RatItem item, int level) onBuy;
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
          _RatLoadoutSection(
            level: player.level,
            inventory: inventory,
            gender:
                TrainingProfileStore.profile.value?.gender ??
                RatGender.nonBinary,
            onEquip: onEquip,
            onBuy: onBuy,
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

class _RatLoadoutSection extends StatelessWidget {
  const _RatLoadoutSection({
    required this.level,
    required this.inventory,
    required this.gender,
    required this.onEquip,
    required this.onBuy,
  });

  final int level;
  final RatInventoryState inventory;
  final RatGender gender;
  final Future<void> Function(RatItem item, int level) onEquip;
  final Future<void> Function(RatItem item, int level) onBuy;

  @override
  Widget build(BuildContext context) {
    final loadout = inventory.loadoutForLevel(level);
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
              '${inventory.credits}',
              style: const TextStyle(
                color: GymRatColors.gold,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
          child: GymRatCharacter(
            height: 285,
            level: level,
            gender: gender,
            loadout: loadout,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr.t('ratItemsHelp'),
          style: const TextStyle(color: GymRatColors.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 10),
        for (final item in RatItemCatalog.items) ...[
          _RatItemCard(
            item: item,
            level: level,
            owned: inventory.owns(item, level),
            equipped: loadout[item.slot]?.id == item.id,
            onEquip: () => onEquip(item, level),
            onBuy: () => onBuy(item, level),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _RatItemCard extends StatelessWidget {
  const _RatItemCard({
    required this.item,
    required this.level,
    required this.owned,
    required this.equipped,
    required this.onEquip,
    required this.onBuy,
  });

  final RatItem item;
  final int level;
  final bool owned;
  final bool equipped;
  final VoidCallback onEquip;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(
        color: equipped
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
            color: (equipped ? GymRatColors.gold : GymRatColors.green)
                .withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
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
                    : '${item.priceCredits} ${context.tr.t('armoryCredits')}',
                style: const TextStyle(
                  color: GymRatColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (equipped)
          Text(
            context.tr.t('equipped'),
            style: const TextStyle(
              color: GymRatColors.gold,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          )
        else if (owned)
          TextButton(onPressed: onEquip, child: Text(context.tr.t('equip')))
        else if (item.priceCredits != null)
          FilledButton(
            onPressed: onBuy,
            style: FilledButton.styleFrom(
              backgroundColor: GymRatColors.gold,
              foregroundColor: GymRatColors.black,
              visualDensity: VisualDensity.compact,
            ),
            child: Text('${item.priceCredits}'),
          )
        else
          const Icon(Icons.lock_rounded, color: GymRatColors.textMuted),
      ],
    ),
  );
}

IconData _ratItemIcon(RatItemSlot slot) => switch (slot) {
  RatItemSlot.head => Icons.sports_martial_arts_rounded,
  RatItemSlot.neck => Icons.link_rounded,
  RatItemSlot.belt => Icons.shield_rounded,
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
  Widget build(BuildContext context) => RefreshIndicator(
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
        if (store.status == ArmoryStoreStatus.ready)
          for (final offer in store.offers) ...[
            _OfferCard(
              offer: offer,
              busy: busyOffer == offer.identifier,
              onPurchase: () => onPurchase(offer),
            ),
            const SizedBox(height: 10),
          ]
        else
          _StoreState(status: store.status),
      ],
    ),
  );
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

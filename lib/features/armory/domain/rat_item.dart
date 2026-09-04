enum RatItemSlot { head, neck, top, bottom, feet, belt, collectible, aura }

class RatItem {
  const RatItem({
    required this.id,
    required this.nameKey,
    required this.slot,
    this.unlockLevel,
    this.priceCredits,
    this.storeProductId,
    this.previewAssetPath,
    this.appearanceId,
  }) : assert(
         unlockLevel != null || priceCredits != null || storeProductId != null,
       );

  final String id;
  final String nameKey;
  final RatItemSlot slot;
  final int? unlockLevel;
  final int? priceCredits;
  final String? storeProductId;
  final String? previewAssetPath;
  final String? appearanceId;

  bool isLevelUnlocked(int level) =>
      unlockLevel != null && level >= unlockLevel!;

  bool get hasCompleteAppearance => appearanceId != null;
  bool get isConcept =>
      slot != RatItemSlot.collectible && !hasCompleteAppearance;
}

abstract final class RatItemCatalog {
  static final rankRewards = List<RatItem>.unmodifiable(
    List.generate(
      49,
      (index) => RatItem(
        id: 'rank_mark_${index + 2}',
        nameKey: 'itemRankMark',
        slot: RatItemSlot.collectible,
        unlockLevel: index + 2,
      ),
    ),
  );

  static const featuredItems = <RatItem>[
    RatItem(
      id: 'rookie_headband',
      nameKey: 'itemRookieHeadband',
      slot: RatItemSlot.head,
      unlockLevel: 2,
    ),
    RatItem(
      id: 'iron_tags',
      nameKey: 'itemIronTags',
      slot: RatItemSlot.neck,
      unlockLevel: 5,
    ),
    RatItem(
      id: 'emerald_belt',
      nameKey: 'itemEmeraldBelt',
      slot: RatItemSlot.belt,
      unlockLevel: 10,
    ),
    RatItem(
      id: 'war_crown',
      nameKey: 'itemWarCrown',
      slot: RatItemSlot.head,
      unlockLevel: 15,
    ),
    RatItem(
      id: 'power_aura',
      nameKey: 'itemPowerAura',
      slot: RatItemSlot.aura,
      unlockLevel: 20,
    ),
    RatItem(
      id: 'gold_chain',
      nameKey: 'itemGoldChain',
      slot: RatItemSlot.neck,
      unlockLevel: 30,
    ),
    RatItem(
      id: 'champion_belt',
      nameKey: 'itemChampionBelt',
      slot: RatItemSlot.belt,
      unlockLevel: 40,
    ),
    RatItem(
      id: 'olympia_aura',
      nameKey: 'itemOlympiaAura',
      slot: RatItemSlot.aura,
      unlockLevel: 50,
    ),
    RatItem(
      id: 'shadow_hood',
      nameKey: 'itemShadowHood',
      slot: RatItemSlot.head,
      priceCredits: 60,
    ),
    RatItem(
      id: 'violet_chain',
      nameKey: 'itemVioletChain',
      slot: RatItemSlot.neck,
      priceCredits: 100,
    ),
    RatItem(
      id: 'molten_belt',
      nameKey: 'itemMoltenBelt',
      slot: RatItemSlot.belt,
      priceCredits: 140,
    ),
    RatItem(
      id: 'void_aura',
      nameKey: 'itemVoidAura',
      slot: RatItemSlot.aura,
      priceCredits: 180,
    ),
    RatItem(
      id: 'graphite_cap',
      nameKey: 'itemGraphiteCap',
      slot: RatItemSlot.head,
      priceCredits: 80,
      storeProductId: 'gymrat.graphite_cap',
      previewAssetPath: 'assets/items/graphite_cap.png',
    ),
    RatItem(
      id: 'iron_chain',
      nameKey: 'itemIronChain',
      slot: RatItemSlot.neck,
      priceCredits: 100,
      storeProductId: 'gymrat.iron_chain',
      previewAssetPath: 'assets/items/iron_chain.png',
    ),
    RatItem(
      id: 'founders_tee',
      nameKey: 'itemFoundersTee',
      slot: RatItemSlot.top,
      priceCredits: 125,
      storeProductId: 'gymrat.founders_tee',
      previewAssetPath: 'assets/items/founders_tee.png',
    ),
    RatItem(
      id: 'champion_joggers',
      nameKey: 'itemChampionJoggers',
      slot: RatItemSlot.bottom,
      priceCredits: 145,
      storeProductId: 'gymrat.champion_joggers',
      previewAssetPath: 'assets/items/champion_joggers.png',
    ),
    RatItem(
      id: 'arena_shorts',
      nameKey: 'itemArenaShorts',
      slot: RatItemSlot.bottom,
      priceCredits: 110,
      storeProductId: 'gymrat.arena_shorts',
      previewAssetPath: 'assets/items/arena_shorts.png',
    ),
    RatItem(
      id: 'neon_trainers',
      nameKey: 'itemNeonTrainers',
      slot: RatItemSlot.feet,
      priceCredits: 135,
      storeProductId: 'gymrat.neon_trainers',
      previewAssetPath: 'assets/items/neon_trainers.png',
    ),
  ];

  static final items = List<RatItem>.unmodifiable([
    ...rankRewards,
    ...featuredItems,
  ]);

  static RatItem? forLevel(int level) {
    RatItem? rank;
    for (final item in items) {
      if (item.unlockLevel != level) continue;
      if (item.slot == RatItemSlot.collectible) {
        rank = item;
      } else if (item.hasCompleteAppearance) {
        return item;
      }
    }
    return rank;
  }

  static List<RatItem> itemsForLevel(int level) =>
      List.unmodifiable(items.where((item) => item.unlockLevel == level));

  static RatItem? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static RatItem? byStoreProductId(String id) {
    for (final item in items) {
      if (item.storeProductId == id) return item;
    }
    return null;
  }
}

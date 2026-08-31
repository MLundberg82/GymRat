enum RatItemSlot { head, neck, belt, aura }

class RatItem {
  const RatItem({
    required this.id,
    required this.nameKey,
    required this.slot,
    this.unlockLevel,
    this.priceCredits,
  }) : assert(unlockLevel != null || priceCredits != null);

  final String id;
  final String nameKey;
  final RatItemSlot slot;
  final int? unlockLevel;
  final int? priceCredits;

  bool isLevelUnlocked(int level) =>
      unlockLevel != null && level >= unlockLevel!;
}

abstract final class RatItemCatalog {
  static const items = <RatItem>[
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
  ];

  static RatItem? forLevel(int level) {
    for (final item in items) {
      if (item.unlockLevel == level) return item;
    }
    return null;
  }

  static RatItem? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}

class RatLoadout {
  const RatLoadout(this.items);

  final Map<RatItemSlot, RatItem> items;

  RatItem? operator [](RatItemSlot slot) => items[slot];
}

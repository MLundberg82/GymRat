enum GymUpgradeType {
  dumbbellRack,
  neonLights,
  weightPlates,
  powerRack,
  banner,
  spotlights,
  speakers,
  championPlaque,
}

class GymUpgrade {
  const GymUpgrade({
    required this.level,
    required this.type,
    required this.tier,
    required this.nameKey,
  });
  final int level, tier;
  final GymUpgradeType type;
  final String nameKey;
}

abstract final class GymUpgradeCatalog {
  static const _types = GymUpgradeType.values;
  static const _keys = <GymUpgradeType, String>{
    GymUpgradeType.dumbbellRack: 'upgradeDumbbellRack',
    GymUpgradeType.neonLights: 'upgradeNeonLights',
    GymUpgradeType.weightPlates: 'upgradeWeightPlates',
    GymUpgradeType.powerRack: 'upgradePowerRack',
    GymUpgradeType.banner: 'upgradeBanner',
    GymUpgradeType.spotlights: 'upgradeSpotlights',
    GymUpgradeType.speakers: 'upgradeSpeakers',
    GymUpgradeType.championPlaque: 'upgradeChampionPlaque',
  };
  static GymUpgrade forLevel(int level) {
    final safe = level < 2 ? 2 : level;
    final index = safe - 2;
    final type = _types[index % _types.length];
    return GymUpgrade(
      level: safe,
      type: type,
      tier: (index ~/ _types.length) + 1,
      nameKey: _keys[type]!,
    );
  }

  static Map<GymUpgradeType, int> tiersAtLevel(int level) {
    final tiers = <GymUpgradeType, int>{};
    for (var unlockedLevel = 2; unlockedLevel <= level; unlockedLevel++) {
      final upgrade = forLevel(unlockedLevel);
      tiers[upgrade.type] = upgrade.tier;
    }
    return tiers;
  }
}

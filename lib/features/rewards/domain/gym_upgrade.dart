enum GymUpgradeType {
  dumbbellRack,
  neonLights,
  weightPlates,
  powerRack,
  liftingPlatform,
  banner,
  spotlights,
  speakers,
  championPlaque,
  cardio,
  recovery,
  strongman,
  architecture,
}

class GymUpgrade {
  const GymUpgrade({
    required this.level,
    required this.type,
    required this.tier,
    required this.nameKey,
  });

  final int level;
  final int tier;
  final GymUpgradeType type;
  final String nameKey;
}

class _GymUpgradeDefinition {
  const _GymUpgradeDefinition(this.type, this.nameKey);

  final GymUpgradeType type;
  final String nameKey;
}

abstract final class GymUpgradeCatalog {
  static const _definitions = <_GymUpgradeDefinition>[
    _GymUpgradeDefinition(GymUpgradeType.weightPlates, 'upgradeWeightPlates'),
    _GymUpgradeDefinition(GymUpgradeType.neonLights, 'upgradeNeonLights'),
    _GymUpgradeDefinition(
      GymUpgradeType.liftingPlatform,
      'upgradeLiftingPlatform',
    ),
    _GymUpgradeDefinition(GymUpgradeType.banner, 'upgradeBanner'),
    _GymUpgradeDefinition(GymUpgradeType.spotlights, 'upgradeSpotlights'),
    _GymUpgradeDefinition(GymUpgradeType.speakers, 'upgradeSpeakers'),
    _GymUpgradeDefinition(
      GymUpgradeType.championPlaque,
      'upgradeChampionPlaque',
    ),
    _GymUpgradeDefinition(GymUpgradeType.dumbbellRack, 'upgradeDumbbellRack'),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeCableTowers'),
    _GymUpgradeDefinition(GymUpgradeType.weightPlates, 'upgradeKettlebellRack'),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeChalkStation'),
    _GymUpgradeDefinition(GymUpgradeType.strongman, 'upgradeBattleRopes'),
    _GymUpgradeDefinition(GymUpgradeType.liftingPlatform, 'upgradePlyoBoxes'),
    _GymUpgradeDefinition(GymUpgradeType.architecture, 'upgradeWallArmor'),
    _GymUpgradeDefinition(GymUpgradeType.cardio, 'upgradeAirBike'),
    _GymUpgradeDefinition(GymUpgradeType.cardio, 'upgradeRower'),
    _GymUpgradeDefinition(GymUpgradeType.strongman, 'upgradeProwlerSled'),
    _GymUpgradeDefinition(GymUpgradeType.strongman, 'upgradeClimbingRopes'),
    _GymUpgradeDefinition(GymUpgradeType.spotlights, 'upgradeLightingTruss'),
    _GymUpgradeDefinition(GymUpgradeType.championPlaque, 'upgradeTrophyCase'),
    _GymUpgradeDefinition(GymUpgradeType.strongman, 'upgradePunchingBag'),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeLegPress'),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeGluteHam'),
    _GymUpgradeDefinition(
      GymUpgradeType.architecture,
      'upgradeLightningInsignia',
    ),
    _GymUpgradeDefinition(
      GymUpgradeType.weightPlates,
      'upgradeMedicineBallRack',
    ),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeResistanceStation'),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeLandmineStation'),
    _GymUpgradeDefinition(GymUpgradeType.recovery, 'upgradeRecoveryFan'),
    _GymUpgradeDefinition(
      GymUpgradeType.liftingPlatform,
      'upgradeCompetitionPlatform',
    ),
    _GymUpgradeDefinition(GymUpgradeType.cardio, 'upgradeCurvedTreadmill'),
    _GymUpgradeDefinition(GymUpgradeType.cardio, 'upgradeSkiErg'),
    _GymUpgradeDefinition(GymUpgradeType.strongman, 'upgradeChainStorage'),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeSpecialtyBars'),
    _GymUpgradeDefinition(
      GymUpgradeType.architecture,
      'upgradeChampionColumns',
    ),
    _GymUpgradeDefinition(GymUpgradeType.strongman, 'upgradeAtlasStones'),
    _GymUpgradeDefinition(GymUpgradeType.strongman, 'upgradeFarmerHandles'),
    _GymUpgradeDefinition(GymUpgradeType.strongman, 'upgradeYoke'),
    _GymUpgradeDefinition(GymUpgradeType.recovery, 'upgradeDustExtraction'),
    _GymUpgradeDefinition(
      GymUpgradeType.championPlaque,
      'upgradeChampionDisplay',
    ),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeDipStation'),
    _GymUpgradeDefinition(GymUpgradeType.recovery, 'upgradeReverseHyper'),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeLegExtension'),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeCalfRaise'),
    _GymUpgradeDefinition(GymUpgradeType.spotlights, 'upgradePrestigeLighting'),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeMonolift'),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeCompetitionBench'),
    _GymUpgradeDefinition(GymUpgradeType.powerRack, 'upgradeDeadliftStation'),
    _GymUpgradeDefinition(GymUpgradeType.recovery, 'upgradeRecoveryStation'),
    _GymUpgradeDefinition(GymUpgradeType.architecture, 'upgradeVictoryArch'),
  ];

  static GymUpgrade forLevel(int level) {
    final safeLevel = level.clamp(2, 50).toInt();
    final definition = _definitions[safeLevel - 2];
    return GymUpgrade(
      level: safeLevel,
      type: definition.type,
      tier: 1,
      nameKey: definition.nameKey,
    );
  }

  static List<GymUpgrade> get all =>
      List.unmodifiable(List.generate(49, (index) => forLevel(index + 2)));

  static Map<GymUpgradeType, int> tiersAtLevel(int level) {
    final tiers = <GymUpgradeType, int>{};
    final safeLevel = level.clamp(1, 50).toInt();
    for (var unlockedLevel = 2; unlockedLevel <= safeLevel; unlockedLevel++) {
      final type = forLevel(unlockedLevel).type;
      tiers[type] = (tiers[type] ?? 0) + 1;
    }
    return tiers;
  }
}

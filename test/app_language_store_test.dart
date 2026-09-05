import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/core/localization/app_language_store.dart';
import 'package:gymrat/core/localization/gymrat_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppLanguageStore.locale.value = null;
  });

  tearDown(() {
    AppLanguageStore.locale.value = null;
  });

  test('uses the system language by default', () async {
    await AppLanguageStore.initialize();

    expect(AppLanguageStore.locale.value, isNull);
    expect(AppLanguageStore.currentCode(), 'system');
  });

  test('persists and restores an explicit language', () async {
    await AppLanguageStore.setLanguage('sv');
    expect(AppLanguageStore.locale.value, const Locale('sv'));

    AppLanguageStore.locale.value = null;
    await AppLanguageStore.initialize();

    expect(AppLanguageStore.locale.value, const Locale('sv'));
    expect(AppLanguageStore.currentCode(), 'sv');
  });

  test('restores system language after clearing an override', () async {
    await AppLanguageStore.setLanguage('sv');
    await AppLanguageStore.setLanguage('system');

    AppLanguageStore.locale.value = const Locale('en');
    await AppLanguageStore.initialize();

    expect(AppLanguageStore.locale.value, isNull);
    expect(AppLanguageStore.currentCode(), 'system');
  });

  test('feature copy exists in every supported language', () {
    const keys = <String>[
      'trainingHistory',
      'combatLog',
      'records',
      'trainingArchive',
      'emptyHistoryTitle',
      'workoutDetails',
      'exerciseBreakdown',
      'recordVault',
      'recordsUnlocked',
      'noRecordsTitle',
      'baseline',
      'previousBest',
      'totalGain',
      'recordBreaks',
      'historyLoadError',
      'armoryTitle',
      'armoryCollection',
      'armoryStore',
      'armoryVaultTitle',
      'restorePurchases',
      'armoryOwned',
      'questBoardTitle',
      'dailyContracts',
      'weeklyCampaign',
      'questDailySession',
      'questWeeklyDuration',
      'onboardingTitle',
      'genderFemale',
      'genderNonBinary',
      'authoredBreathing',
      'experienceExpert',
      'goalBuildMuscle',
      'ratLoadout',
      'armoryCredits',
      'itemOlympiaAura',
      'claimReward',
      'premiumCoach',
      'workoutChest',
      'workoutBack',
      'workoutLegs',
      'workoutArms',
      'workoutWalk',
      'workoutChestSubtitle',
      'workoutBackSubtitle',
      'workoutLegsSubtitle',
      'workoutArmsSubtitle',
      'workoutWalkSubtitle',
      'exerciseBenchPress',
      'exerciseInclineDumbbellPress',
      'exerciseChestFly',
      'exerciseCablePress',
      'exerciseLatPulldown',
      'exerciseBarbellRow',
      'exerciseSeatedCableRow',
      'exerciseFacePull',
      'exerciseSquat',
      'exerciseLegPress',
      'exerciseRomanianDeadlift',
      'exerciseLegCurl',
      'exerciseBarbellCurl',
      'exerciseHammerCurl',
      'exerciseTricepPushdown',
      'exerciseOverheadExtension',
      'coachNextMission',
      'coachWeeklyTargetReachedReason',
      'coachLaunchMission',
      'coachMissionLabel',
      'coachRecoveryMissionHelp',
      'coachTargetLabel',
      'coachLoadError',
      'tryAgain',
      'coachMissionsRemaining',
      'coachCampaignComplete',
      'coachRecoveryWindow',
      'coachFreshRoute',
      'coachDaySuffix',
      'coachBaseline',
      'coachVolumeHelp',
      'coachRotationTitle',
      'coachRotationHelp',
      'evolutionRoadmap',
      'finalEvolutionReached',
      'olympiaFormComplete',
      'untilEvolution',
      'nextEvolutionReward',
      'frontView',
      'backView',
      'changeRatIdentity',
      'levelRewards',
      'itemFoundersTee',
      'itemConcept',
      'appearanceInForge',
      'appearanceInForgeMessage',
      'appearancePurchaseBlocked',
      'premiumBlueprint',
      'premiumBenefitHistory',
      'contactSupport',
      'supportTitle',
      'characterLab',
      'characterLabHelp',
      'approvedAssetStage',
      'scalePreview',
      'assetPending',
      'authoredMotion',
      'safeMotionFallback',
      'weeklyShort',
      'armoryFitForge',
      'armoryFitForgeHelp',
      'fitMatrixPending',
      'workoutWeightUnit',
      'sessionJournal',
      'effortRating',
      'sessionNote',
      'trainingLoad',
      'readinessRecover',
      'coachEffortRecoveryReason',
      'achievementVault',
      'achievementFirstSession',
      'achievementFiveRecords',
      'achievementFirstEvolution',
      'nutritionTitle',
      'nutritionCommandCenter',
      'calories',
      'protein',
      'carbohydrates',
      'fat',
      'logMeal',
      'sevenDayNutrition',
      'nutritionSafetyNote',
      'premiumXpBoost',
      'premiumBenefitNutrition',
      'premiumPaywallTitle',
      'notNow',
      'localPremiumAccess',
      'monthlyPlan',
      'yearlyPlan',
      'twoMonthsFree',
    ];

    for (final locale in AppLanguageStore.supported) {
      final translations = GymRatLocalizations(locale);
      for (final key in keys) {
        expect(
          translations.t(key),
          isNot(key),
          reason: '$key is missing for ${locale.languageCode}',
        );
      }
    }
  });
}

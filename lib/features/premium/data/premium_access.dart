import '../../armory/data/armory_billing.dart';
import '../../workout/data/workout_session_store.dart';

abstract final class PremiumAccess {
  static const entitlementId = 'premium';
  static const freeHistoryLimit = 10;

  static Future<bool> isActive() =>
      ArmoryBilling.hasActiveEntitlement(entitlementId);

  static bool get current =>
      ArmoryBilling.activeEntitlements.value.contains(entitlementId);

  static TrainingHistorySnapshot visibleHistory(
    TrainingHistorySnapshot history, {
    required bool isPremium,
  }) {
    if (isPremium || history.workouts.length <= freeHistoryLimit) {
      return history;
    }
    return TrainingHistorySnapshot(
      workouts: List.unmodifiable(history.workouts.take(freeHistoryLimit)),
      personalBests: history.personalBests,
    );
  }
}

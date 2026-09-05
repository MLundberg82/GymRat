import '../../armory/data/armory_billing.dart';
import '../../workout/data/workout_session_store.dart';
import '../domain/premium_products.dart';
import 'premium_local_access.dart';

abstract final class PremiumAccess {
  static const entitlementId = 'premium';
  static const monthlyProductId = PremiumProducts.monthly;
  static const yearlyProductId = PremiumProducts.yearly;
  static const freeHistoryLimit = 10;
  static const xpBoostPercent = 10;

  static bool isSubscriptionProduct(String productId) =>
      PremiumProducts.contains(productId);

  static Future<bool> isActive() async =>
      PremiumLocalAccess.active.value ||
      await ArmoryBilling.hasActiveEntitlement(entitlementId);

  static bool get current =>
      PremiumLocalAccess.active.value ||
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

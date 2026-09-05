abstract final class PremiumProducts {
  static const monthly = 'gymrat_premium_monthly';
  static const yearly = 'gymrat_premium_yearly';

  static bool contains(String productId) =>
      productId == monthly || productId == yearly;
}

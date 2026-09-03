import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

enum ArmoryStoreStatus { notConfigured, ready, empty, unavailable }

enum ArmoryPurchaseStatus { purchased, cancelled, failed }

class ArmoryOffer {
  const ArmoryOffer({
    required this.identifier,
    required this.title,
    required this.description,
    required this.price,
    required this.isOwned,
    required this.package,
  });

  final String identifier;
  final String title;
  final String description;
  final String price;
  final bool isOwned;
  final Package package;
}

class ArmoryStoreSnapshot {
  const ArmoryStoreSnapshot({required this.status, this.offers = const []});

  final ArmoryStoreStatus status;
  final List<ArmoryOffer> offers;
}

abstract final class ArmoryBilling {
  static const _appleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_API_KEY',
  );
  static const _googleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_API_KEY',
  );

  static bool _configured = false;
  static bool _listenerRegistered = false;
  static final ValueNotifier<Set<String>> activeEntitlements =
      ValueNotifier<Set<String>>(<String>{});
  static final ValueNotifier<Set<String>> purchasedProductIds =
      ValueNotifier<Set<String>>(<String>{});

  static bool get isConfigured => _configured;

  static Future<void> initialize() async {
    if (_configured || kIsWeb) return;
    final apiKey = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => _appleApiKey,
      TargetPlatform.android => _googleApiKey,
      _ => '',
    };
    if (apiKey.isEmpty) return;

    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;
      if (!_listenerRegistered) {
        Purchases.addCustomerInfoUpdateListener(_applyCustomerInfo);
        _listenerRegistered = true;
      }
      _applyCustomerInfo(await Purchases.getCustomerInfo());
    } catch (_) {
      // Billing must never prevent the workout app from starting.
    }
  }

  static Future<ArmoryStoreSnapshot> loadStore() async {
    if (!_configured) {
      return const ArmoryStoreSnapshot(status: ArmoryStoreStatus.notConfigured);
    }
    try {
      final results = await Future.wait<Object>([
        Purchases.getOfferings(),
        Purchases.getCustomerInfo(),
      ]);
      final offering = (results[0] as Offerings).current;
      final customerInfo = results[1] as CustomerInfo;
      _applyCustomerInfo(customerInfo);
      if (offering == null || offering.availablePackages.isEmpty) {
        return const ArmoryStoreSnapshot(status: ArmoryStoreStatus.empty);
      }
      final ownedProductIds = customerInfo.allPurchasedProductIdentifiers
          .toSet();
      final offers = offering.availablePackages
          .map((package) {
            final product = package.storeProduct;
            return ArmoryOffer(
              identifier: product.identifier,
              title: product.title,
              description: product.description,
              price: product.priceString,
              isOwned: ownedProductIds.contains(product.identifier),
              package: package,
            );
          })
          .toList(growable: false);
      return ArmoryStoreSnapshot(
        status: ArmoryStoreStatus.ready,
        offers: offers,
      );
    } catch (_) {
      return const ArmoryStoreSnapshot(status: ArmoryStoreStatus.unavailable);
    }
  }

  static Future<ArmoryPurchaseStatus> purchase(ArmoryOffer offer) async {
    if (!_configured) return ArmoryPurchaseStatus.failed;
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(offer.package),
      );
      _applyCustomerInfo(result.customerInfo);
      return ArmoryPurchaseStatus.purchased;
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      return code == PurchasesErrorCode.purchaseCancelledError
          ? ArmoryPurchaseStatus.cancelled
          : ArmoryPurchaseStatus.failed;
    } catch (_) {
      return ArmoryPurchaseStatus.failed;
    }
  }

  static Future<bool> restore() async {
    if (!_configured) return false;
    try {
      _applyCustomerInfo(await Purchases.restorePurchases());
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasActiveEntitlement(String identifier) async {
    if (!_configured) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      _applyCustomerInfo(info);
      return info.entitlements.active[identifier]?.isActive ?? false;
    } catch (_) {
      return false;
    }
  }

  static void _applyCustomerInfo(CustomerInfo info) {
    final nextEntitlements = Set<String>.unmodifiable(
      info.entitlements.active.entries
          .where((entry) => entry.value.isActive)
          .map((entry) => entry.key),
    );
    final nextProducts = Set<String>.unmodifiable(
      info.allPurchasedProductIdentifiers,
    );
    if (!_setsEqual(activeEntitlements.value, nextEntitlements)) {
      activeEntitlements.value = nextEntitlements;
    }
    if (!_setsEqual(purchasedProductIds.value, nextProducts)) {
      purchasedProductIds.value = nextProducts;
    }
  }

  static bool _setsEqual(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);
}

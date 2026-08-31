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
      if (offering == null || offering.availablePackages.isEmpty) {
        return const ArmoryStoreSnapshot(status: ArmoryStoreStatus.empty);
      }
      final activeProductIds = (results[1] as CustomerInfo)
          .entitlements
          .active
          .values
          .map((entitlement) => entitlement.productIdentifier)
          .toSet();
      final offers = offering.availablePackages
          .map((package) {
            final product = package.storeProduct;
            return ArmoryOffer(
              identifier: product.identifier,
              title: product.title,
              description: product.description,
              price: product.priceString,
              isOwned: activeProductIds.contains(product.identifier),
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
      await Purchases.purchase(PurchaseParams.package(offer.package));
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
      await Purchases.restorePurchases();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasActiveEntitlement(String identifier) async {
    if (!_configured) return false;
    try {
      return (await Purchases.getCustomerInfo())
              .entitlements
              .active[identifier]
              ?.isActive ??
          false;
    } catch (_) {
      return false;
    }
  }
}

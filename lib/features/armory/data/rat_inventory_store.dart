import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../character/domain/rat_appearance.dart';
import '../domain/rat_item.dart';

enum RatItemPurchaseResult {
  purchased,
  insufficientCredits,
  alreadyOwned,
  appearanceUnavailable,
}

class RatInventoryState {
  const RatInventoryState({
    this.credits = 0,
    this.claimedQuests = const <String>{},
    this.ownedItems = const <String>{},
    this.equippedAppearanceId = RatAppearanceCatalog.baseId,
  });

  final int credits;
  final Set<String> claimedQuests;
  final Set<String> ownedItems;
  final String equippedAppearanceId;

  bool owns(RatItem item, int level) =>
      item.isLevelUnlocked(level) || ownedItems.contains(item.id);
}

abstract final class RatInventoryStore {
  static const _stateKey = 'gymrat-rat-inventory-v1';

  static Future<RatInventoryState> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_stateKey);
    if (raw == null) return const RatInventoryState();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const RatInventoryState();
      final json = Map<String, dynamic>.from(decoded);
      final storedAppearance = json['equippedAppearanceId'];
      final appearanceId =
          storedAppearance is String &&
              RatAppearanceCatalog.isReady(storedAppearance)
          ? storedAppearance
          : RatAppearanceCatalog.baseId;
      return RatInventoryState(
        credits: (json['credits'] as num?)?.toInt().clamp(0, 1000000) ?? 0,
        claimedQuests: _strings(json['claimedQuests']),
        ownedItems: _strings(json['ownedItems'])
            .where((id) => RatItemCatalog.byId(id) != null)
            .toSet(),
        equippedAppearanceId: appearanceId,
      );
    } catch (_) {
      return const RatInventoryState();
    }
  }

  static Future<bool> claimQuest(String claimId, int reward) async {
    final state = await load();
    if (state.claimedQuests.contains(claimId) || reward <= 0) return false;
    await _save(
      RatInventoryState(
        credits: state.credits + reward,
        claimedQuests: {...state.claimedQuests, claimId},
        ownedItems: state.ownedItems,
        equippedAppearanceId: state.equippedAppearanceId,
      ),
    );
    return true;
  }

  static Future<RatItemPurchaseResult> purchase(
    RatItem item, {
    required int level,
  }) async {
    if (!item.hasCompleteAppearance ||
        !RatAppearanceCatalog.isReady(item.appearanceId)) {
      return RatItemPurchaseResult.appearanceUnavailable;
    }
    final state = await load();
    if (state.owns(item, level)) return RatItemPurchaseResult.alreadyOwned;
    final price = item.priceCredits ?? 0;
    if (state.credits < price) {
      return RatItemPurchaseResult.insufficientCredits;
    }
    await _save(
      RatInventoryState(
        credits: state.credits - price,
        claimedQuests: state.claimedQuests,
        ownedItems: {...state.ownedItems, item.id},
        equippedAppearanceId: item.appearanceId!,
      ),
    );
    return RatItemPurchaseResult.purchased;
  }

  static Future<void> equipAppearance(
    String appearanceId, {
    required int level,
  }) async {
    if (!RatAppearanceCatalog.isReady(appearanceId)) return;
    final state = await load();
    final appearance = RatAppearanceCatalog.byId(appearanceId);
    final item = RatItemCatalog.items
        .where((candidate) => candidate.appearanceId == appearance.id)
        .firstOrNull;
    if (item != null && !state.owns(item, level)) return;
    await _save(
      RatInventoryState(
        credits: state.credits,
        claimedQuests: state.claimedQuests,
        ownedItems: state.ownedItems,
        equippedAppearanceId: appearance.id,
      ),
    );
  }

  static Future<void> grantPurchased(RatItem item) async {
    if (!item.hasCompleteAppearance ||
        !RatAppearanceCatalog.isReady(item.appearanceId)) {
      return;
    }
    final state = await load();
    await _save(
      RatInventoryState(
        credits: state.credits,
        claimedQuests: state.claimedQuests,
        ownedItems: {...state.ownedItems, item.id},
        equippedAppearanceId: item.appearanceId!,
      ),
    );
  }

  static Future<void> _save(RatInventoryState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _stateKey,
      jsonEncode(<String, Object>{
        'version': 2,
        'credits': state.credits,
        'claimedQuests': state.claimedQuests.toList(),
        'ownedItems': state.ownedItems.toList(),
        'equippedAppearanceId': state.equippedAppearanceId,
      }),
    );
  }

  static Set<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toSet() : const <String>{};
}

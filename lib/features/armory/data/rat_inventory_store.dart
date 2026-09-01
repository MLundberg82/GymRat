import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/rat_item.dart';

enum RatItemPurchaseResult { purchased, insufficientCredits, alreadyOwned }

class RatInventoryState {
  const RatInventoryState({
    this.credits = 0,
    this.claimedQuests = const <String>{},
    this.ownedItems = const <String>{},
    this.equipped = const <RatItemSlot, String>{},
  });

  final int credits;
  final Set<String> claimedQuests;
  final Set<String> ownedItems;
  final Map<RatItemSlot, String> equipped;

  bool owns(RatItem item, int level) =>
      item.isLevelUnlocked(level) || ownedItems.contains(item.id);

  RatLoadout loadoutForLevel(int level) {
    final result = <RatItemSlot, RatItem>{};
    for (final slot in RatItemSlot.values) {
      if (slot == RatItemSlot.collectible) continue;
      final selected = RatItemCatalog.byId(equipped[slot] ?? '');
      if (selected != null && owns(selected, level)) {
        result[slot] = selected;
        continue;
      }
      final levelItems = RatItemCatalog.items
          .where((item) => item.slot == slot && item.isLevelUnlocked(level))
          .toList();
      if (levelItems.isNotEmpty) result[slot] = levelItems.last;
    }
    return RatLoadout(Map.unmodifiable(result));
  }
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
      final equipped = <RatItemSlot, String>{};
      final rawEquipped = json['equipped'];
      if (rawEquipped is Map) {
        for (final slot in RatItemSlot.values) {
          final value = rawEquipped[slot.name];
          if (value is String && RatItemCatalog.byId(value) != null) {
            equipped[slot] = value;
          }
        }
      }
      return RatInventoryState(
        credits: (json['credits'] as num?)?.toInt().clamp(0, 1000000) ?? 0,
        claimedQuests: _strings(json['claimedQuests']),
        ownedItems: _strings(json['ownedItems'])
            .where((id) => RatItemCatalog.byId(id) != null)
            .toSet(),
        equipped: Map.unmodifiable(equipped),
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
        equipped: state.equipped,
      ),
    );
    return true;
  }

  static Future<RatItemPurchaseResult> purchase(
    RatItem item, {
    required int level,
  }) async {
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
        equipped: item.isWearable
            ? {...state.equipped, item.slot: item.id}
            : state.equipped,
      ),
    );
    return RatItemPurchaseResult.purchased;
  }

  static Future<void> equip(RatItem item, {required int level}) async {
    if (!item.isWearable) return;
    final state = await load();
    if (!state.owns(item, level)) return;
    await _save(
      RatInventoryState(
        credits: state.credits,
        claimedQuests: state.claimedQuests,
        ownedItems: state.ownedItems,
        equipped: {...state.equipped, item.slot: item.id},
      ),
    );
  }

  static Future<void> grantPurchased(RatItem item) async {
    final state = await load();
    await _save(
      RatInventoryState(
        credits: state.credits,
        claimedQuests: state.claimedQuests,
        ownedItems: {...state.ownedItems, item.id},
        equipped: item.isWearable
            ? {...state.equipped, item.slot: item.id}
            : state.equipped,
      ),
    );
  }

  static Future<void> _save(RatInventoryState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _stateKey,
      jsonEncode(<String, Object>{
        'version': 1,
        'credits': state.credits,
        'claimedQuests': state.claimedQuests.toList(),
        'ownedItems': state.ownedItems.toList(),
        'equipped': state.equipped.map(
          (slot, itemId) => MapEntry(slot.name, itemId),
        ),
      }),
    );
  }

  static Set<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toSet() : const <String>{};
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/nutrition_models.dart';

abstract final class NutritionStore {
  static const _entriesKey = 'gymrat-nutrition-entries-v1';
  static const _maximumEntries = 5000;

  static Future<List<NutritionEntry>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_entriesKey);
    if (raw == null) return const <NutritionEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <NutritionEntry>[];
      final entries = <NutritionEntry>[];
      for (final value in decoded) {
        if (value is! Map) continue;
        final entry = NutritionEntry.tryParse(Map<String, dynamic>.from(value));
        if (entry != null) entries.add(entry);
      }
      entries.sort((left, right) => right.loggedAt.compareTo(left.loggedAt));
      return List<NutritionEntry>.unmodifiable(entries);
    } catch (_) {
      return const <NutritionEntry>[];
    }
  }

  static Future<NutritionEntry> add({
    required String name,
    required int calories,
    required double proteinGrams,
    required double carbohydrateGrams,
    required double fatGrams,
    DateTime? loggedAt,
  }) async {
    final timestamp = loggedAt ?? DateTime.now();
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Meal name cannot be empty.');
    }
    final entry = NutritionEntry(
      id: 'nutrition-${timestamp.microsecondsSinceEpoch}',
      name: cleanName.length > 80 ? cleanName.substring(0, 80) : cleanName,
      loggedAt: timestamp,
      calories: calories.clamp(0, 10000),
      proteinGrams: proteinGrams.clamp(0, 1000),
      carbohydrateGrams: carbohydrateGrams.clamp(0, 2000),
      fatGrams: fatGrams.clamp(0, 1000),
    );
    final entries = <NutritionEntry>[entry, ...await load()];
    await _save(entries.take(_maximumEntries));
    return entry;
  }

  static Future<void> delete(String id) async {
    final entries = await load();
    await _save(entries.where((entry) => entry.id != id));
  }

  static Future<void> _save(Iterable<NutritionEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _entriesKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}

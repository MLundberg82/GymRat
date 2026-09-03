import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/workout_draft.dart';

abstract final class WorkoutDraftStore {
  static const _draftKey = 'gymrat-active-workout-draft-v1';

  static Future<void> save(WorkoutDraft draft) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  static Future<WorkoutDraft?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_draftKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return WorkoutDraft.tryParse(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<WorkoutDraft?> loadForPreset(String presetId) async {
    final draft = await load();
    return draft?.presetId == presetId ? draft : null;
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_draftKey);
  }
}

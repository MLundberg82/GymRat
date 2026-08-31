import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/training_profile.dart';

abstract final class TrainingProfileStore {
  static const _profileKey = 'gymrat-training-profile';

  static final ValueNotifier<TrainingProfile?> profile = ValueNotifier(null);

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_profileKey);
    if (raw == null) {
      profile.value = null;
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      profile.value = decoded is Map
          ? TrainingProfile.tryParse(Map<String, dynamic>.from(decoded))
          : null;
    } catch (_) {
      profile.value = null;
    }
  }

  static Future<void> save(TrainingProfile value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_profileKey, jsonEncode(value.toJson()));
    profile.value = value;
  }
}

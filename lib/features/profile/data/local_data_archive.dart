import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract final class LocalDataArchive {
  static const keyPrefix = 'gymrat-';

  static Future<String> exportJson() async {
    final preferences = await SharedPreferences.getInstance();
    final keys =
        preferences.getKeys().where((key) => key.startsWith(keyPrefix)).toList()
          ..sort();
    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'format': 'gymrat-local-export-v1',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': <String, Object?>{
        for (final key in keys) key: preferences.get(key),
      },
    });
  }

  static Future<int> clear() async {
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences
        .getKeys()
        .where((key) => key.startsWith(keyPrefix))
        .toList(growable: false);
    var removed = 0;
    for (final key in keys) {
      if (await preferences.remove(key)) removed++;
    }
    return removed;
  }
}

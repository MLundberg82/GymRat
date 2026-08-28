import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppLanguageStore {
  static const _key = 'gymrat-language';
  static final ValueNotifier<Locale?> locale = ValueNotifier(null);

  static const supported = [
    Locale('en'),
    Locale('sv'),
    Locale('es'),
    Locale('ru'),
    Locale('zh'),
  ];

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    locale.value = code == null || code == 'system' ? null : Locale(code);
  }

  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == 'system') {
      await prefs.setString(_key, 'system');
      locale.value = null;
      return;
    }
    await prefs.setString(_key, code);
    locale.value = Locale(code);
  }

  static String currentCode() => locale.value?.languageCode ?? 'system';
}

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class PremiumLocalAccess {
  static const _storedGrantKey = 'gymrat-premium-local-grant-v1';
  static const _expectedCodeHash = String.fromEnvironment(
    'GYMRAT_PREMIUM_ACCESS_CODE_SHA256',
  );
  static const _debugGrant = 'debug-local';

  static final ValueNotifier<bool> active = ValueNotifier<bool>(false);

  static bool get codeUnlockConfigured => _expectedCodeHash.length == 64;

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_storedGrantKey);
    active.value =
        stored == _debugGrant && kDebugMode ||
        codeUnlockConfigured && stored == _expectedCodeHash.toLowerCase();
  }

  static Future<bool> unlockWithCode(String code) async {
    if (!codeUnlockConfigured) return false;
    final suppliedHash = sha256
        .convert(utf8.encode(code.trim()))
        .toString()
        .toLowerCase();
    if (!_constantTimeEquals(suppliedHash, _expectedCodeHash.toLowerCase())) {
      return false;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storedGrantKey, suppliedHash);
    active.value = true;
    return true;
  }

  static Future<bool> enableDebugAccess() async {
    if (!kDebugMode) return false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storedGrantKey, _debugGrant);
    active.value = true;
    return true;
  }

  static Future<void> revoke() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storedGrantKey);
    active.value = false;
  }

  static bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}

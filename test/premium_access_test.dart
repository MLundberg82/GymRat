import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/premium/data/premium_local_access.dart';
import 'package:gymrat/features/premium/data/premium_prompt_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PremiumLocalAccess.active.value = false;
  });

  tearDown(() {
    PremiumLocalAccess.active.value = false;
  });

  test('local debug Premium persists only in debug/test builds', () async {
    expect(kDebugMode, isTrue);

    expect(await PremiumLocalAccess.enableDebugAccess(), isTrue);
    expect(PremiumLocalAccess.active.value, isTrue);

    PremiumLocalAccess.active.value = false;
    await PremiumLocalAccess.initialize();
    expect(PremiumLocalAccess.active.value, isTrue);

    await PremiumLocalAccess.revoke();
    expect(PremiumLocalAccess.active.value, isFalse);
  });

  test('workout paywall is occasional and respects its cooldown', () async {
    expect(await PremiumPromptPolicy.shouldShowAfterWorkout(1), isFalse);
    expect(await PremiumPromptPolicy.shouldShowAfterWorkout(3), isTrue);
    expect(await PremiumPromptPolicy.shouldShowAfterWorkout(10), isFalse);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'gymrat-premium-last-workout-prompt',
      DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
    );
    expect(await PremiumPromptPolicy.shouldShowAfterWorkout(10), isTrue);
  });
}

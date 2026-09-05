import 'package:shared_preferences/shared_preferences.dart';

abstract final class PremiumPromptPolicy {
  static const _lastWorkoutPromptKey = 'gymrat-premium-last-workout-prompt';
  static const _cooldown = Duration(days: 14);

  static Future<bool> shouldShowAfterWorkout(int totalWorkouts) async {
    if (totalWorkouts != 3 && (totalWorkouts < 10 || totalWorkouts % 10 != 0)) {
      return false;
    }
    final preferences = await SharedPreferences.getInstance();
    final previous = DateTime.tryParse(
      preferences.getString(_lastWorkoutPromptKey) ?? '',
    );
    final now = DateTime.now();
    if (previous != null && now.difference(previous) < _cooldown) return false;
    await preferences.setString(_lastWorkoutPromptKey, now.toIso8601String());
    return true;
  }
}

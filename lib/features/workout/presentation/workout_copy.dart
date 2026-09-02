import 'package:flutter/widgets.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../domain/workout_models.dart';

abstract final class WorkoutCopy {
  static const _workoutKeys = <String, String>{
    'CHEST': 'workoutChest',
    'BACK': 'workoutBack',
    'LEGS': 'workoutLegs',
    'ARMS': 'workoutArms',
    'WALK': 'workoutWalk',
  };

  static const _subtitleKeys = <String, String>{
    'chest': 'workoutChestSubtitle',
    'back': 'workoutBackSubtitle',
    'legs': 'workoutLegsSubtitle',
    'arms': 'workoutArmsSubtitle',
    'walk': 'workoutWalkSubtitle',
  };

  static const _exerciseKeys = <String, String>{
    'Bench Press': 'exerciseBenchPress',
    'Incline Dumbbell Press': 'exerciseInclineDumbbellPress',
    'Chest Fly': 'exerciseChestFly',
    'Cable Press': 'exerciseCablePress',
    'Lat Pulldown': 'exerciseLatPulldown',
    'Barbell Row': 'exerciseBarbellRow',
    'Seated Cable Row': 'exerciseSeatedCableRow',
    'Face Pull': 'exerciseFacePull',
    'Squat': 'exerciseSquat',
    'Leg Press': 'exerciseLegPress',
    'Romanian Deadlift': 'exerciseRomanianDeadlift',
    'Leg Curl': 'exerciseLegCurl',
    'Barbell Curl': 'exerciseBarbellCurl',
    'Hammer Curl': 'exerciseHammerCurl',
    'Tricep Pushdown': 'exerciseTricepPushdown',
    'Overhead Extension': 'exerciseOverheadExtension',
  };

  static String workout(BuildContext context, String canonicalName) =>
      _translate(
        context,
        _workoutKeys[canonicalName.toUpperCase()],
        canonicalName,
      );

  static String subtitle(BuildContext context, WorkoutPreset preset) =>
      _translate(context, _subtitleKeys[preset.id], preset.subtitle);

  static String exercise(BuildContext context, String canonicalName) =>
      _translate(context, _exerciseKeys[canonicalName], canonicalName);

  static String _translate(
    BuildContext context,
    String? key,
    String fallback,
  ) => key == null ? fallback : context.tr.t(key);
}

class WorkoutTimerSettings {
  const WorkoutTimerSettings({
    required this.setSeconds,
    required this.restSeconds,
    required this.autoLoop,
  });

  final int setSeconds;
  final int restSeconds;
  final bool autoLoop;

  WorkoutTimerSettings copyWith({
    int? setSeconds,
    int? restSeconds,
    bool? autoLoop,
  }) {
    return WorkoutTimerSettings(
      setSeconds: setSeconds ?? this.setSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      autoLoop: autoLoop ?? this.autoLoop,
    );
  }
}

abstract final class WorkoutTimerStore {
  static WorkoutTimerSettings current = const WorkoutTimerSettings(
    setSeconds: 60,
    restSeconds: 90,
    autoLoop: true,
  );
}

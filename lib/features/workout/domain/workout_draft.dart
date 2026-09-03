class WorkoutSetDraft {
  const WorkoutSetDraft({required this.weight, required this.reps});

  final String weight;
  final String reps;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'weight': weight,
    'reps': reps,
  };

  factory WorkoutSetDraft.fromJson(Map<String, dynamic> json) =>
      WorkoutSetDraft(
        weight: json['weight'] as String? ?? '',
        reps: json['reps'] as String? ?? '',
      );
}

class WorkoutDraft {
  const WorkoutDraft({
    required this.presetId,
    required this.exerciseIndex,
    required this.elapsedSeconds,
    required this.savedAt,
    required this.sets,
  });

  static const schemaVersion = 1;

  final String presetId;
  final int exerciseIndex;
  final int elapsedSeconds;
  final DateTime savedAt;
  final Map<String, List<WorkoutSetDraft>> sets;

  bool get hasEnteredData => sets.values.any(
    (entries) => entries.any(
      (entry) => entry.weight.trim().isNotEmpty || entry.reps.trim().isNotEmpty,
    ),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': schemaVersion,
    'presetId': presetId,
    'exerciseIndex': exerciseIndex,
    'elapsedSeconds': elapsedSeconds,
    'savedAt': savedAt.toIso8601String(),
    'sets': sets.map(
      (name, entries) => MapEntry(
        name,
        entries.map((entry) => entry.toJson()).toList(growable: false),
      ),
    ),
  };

  static WorkoutDraft? tryParse(Map<String, dynamic> json) {
    final presetId = json['presetId'];
    final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
    if (presetId is! String || presetId.isEmpty || savedAt == null) return null;

    final parsedSets = <String, List<WorkoutSetDraft>>{};
    final rawSets = json['sets'];
    if (rawSets is Map) {
      for (final entry in rawSets.entries) {
        if (entry.key is! String || entry.value is! List) continue;
        parsedSets[entry.key as String] = (entry.value as List)
            .whereType<Map>()
            .map(
              (value) =>
                  WorkoutSetDraft.fromJson(Map<String, dynamic>.from(value)),
            )
            .toList(growable: false);
      }
    }

    final exerciseIndex = json['exerciseIndex'];
    final elapsedSeconds = json['elapsedSeconds'];
    return WorkoutDraft(
      presetId: presetId,
      exerciseIndex: exerciseIndex is num ? exerciseIndex.toInt() : 0,
      elapsedSeconds: elapsedSeconds is num ? elapsedSeconds.toInt() : 0,
      savedAt: savedAt,
      sets: parsedSets,
    );
  }
}

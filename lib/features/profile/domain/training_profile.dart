enum RatGender { male, female, nonBinary }

enum TrainingExperience { beginner, intermediate, advanced, expert }

enum TrainingGoal { buildMuscle, strength, fatLoss, generalFitness }

class TrainingProfile {
  const TrainingProfile({
    required this.gender,
    required this.experience,
    required this.heightCm,
    required this.weightKg,
    required this.sessionsPerWeek,
    required this.goal,
  });

  final RatGender gender;
  final TrainingExperience experience;
  final int heightCm;
  final double weightKg;
  final int sessionsPerWeek;
  final TrainingGoal goal;

  TrainingProfile copyWith({
    RatGender? gender,
    TrainingExperience? experience,
    int? heightCm,
    double? weightKg,
    int? sessionsPerWeek,
    TrainingGoal? goal,
  }) => TrainingProfile(
    gender: gender ?? this.gender,
    experience: experience ?? this.experience,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
    goal: goal ?? this.goal,
  );

  static const starter = TrainingProfile(
    gender: RatGender.nonBinary,
    experience: TrainingExperience.beginner,
    heightCm: 175,
    weightKg: 75,
    sessionsPerWeek: 3,
    goal: TrainingGoal.generalFitness,
  );

  Map<String, Object> toJson() => <String, Object>{
    'version': 1,
    'gender': gender.name,
    'experience': experience.name,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'sessionsPerWeek': sessionsPerWeek,
    'goal': goal.name,
  };

  static TrainingProfile? tryParse(Map<String, dynamic> json) {
    final gender = _enumByName(RatGender.values, json['gender']);
    final experience = _enumByName(
      TrainingExperience.values,
      json['experience'],
    );
    final goal = _enumByName(TrainingGoal.values, json['goal']);
    final height = json['heightCm'];
    final weight = json['weightKg'];
    final sessions = json['sessionsPerWeek'];
    if (gender == null ||
        experience == null ||
        goal == null ||
        height is! num ||
        weight is! num ||
        sessions is! num) {
      return null;
    }
    return TrainingProfile(
      gender: gender,
      experience: experience,
      heightCm: height.toInt().clamp(120, 230),
      weightKg: weight.toDouble().clamp(35, 250),
      sessionsPerWeek: sessions.toInt().clamp(1, 7),
      goal: goal,
    );
  }

  static T? _enumByName<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../data/training_profile_store.dart';
import '../domain/training_profile.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.initialProfile,
    this.editing = false,
  });

  final TrainingProfile? initialProfile;
  final bool editing;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  late RatGender _gender;
  late TrainingExperience _experience;
  late TrainingGoal _goal;
  late double _height;
  late double _weight;
  late double _sessions;
  late double _age;
  int _page = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile ?? TrainingProfile.starter;
    _gender = profile.gender;
    _experience = profile.experience;
    _goal = profile.goal;
    _height = profile.heightCm.toDouble();
    _weight = profile.weightKg;
    _sessions = profile.sessionsPerWeek.toDouble();
    _age = (profile.ageYears ?? 30).toDouble();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < 2) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    setState(() => _saving = true);
    await TrainingProfileStore.save(
      TrainingProfile(
        gender: _gender,
        experience: _experience,
        heightCm: _height.round(),
        weightKg: double.parse(_weight.toStringAsFixed(1)),
        sessionsPerWeek: _sessions.round(),
        goal: _goal,
        ageYears: _age.round(),
      ),
    );
    if (!mounted) return;
    if (widget.editing) Navigator.of(context).pop();
  }

  void _back() {
    if (_page == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: widget.editing,
    child: Scaffold(
      backgroundColor: GymRatColors.black,
      appBar: widget.editing
          ? AppBar(
              backgroundColor: GymRatColors.black,
              title: Text(
                context.tr.t('editTrainingProfile'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.editing)
                    const Text(
                      'GYMRAT',
                      style: TextStyle(
                        color: GymRatColors.green,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (!widget.editing) const SizedBox(height: 14),
                  Text(
                    context.tr.t('onboardingTitle'),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    context.tr.t('onboardingSubtitle'),
                    style: const TextStyle(
                      color: GymRatColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: List.generate(
                      3,
                      (index) => Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index == 2 ? 0 : 7),
                          decoration: BoxDecoration(
                            color: index <= _page
                                ? GymRatColors.green
                                : GymRatColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _GenderStep(
                    selected: _gender,
                    onSelected: (value) => setState(() => _gender = value),
                  ),
                  _ExperienceStep(
                    selected: _experience,
                    sessions: _sessions,
                    onSelected: (value) => setState(() => _experience = value),
                    onSessionsChanged: (value) =>
                        setState(() => _sessions = value),
                  ),
                  _GoalStep(
                    selected: _goal,
                    height: _height,
                    weight: _weight,
                    age: _age,
                    onSelected: (value) => setState(() => _goal = value),
                    onHeightChanged: (value) => setState(() => _height = value),
                    onWeightChanged: (value) => setState(() => _weight = value),
                    onAgeChanged: (value) => setState(() => _age = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
              child: Row(
                children: [
                  if (_page > 0) ...[
                    IconButton.outlined(
                      onPressed: _saving ? null : _back,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _saving ? null : _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: GymRatColors.green,
                          foregroundColor: GymRatColors.black,
                        ),
                        child: Text(
                          context.tr.t(
                            _page == 2 ? 'forgeMyGymRat' : 'continueLabel',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GenderStep extends StatelessWidget {
  const _GenderStep({required this.selected, required this.onSelected});

  final RatGender selected;
  final ValueChanged<RatGender> onSelected;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
    children: [
      _StepTitle(
        title: context.tr.t('chooseRatIdentity'),
        subtitle: context.tr.t('chooseRatIdentityHelp'),
      ),
      const SizedBox(height: 18),
      for (final gender in RatGender.values) ...[
        _ChoiceCard(
          selected: selected == gender,
          icon: switch (gender) {
            RatGender.male => Icons.male_rounded,
            RatGender.female => Icons.female_rounded,
            RatGender.nonBinary => Icons.transgender_rounded,
          },
          title: context.tr.t(_genderKey(gender)),
          onTap: () => onSelected(gender),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 6),
      Text(
        context.tr.t('ratMasterNotice'),
        style: const TextStyle(
          color: GymRatColors.textMuted,
          fontSize: 10,
          height: 1.35,
        ),
      ),
    ],
  );
}

class _ExperienceStep extends StatelessWidget {
  const _ExperienceStep({
    required this.selected,
    required this.sessions,
    required this.onSelected,
    required this.onSessionsChanged,
  });

  final TrainingExperience selected;
  final double sessions;
  final ValueChanged<TrainingExperience> onSelected;
  final ValueChanged<double> onSessionsChanged;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
    children: [
      _StepTitle(
        title: context.tr.t('trainingLevelTitle'),
        subtitle: context.tr.t('trainingLevelHelp'),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          for (final experience in TrainingExperience.values)
            ChoiceChip(
              selected: selected == experience,
              label: Text(context.tr.t(_experienceKey(experience))),
              onSelected: (_) => onSelected(experience),
              selectedColor: GymRatColors.green,
              backgroundColor: GymRatColors.surface,
              labelStyle: TextStyle(
                color: selected == experience
                    ? GymRatColors.black
                    : GymRatColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
      const SizedBox(height: 30),
      _SliderCard(
        label: context.tr.t('sessionsPerWeek'),
        valueLabel: '${sessions.round()}',
        child: Slider(
          value: sessions,
          min: 1,
          max: 7,
          divisions: 6,
          onChanged: onSessionsChanged,
        ),
      ),
    ],
  );
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.selected,
    required this.height,
    required this.weight,
    required this.age,
    required this.onSelected,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onAgeChanged,
  });

  final TrainingGoal selected;
  final double height;
  final double weight;
  final double age;
  final ValueChanged<TrainingGoal> onSelected;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<double> onAgeChanged;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
    children: [
      _StepTitle(
        title: context.tr.t('goalAndBodyTitle'),
        subtitle: context.tr.t('goalAndBodyHelp'),
      ),
      const SizedBox(height: 15),
      for (final goal in TrainingGoal.values) ...[
        _ChoiceCard(
          selected: selected == goal,
          icon: _goalIcon(goal),
          title: context.tr.t(_goalKey(goal)),
          onTap: () => onSelected(goal),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 18),
      _SliderCard(
        label: context.tr.t('ageLabel'),
        valueLabel: '${age.round()} ${context.tr.t('yearsShort')}',
        child: Slider(
          value: age,
          min: 16,
          max: 100,
          divisions: 84,
          onChanged: onAgeChanged,
        ),
      ),
      const SizedBox(height: 10),
      _SliderCard(
        label: context.tr.t('heightLabel'),
        valueLabel: '${height.round()} cm',
        child: Slider(
          value: height,
          min: 120,
          max: 230,
          divisions: 110,
          onChanged: onHeightChanged,
        ),
      ),
      const SizedBox(height: 10),
      _SliderCard(
        label: context.tr.t('weightLabel'),
        valueLabel: '${weight.toStringAsFixed(1)} kg',
        child: Slider(
          value: weight,
          min: 35,
          max: 250,
          divisions: 430,
          onChanged: onWeightChanged,
        ),
      ),
    ],
  );
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 5),
      Text(
        subtitle,
        style: const TextStyle(
          color: GymRatColors.textSecondary,
          fontSize: 11,
          height: 1.4,
        ),
      ),
    ],
  );
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GymRatColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? GymRatColors.green : GymRatColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? GymRatColors.green : GymRatColors.textMuted,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? GymRatColors.green : GymRatColors.textMuted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.label,
    required this.valueLabel,
    required this.child,
  });

  final String label;
  final String valueLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(15, 14, 15, 8),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(
              valueLabel,
              style: const TextStyle(
                color: GymRatColors.green,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        child,
      ],
    ),
  );
}

String _genderKey(RatGender gender) => switch (gender) {
  RatGender.male => 'genderMale',
  RatGender.female => 'genderFemale',
  RatGender.nonBinary => 'genderNonBinary',
};

String _experienceKey(TrainingExperience experience) => switch (experience) {
  TrainingExperience.beginner => 'experienceBeginner',
  TrainingExperience.intermediate => 'experienceIntermediate',
  TrainingExperience.advanced => 'experienceAdvanced',
  TrainingExperience.expert => 'experienceExpert',
};

String _goalKey(TrainingGoal goal) => switch (goal) {
  TrainingGoal.buildMuscle => 'goalBuildMuscle',
  TrainingGoal.strength => 'goalStrength',
  TrainingGoal.fatLoss => 'goalFatLoss',
  TrainingGoal.generalFitness => 'goalGeneralFitness',
};

IconData _goalIcon(TrainingGoal goal) => switch (goal) {
  TrainingGoal.buildMuscle => Icons.fitness_center_rounded,
  TrainingGoal.strength => Icons.bolt_rounded,
  TrainingGoal.fatLoss => Icons.local_fire_department_rounded,
  TrainingGoal.generalFitness => Icons.favorite_rounded,
};

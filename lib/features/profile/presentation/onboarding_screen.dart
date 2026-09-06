import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../../core/units/body_measurement_units.dart';
import '../../../core/units/weight_unit_store.dart';
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
  final GlobalKey<FormState> _bodyFormKey = GlobalKey<FormState>();
  late RatGender _gender;
  late TrainingExperience _experience;
  late TrainingGoal _goal;
  late double _sessions;
  late int _heightCm;
  late double _weightKg;
  late int _ageYears;
  late BodyMeasurementSystem _measurementSystem;
  late final TextEditingController _ageController;
  late final TextEditingController _heightCmController;
  late final TextEditingController _weightKgController;
  late final TextEditingController _heightFeetController;
  late final TextEditingController _heightInchesController;
  late final TextEditingController _weightLbController;
  int _page = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile ?? TrainingProfile.starter;
    _gender = profile.gender;
    _experience = profile.experience;
    _goal = profile.goal;
    _sessions = profile.sessionsPerWeek.toDouble();
    _heightCm = profile.heightCm;
    _weightKg = profile.weightKg;
    _ageYears = profile.ageYears ?? 30;
    final useAmericanDefault =
        !WeightUnitStore.hasStoredPreference &&
        WidgetsBinding.instance.platformDispatcher.locale.countryCode
                ?.toUpperCase() ==
            'US';
    _measurementSystem = useAmericanDefault
        ? BodyMeasurementSystem.imperial
        : BodyMeasurementUnits.systemFor(WeightUnitStore.current);
    _ageController = TextEditingController(text: '$_ageYears');
    _heightCmController = TextEditingController();
    _weightKgController = TextEditingController();
    _heightFeetController = TextEditingController();
    _heightInchesController = TextEditingController();
    _weightLbController = TextEditingController();
    _syncMeasurementControllers();
  }

  @override
  void dispose() {
    _controller.dispose();
    _ageController.dispose();
    _heightCmController.dispose();
    _weightKgController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _weightLbController.dispose();
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
    if (_bodyFormKey.currentState?.validate() != true) return;
    _captureBodyMeasurements();
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    await WeightUnitStore.setUnit(
      BodyMeasurementUnits.weightUnitFor(_measurementSystem),
    );
    await TrainingProfileStore.save(
      TrainingProfile(
        gender: _gender,
        experience: _experience,
        heightCm: _heightCm,
        weightKg: double.parse(_weightKg.toStringAsFixed(1)),
        sessionsPerWeek: _sessions.round(),
        goal: _goal,
        ageYears: _ageYears,
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

  void _changeMeasurementSystem(BodyMeasurementSystem value) {
    if (value == _measurementSystem) return;
    _captureBodyMeasurements();
    setState(() {
      _measurementSystem = value;
      _syncMeasurementControllers();
    });
  }

  void _captureBodyMeasurements() {
    final age = int.tryParse(_ageController.text.trim());
    if (age != null && age >= 16 && age <= 100) {
      _ageYears = age;
    }
    if (_measurementSystem == BodyMeasurementSystem.metric) {
      final height = int.tryParse(_heightCmController.text.trim());
      final weight = _parseDecimal(_weightKgController.text);
      if (height != null && height >= 120 && height <= 230) {
        _heightCm = height;
      }
      if (weight != null && weight >= 35 && weight <= 250) {
        _weightKg = weight;
      }
      return;
    }
    final feet = int.tryParse(_heightFeetController.text.trim());
    final inches = int.tryParse(_heightInchesController.text.trim());
    final pounds = _parseDecimal(_weightLbController.text);
    if (feet != null && inches != null && inches >= 0 && inches <= 11) {
      final centimeters = BodyMeasurementUnits.centimetersFromFeetAndInches(
        feet,
        inches,
      );
      if (centimeters >= 120 && centimeters <= 230) {
        _heightCm = centimeters;
      }
    }
    if (pounds != null) {
      final kilograms = WeightUnitStore.toKilograms(
        pounds,
        unit: WeightUnit.pounds,
      );
      if (kilograms >= 35 && kilograms <= 250) {
        _weightKg = kilograms;
      }
    }
  }

  void _syncMeasurementControllers() {
    _heightCmController.text = '$_heightCm';
    _weightKgController.text = _displayNumber(_weightKg);
    final imperial = BodyMeasurementUnits.feetAndInchesFromCentimeters(
      _heightCm,
    );
    _heightFeetController.text = '${imperial.feet}';
    _heightInchesController.text = '${imperial.inches}';
    _weightLbController.text = _displayNumber(
      WeightUnitStore.fromKilograms(_weightKg, unit: WeightUnit.pounds),
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
                    formKey: _bodyFormKey,
                    measurementSystem: _measurementSystem,
                    ageController: _ageController,
                    heightCmController: _heightCmController,
                    weightKgController: _weightKgController,
                    heightFeetController: _heightFeetController,
                    heightInchesController: _heightInchesController,
                    weightLbController: _weightLbController,
                    onSelected: (value) => setState(() => _goal = value),
                    onMeasurementSystemChanged: _changeMeasurementSystem,
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
    required this.formKey,
    required this.measurementSystem,
    required this.ageController,
    required this.heightCmController,
    required this.weightKgController,
    required this.heightFeetController,
    required this.heightInchesController,
    required this.weightLbController,
    required this.onSelected,
    required this.onMeasurementSystemChanged,
  });

  final TrainingGoal selected;
  final GlobalKey<FormState> formKey;
  final BodyMeasurementSystem measurementSystem;
  final TextEditingController ageController;
  final TextEditingController heightCmController;
  final TextEditingController weightKgController;
  final TextEditingController heightFeetController;
  final TextEditingController heightInchesController;
  final TextEditingController weightLbController;
  final ValueChanged<TrainingGoal> onSelected;
  final ValueChanged<BodyMeasurementSystem> onMeasurementSystemChanged;

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
      Form(
        key: formKey,
        child: _BodyInputCard(
          measurementSystem: measurementSystem,
          ageController: ageController,
          heightCmController: heightCmController,
          weightKgController: weightKgController,
          heightFeetController: heightFeetController,
          heightInchesController: heightInchesController,
          weightLbController: weightLbController,
          onMeasurementSystemChanged: onMeasurementSystemChanged,
        ),
      ),
    ],
  );
}

class _BodyInputCard extends StatelessWidget {
  const _BodyInputCard({
    required this.measurementSystem,
    required this.ageController,
    required this.heightCmController,
    required this.weightKgController,
    required this.heightFeetController,
    required this.heightInchesController,
    required this.weightLbController,
    required this.onMeasurementSystemChanged,
  });

  final BodyMeasurementSystem measurementSystem;
  final TextEditingController ageController;
  final TextEditingController heightCmController;
  final TextEditingController weightKgController;
  final TextEditingController heightFeetController;
  final TextEditingController heightInchesController;
  final TextEditingController weightLbController;
  final ValueChanged<BodyMeasurementSystem> onMeasurementSystemChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr.t('manualBodyEntryHelp'),
          style: const TextStyle(
            color: GymRatColors.textSecondary,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<BodyMeasurementSystem>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: BodyMeasurementSystem.metric,
                label: Text(context.tr.t('metricUnits')),
              ),
              ButtonSegment(
                value: BodyMeasurementSystem.imperial,
                label: Text(context.tr.t('imperialUnits')),
              ),
            ],
            selected: {measurementSystem},
            onSelectionChanged: (selection) =>
                onMeasurementSystemChanged(selection.first),
          ),
        ),
        const SizedBox(height: 16),
        _ManualBodyField(
          controller: ageController,
          label: context.tr.t('ageLabel'),
          suffix: context.tr.t('yearsShort'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) =>
              _validateInteger(context, value, minimum: 16, maximum: 100),
        ),
        const SizedBox(height: 12),
        if (measurementSystem == BodyMeasurementSystem.metric) ...[
          _ManualBodyField(
            controller: heightCmController,
            label: context.tr.t('heightLabel'),
            suffix: 'cm',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                _validateInteger(context, value, minimum: 120, maximum: 230),
          ),
          const SizedBox(height: 12),
          _ManualBodyField(
            controller: weightKgController,
            label: context.tr.t('weightLabel'),
            suffix: 'kg',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalFormatter],
            validator: (value) =>
                _validateDecimal(context, value, minimum: 35, maximum: 250),
          ),
        ] else ...[
          Text(
            context.tr.t('heightLabel'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ManualBodyField(
                  controller: heightFeetController,
                  label: context.tr.t('feetLabel'),
                  suffix: 'ft',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => _validateImperialHeight(
                    context,
                    feet: value,
                    inches: heightInchesController.text,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ManualBodyField(
                  controller: heightInchesController,
                  label: context.tr.t('inchesLabel'),
                  suffix: 'in',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      _validateInteger(context, value, minimum: 0, maximum: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ManualBodyField(
            controller: weightLbController,
            label: context.tr.t('weightLabel'),
            suffix: 'lb',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalFormatter],
            validator: (value) => _validateDecimal(
              context,
              value,
              minimum: WeightUnitStore.fromKilograms(
                35,
                unit: WeightUnit.pounds,
              ),
              maximum: WeightUnitStore.fromKilograms(
                250,
                unit: WeightUnit.pounds,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ManualBodyField extends StatelessWidget {
  const _ManualBodyField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.keyboardType,
    required this.inputFormatters,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    validator: validator,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    textInputAction: TextInputAction.next,
    onTapOutside: (_) => FocusScope.of(context).unfocus(),
    style: const TextStyle(fontWeight: FontWeight.w800),
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      filled: true,
      fillColor: GymRatColors.surfaceElevated,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

final _decimalFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'));

String? _validateInteger(
  BuildContext context,
  String? value, {
  required int minimum,
  required int maximum,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return context.tr.t('requiredField');
  final number = int.tryParse(text);
  if (number == null || number < minimum || number > maximum) {
    return context.tr.t('invalidNumber');
  }
  return null;
}

String? _validateDecimal(
  BuildContext context,
  String? value, {
  required double minimum,
  required double maximum,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return context.tr.t('requiredField');
  final number = _parseDecimal(text);
  if (number == null || number < minimum || number > maximum) {
    return context.tr.t('invalidNumber');
  }
  return null;
}

String? _validateImperialHeight(
  BuildContext context, {
  required String? feet,
  required String? inches,
}) {
  final feetText = feet?.trim() ?? '';
  final inchesText = inches?.trim() ?? '';
  if (feetText.isEmpty) return context.tr.t('requiredField');
  final feetValue = int.tryParse(feetText);
  final inchesValue = int.tryParse(inchesText);
  if (feetValue == null || inchesValue == null) return null;
  final centimeters = BodyMeasurementUnits.centimetersFromFeetAndInches(
    feetValue,
    inchesValue,
  );
  if (centimeters < 120 || centimeters > 230) {
    return context.tr.t('invalidNumber');
  }
  return null;
}

double? _parseDecimal(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));

String _displayNumber(double value) {
  final rounded = value.roundToDouble();
  return value == rounded ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
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

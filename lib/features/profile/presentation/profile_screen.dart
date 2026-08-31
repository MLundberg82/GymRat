import 'package:flutter/material.dart';

import '../../../core/localization/app_language_store.dart';
import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../data/training_profile_store.dart';
import '../domain/training_profile.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String selected = AppLanguageStore.currentCode();

  Future<void> _change(String? value) async {
    if (value == null) return;
    await AppLanguageStore.setLanguage(value);
    if (mounted) setState(() => selected = value);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    return Scaffold(
      backgroundColor: GymRatColors.black,
      appBar: AppBar(
        backgroundColor: GymRatColors.black,
        foregroundColor: GymRatColors.textPrimary,
        title: Text(
          t.t('settings'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (TrainingProfileStore.profile.value case final profile?) ...[
            Text(
              t.t('trainingProfile'),
              style: const TextStyle(
                color: GymRatColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: GymRatColors.surface,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: GymRatColors.greenDark),
              ),
              child: Column(
                children: [
                  _ProfileLine(
                    label: t.t('ratIdentity'),
                    value: t.t(_genderKey(profile.gender)),
                  ),
                  _ProfileLine(
                    label: t.t('trainingLevelTitle'),
                    value: t.t(_experienceKey(profile.experience)),
                  ),
                  _ProfileLine(
                    label: t.t('trainingGoal'),
                    value: t.t(_goalKey(profile.goal)),
                  ),
                  _ProfileLine(
                    label: t.t('bodyProfile'),
                    value:
                        '${profile.heightCm} cm · '
                        '${profile.weightKg.toStringAsFixed(1)} kg',
                  ),
                  _ProfileLine(
                    label: t.t('sessionsPerWeek'),
                    value: '${profile.sessionsPerWeek}',
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OnboardingScreen(
                      initialProfile: profile,
                      editing: true,
                    ),
                  ),
                );
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.edit_rounded),
              label: Text(t.t('editTrainingProfile')),
            ),
            const SizedBox(height: 28),
          ],
          Text(
            t.t('appLanguage'),
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.t('languageHelp'),
            style: const TextStyle(
              color: GymRatColors.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: GymRatColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GymRatColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                dropdownColor: GymRatColors.surfaceElevated,
                iconEnabledColor: GymRatColors.textSecondary,
                style: const TextStyle(
                  color: GymRatColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'system',
                    child: Text(t.t('systemDefault')),
                  ),
                  DropdownMenuItem(value: 'en', child: Text(t.t('english'))),
                  DropdownMenuItem(value: 'sv', child: Text(t.t('swedish'))),
                  DropdownMenuItem(value: 'es', child: Text(t.t('spanish'))),
                  DropdownMenuItem(value: 'ru', child: Text(t.t('russian'))),
                  DropdownMenuItem(value: 'zh', child: Text(t.t('chinese'))),
                ],
                onChanged: _change,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: GymRatColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
        ),
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

import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../evolution/domain/evolution_milestones.dart';
import '../../profile/domain/training_profile.dart';
import '../domain/rat_animation_set.dart';
import '../domain/rat_appearance.dart';
import 'gymrat_character.dart';

class CharacterLabScreen extends StatefulWidget {
  const CharacterLabScreen({super.key});

  @override
  State<CharacterLabScreen> createState() => _CharacterLabScreenState();
}

class _CharacterLabScreenState extends State<CharacterLabScreen> {
  RatGender _gender = RatGender.male;
  RatCharacterView _view = RatCharacterView.front;
  int _level = 1;

  @override
  Widget build(BuildContext context) {
    final approvedStage = RatAppearanceCatalog.approvedStageForLevel(
      appearanceId: RatAppearanceCatalog.baseId,
      level: _level,
    );
    final activeAsset = GymRatCharacter.assetFor(
      gender: _gender,
      view: _view,
      level: _level,
    );
    final motion = RatAnimationCatalog.forCharacter(
      gender: _gender,
      view: _view,
      level: _level,
    );
    return Scaffold(
      backgroundColor: GymRatColors.black,
      appBar: AppBar(
        backgroundColor: GymRatColors.black,
        title: Text(context.tr.t('characterLab')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                context.tr.t('characterLabHelp'),
                style: const TextStyle(color: GymRatColors.textMuted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RatGender.values
                    .map(
                      (gender) => ChoiceChip(
                        selected: _gender == gender,
                        label: Text(context.tr.t(_genderKey(gender))),
                        onSelected: (_) => setState(() => _gender = gender),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              SegmentedButton<RatCharacterView>(
                segments: <ButtonSegment<RatCharacterView>>[
                  ButtonSegment(
                    value: RatCharacterView.front,
                    label: Text(context.tr.t('frontView')),
                  ),
                  ButtonSegment(
                    value: RatCharacterView.back,
                    label: Text(context.tr.t('backView')),
                  ),
                ],
                selected: <RatCharacterView>{_view},
                onSelectionChanged: (selection) {
                  setState(() => _view = selection.single);
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: EvolutionMilestones.stages.map((level) {
                    final available = RatAppearanceCatalog.base.stages
                        .containsKey(level);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: _level == level,
                        avatar: Icon(
                          available
                              ? Icons.verified_rounded
                              : Icons.hourglass_empty_rounded,
                          size: 16,
                        ),
                        label: Text('${context.tr.t('level')} $level'),
                        tooltip: available
                            ? null
                            : context.tr.t('assetPending'),
                        onSelected: available
                            ? (_) => setState(() => _level = level)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      center: Alignment(0, .15),
                      colors: <Color>[Color(0xFF163825), Color(0xFF080B09)],
                      radius: .78,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: GymRatColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
                    child: GymRatCharacter(
                      key: ValueKey('$_gender-$_view-$_level'),
                      gender: _gender,
                      view: _view,
                      level: _level,
                      enableEmotes: true,
                      emoteSemanticLabel: context.tr.t('tapRatToFlex'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.verified_rounded,
                        color: GymRatColors.gold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${context.tr.t('approvedAssetStage')}: '
                          '${context.tr.t('level')} $approvedStage',
                          style: const TextStyle(
                            color: GymRatColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.tr.t(
                      motion.isComplete
                          ? 'authoredMotion'
                          : 'safeMotionFallback',
                    ),
                    style: const TextStyle(
                      color: GymRatColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 5),
                  SelectableText(
                    activeAsset,
                    maxLines: 1,
                    style: const TextStyle(
                      color: GymRatColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _genderKey(RatGender gender) => switch (gender) {
    RatGender.male => 'genderMale',
    RatGender.female => 'genderFemale',
    RatGender.nonBinary => 'genderNonBinary',
  };
}

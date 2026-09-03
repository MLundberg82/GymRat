import 'package:flutter/material.dart';

import '../../character/domain/rat_appearance.dart';
import '../../character/domain/rat_character_view.dart';
import '../../profile/domain/training_profile.dart';
import 'evolution_morph.dart';

class EvolutionSequence extends StatelessWidget {
  const EvolutionSequence({
    super.key,
    required this.previousLevel,
    required this.newLevel,
    required this.gender,
    required this.onComplete,
    this.appearanceId = RatAppearanceCatalog.baseId,
    this.characterView = RatCharacterView.front,
  });

  static const Duration duration = Duration(milliseconds: 6400);

  final int previousLevel;
  final int newLevel;
  final RatGender gender;
  final String appearanceId;
  final RatCharacterView characterView;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => EvolutionMorph(
    previousLevel: previousLevel,
    newLevel: newLevel,
    gender: gender,
    appearanceId: appearanceId,
    characterView: characterView,
    duration: duration,
    onComplete: onComplete,
  );
}

import 'package:flutter/material.dart';

import 'evolution_morph.dart';

class EvolutionSequence extends StatelessWidget {
  const EvolutionSequence({
    super.key,
    required this.previousLevel,
    required this.newLevel,
    required this.onComplete,
  });

  static const Duration duration = Duration(milliseconds: 6400);

  final int previousLevel;
  final int newLevel;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => EvolutionMorph(
    previousLevel: previousLevel,
    newLevel: newLevel,
    duration: duration,
    onComplete: onComplete,
  );
}

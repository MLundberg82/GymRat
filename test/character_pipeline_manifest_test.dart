import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/evolution/domain/evolution_milestones.dart';

void main() {
  test('Blender pipeline and runtime share the level 1-100 contract', () {
    final manifest = jsonDecode(
      File('tool/character_pipeline/pipeline_manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(
      (manifest['stages'] as List<dynamic>).cast<int>(),
      EvolutionMilestones.stages,
    );
    expect(
      (manifest['identities'] as Map<String, dynamic>).keys,
      orderedEquals(<String>['male', 'female', 'non_binary']),
    );
    expect(
      (manifest['release_contract']
          as Map<String, dynamic>)['activate_partial_stage'],
      isFalse,
    );
    expect(
      (manifest['release_contract']
          as Map<String, dynamic>)['runtime_physique_scaling'],
      isFalse,
    );
  });
}

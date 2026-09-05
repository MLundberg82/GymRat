import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/character/domain/rat_animation_set.dart';
import 'package:gymrat/features/character/domain/rat_appearance.dart';
import 'package:gymrat/features/evolution/domain/evolution_milestones.dart';

void main() {
  test('Blender pipeline and runtime share the level 1-100 contract', () {
    final manifest = jsonDecode(
      File('tool/character_pipeline/pipeline_manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(manifest['version'], RatAppearanceCatalog.motionContractVersion);

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

    final anatomy = manifest['anatomy_contract'] as Map<String, dynamic>;
    final tail = anatomy['tail_anchor'] as Map<String, dynamic>;
    final head = (tail['head'] as List<dynamic>).cast<num>();
    final tip = (tail['tail'] as List<dynamic>).cast<num>();

    expect(tail['bone'], 'tail_root');
    expect(tail['parent'], 'pelvis');
    expect(tail['rear_midline'], isTrue);
    expect(tail['concealed_by_rear_waistband'], isFalse);
    expect(tail['exit_below_waistband'], isTrue);
    expect(tail['forbid_between_thigh_origin'], isTrue);
    expect(tail['preserve_across_views_and_motions'], isTrue);
    expect(head[0], 0);
    expect(head[2], greaterThan(tip[2]));

    final emotes = manifest['emote_contract'] as Map<String, dynamic>;
    expect(
      (emotes['types'] as List<dynamic>).cast<String>(),
      RatEmoteType.values.map(
        (type) => switch (type) {
          RatEmoteType.doubleBiceps => 'double_biceps',
          RatEmoteType.chestFlex => 'chest_flex',
          RatEmoteType.legPose => 'leg_pose',
          RatEmoteType.triceps => 'triceps',
        },
      ),
    );
    expect(emotes['selection'], 'random_without_immediate_repeat');
    expect(emotes['views'], orderedEquals(<String>['front', 'back']));
    expect(emotes['require_every_identity'], isTrue);
    expect(emotes['require_every_stage'], isTrue);
    expect(emotes['require_every_appearance'], isTrue);
    expect(emotes['synthetic_body_transform'], isFalse);
  });
}

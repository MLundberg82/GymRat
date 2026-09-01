import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/character/domain/rat_appearance.dart';
import 'package:gymrat/features/evolution/domain/evolution_milestones.dart';
import 'package:gymrat/features/profile/domain/training_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stage routing never exposes an unapproved level', () {
    const stagedAppearance = RatAppearance(
      id: 'test',
      stages: <int, Map<RatGender, RatAppearanceAssets>>{
        1: <RatGender, RatAppearanceAssets>{
          RatGender.male: RatAppearanceAssets(front: 'm1f', back: 'm1b'),
          RatGender.female: RatAppearanceAssets(front: 'f1f', back: 'f1b'),
          RatGender.nonBinary: RatAppearanceAssets(front: 'n1f', back: 'n1b'),
        },
        5: <RatGender, RatAppearanceAssets>{
          RatGender.male: RatAppearanceAssets(front: 'm5f', back: 'm5b'),
          RatGender.female: RatAppearanceAssets(front: 'f5f', back: 'f5b'),
          RatGender.nonBinary: RatAppearanceAssets(front: 'n5f', back: 'n5b'),
        },
      },
    );

    expect(stagedAppearance.isComplete, isTrue);
    expect(stagedAppearance.approvedStageForLevel(4), 1);
    expect(stagedAppearance.approvedStageForLevel(5), 5);
    expect(stagedAppearance.approvedStageForLevel(50), 5);
    expect(
      stagedAppearance.assetFor(RatGender.female, RatAppearanceView.back),
      'f1b',
    );
    expect(
      stagedAppearance.assetFor(
        RatGender.nonBinary,
        RatAppearanceView.front,
        level: 10,
      ),
      'n5f',
    );
  });

  test('partial identity or unsupported stages fail the release contract', () {
    const partial = RatAppearance(
      id: 'partial',
      stages: <int, Map<RatGender, RatAppearanceAssets>>{
        1: <RatGender, RatAppearanceAssets>{
          RatGender.male: RatAppearanceAssets(front: 'front', back: 'back'),
        },
      },
    );
    const unsupported = RatAppearance(
      id: 'unsupported',
      stages: <int, Map<RatGender, RatAppearanceAssets>>{
        1: <RatGender, RatAppearanceAssets>{
          RatGender.male: RatAppearanceAssets(front: 'm1f', back: 'm1b'),
          RatGender.female: RatAppearanceAssets(front: 'f1f', back: 'f1b'),
          RatGender.nonBinary: RatAppearanceAssets(front: 'n1f', back: 'n1b'),
        },
        7: <RatGender, RatAppearanceAssets>{
          RatGender.male: RatAppearanceAssets(front: 'm7f', back: 'm7b'),
          RatGender.female: RatAppearanceAssets(front: 'f7f', back: 'f7b'),
          RatGender.nonBinary: RatAppearanceAssets(front: 'n7f', back: 'n7b'),
        },
      },
    );

    expect(partial.isComplete, isFalse);
    expect(unsupported.isComplete, isFalse);
    expect(
      partial.assetFor(RatGender.male, RatAppearanceView.front, level: 50),
      RatAppearanceCatalog.base.assetFor(
        RatGender.male,
        RatAppearanceView.front,
        level: 50,
      ),
    );
  });

  test(
    'every approved stage has transparent corners and paired canvases',
    () async {
      for (final stage in RatAppearanceCatalog.base.stages.entries) {
        for (final gender in RatGender.values) {
          final assets = stage.value[gender];
          expect(assets, isNotNull, reason: 'Level ${stage.key}: $gender');
          final front = assets!.front;
          final back = assets.back;
          final frontInfo = await _inspect(front);
          final backInfo = await _inspect(back);

          expect(frontInfo.cornerAlphas, everyElement(0), reason: front);
          expect(backInfo.cornerAlphas, everyElement(0), reason: back);
          expect(
            (frontInfo.width - backInfo.width).abs() / frontInfo.width,
            lessThan(.03),
            reason: '$front / $back width',
          );
          expect(
            (frontInfo.height - backInfo.height).abs() / frontInfo.height,
            lessThan(.03),
            reason: '$front / $back height',
          );
        }
      }
    },
  );

  test('asset folders contain no partial or unregistered milestone stage', () {
    for (final level in EvolutionMilestones.unlockLevels) {
      final expected = _stagePaths(level);
      final present = expected
          .where((path) => File(path).existsSync())
          .toList();
      expect(
        present,
        anyOf(isEmpty, hasLength(expected.length)),
        reason:
            'Level $level must be absent or contain the complete six-file '
            'matrix. Found: ${present.join(', ')}',
      );
      if (present.isNotEmpty) {
        expect(
          RatAppearanceCatalog.base.stages.containsKey(level),
          isTrue,
          reason:
              'A complete level $level matrix exists but is not registered.',
        );
      }
    }
  });
}

List<String> _stagePaths(int level) {
  final token = level.toString().padLeft(2, '0');
  return <String>[
    'assets/characters/male/level_$token.png',
    'assets/characters/male/level_${token}_back.png',
    'assets/characters/female/level_$token.png',
    'assets/characters/female/level_${token}_back.png',
    'assets/characters/non_binary/level_$token.png',
    'assets/characters/non_binary/level_${token}_back.png',
  ];
}

Future<_ImageInfo> _inspect(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (pixels == null) throw StateError('Could not decode $asset as RGBA.');
  final width = image.width;
  final height = image.height;
  final lastPixel = width * height - 1;
  final corners = <int>[
    pixels.getUint8(3),
    pixels.getUint8((width - 1) * 4 + 3),
    pixels.getUint8((height - 1) * width * 4 + 3),
    pixels.getUint8(lastPixel * 4 + 3),
  ];
  image.dispose();
  codec.dispose();
  return _ImageInfo(width, height, corners);
}

class _ImageInfo {
  const _ImageInfo(this.width, this.height, this.cornerAlphas);

  final int width;
  final int height;
  final List<int> cornerAlphas;
}

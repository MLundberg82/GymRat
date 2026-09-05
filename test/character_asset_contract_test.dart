import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/character/domain/rat_animation_set.dart';
import 'package:gymrat/features/character/domain/rat_appearance.dart';
import 'package:gymrat/features/character/domain/rat_character_view.dart';
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

  test('evolution is released only for a distinct complete stage', () {
    expect(
      RatAppearanceCatalog.hasDistinctStageAtLevel(
        appearanceId: RatAppearanceCatalog.baseId,
        level: 5,
      ),
      isFalse,
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

          expect(frontInfo.pngColorType, 6, reason: '$front is not RGBA PNG');
          expect(backInfo.pngColorType, 6, reason: '$back is not RGBA PNG');
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

  test(
    'every authored motion frame is transparent and canvas-stable',
    () async {
      for (final gender in RatGender.values) {
        for (final view in RatCharacterView.values) {
          final set = RatAnimationCatalog.forCharacter(
            gender: gender,
            view: view,
            level: 1,
          );
          final neutralInfo = await _inspect(set.neutral);

          for (final asset in set.allFrames.toSet()) {
            final info = await _inspect(asset);
            expect(info.cornerAlphas, everyElement(0), reason: asset);
            expect(info.width, neutralInfo.width, reason: asset);
            expect(info.height, neutralInfo.height, reason: asset);
            if (asset.contains('/emote_')) {
              expect(
                info.largeAlphaComponents,
                1,
                reason: '$asset contains a neighbouring pose fragment',
              );
            }
          }
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

  test(
    'breathing frames are RGBA-safe and canvas-matched for every character',
    () async {
      for (final gender in RatGender.values) {
        for (final view in RatCharacterView.values) {
          final motion = RatAnimationCatalog.forCharacter(
            gender: gender,
            view: view,
            level: 50,
          );
          expect(motion.hasAuthoredBreathing, isTrue, reason: '$gender $view');
          final neutralInfo = await _inspect(motion.neutral);
          for (final frame in motion.breathing.toSet()) {
            final frameInfo = await _inspect(frame);
            expect(frameInfo.width, neutralInfo.width, reason: frame);
            expect(frameInfo.height, neutralInfo.height, reason: frame);
            expect(frameInfo.pngColorType, 6, reason: '$frame is not RGBA PNG');
            expect(frameInfo.cornerAlphas, everyElement(0), reason: frame);
          }
        }
      }
    },
  );
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
  final encoded = data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
  final pngColorType = encoded.length > 25 ? encoded[25] : -1;
  final codec = await ui.instantiateImageCodec(encoded);
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
  final largeAlphaComponents = _countLargeAlphaComponents(
    pixels,
    width,
    height,
  );
  image.dispose();
  codec.dispose();
  return _ImageInfo(width, height, corners, pngColorType, largeAlphaComponents);
}

int _countLargeAlphaComponents(ByteData pixels, int width, int height) {
  const blockSize = 4;
  const alphaThreshold = 16;
  const minimumComponentBlocks = 250;
  final gridWidth = (width + blockSize - 1) ~/ blockSize;
  final gridHeight = (height + blockSize - 1) ~/ blockSize;
  final occupied = Uint8List(gridWidth * gridHeight);

  for (var y = 0; y < height; y++) {
    final gridY = y ~/ blockSize;
    for (var x = 0; x < width; x++) {
      if (pixels.getUint8((y * width + x) * 4 + 3) > alphaThreshold) {
        occupied[gridY * gridWidth + x ~/ blockSize] = 1;
      }
    }
  }

  final visited = Uint8List(occupied.length);
  final queue = Int32List(occupied.length);
  var largeComponents = 0;
  for (var start = 0; start < occupied.length; start++) {
    if (occupied[start] == 0 || visited[start] != 0) continue;
    var head = 0;
    var tail = 1;
    var componentSize = 0;
    queue[0] = start;
    visited[start] = 1;

    while (head < tail) {
      final current = queue[head++];
      componentSize++;
      final x = current % gridWidth;
      final y = current ~/ gridWidth;
      final neighbours = <int>[
        if (x > 0) current - 1,
        if (x + 1 < gridWidth) current + 1,
        if (y > 0) current - gridWidth,
        if (y + 1 < gridHeight) current + gridWidth,
      ];
      for (final neighbour in neighbours) {
        if (occupied[neighbour] != 0 && visited[neighbour] == 0) {
          visited[neighbour] = 1;
          queue[tail++] = neighbour;
        }
      }
    }

    if (componentSize >= minimumComponentBlocks) largeComponents++;
  }
  return largeComponents;
}

class _ImageInfo {
  const _ImageInfo(
    this.width,
    this.height,
    this.cornerAlphas,
    this.pngColorType,
    this.largeAlphaComponents,
  );

  final int width;
  final int height;
  final List<int> cornerAlphas;
  final int pngColorType;
  final int largeAlphaComponents;
}

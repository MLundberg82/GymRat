import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/rewards/presentation/volumetric_explosion.dart';
import 'package:gymrat/features/rewards/presentation/volumetric_fire.dart';

void main() {
  test('volumetric explosion advances through the complete atlas', () {
    expect(VolumetricExplosion.frameIndexFor(0), 0);
    expect(
      VolumetricExplosion.frameIndexFor(.5),
      ((VolumetricExplosion.frameCount - 1) * .5).floor(),
    );
    expect(
      VolumetricExplosion.frameIndexFor(1),
      VolumetricExplosion.frameCount - 1,
    );
    expect(VolumetricExplosion.frameIndexFor(-1), 0);
    expect(
      VolumetricExplosion.frameIndexFor(2),
      VolumetricExplosion.frameCount - 1,
    );
  });

  test('volumetric fire loops only within valid atlas frames', () {
    for (var step = 0; step <= 100; step++) {
      final frame = VolumetricFire.frameIndexFor(step / 100);
      expect(frame, inInclusiveRange(0, VolumetricFire.frameCount - 1));
    }
    expect(VolumetricFire.frameIndexFor(-1), 0);
    expect(VolumetricFire.frameIndexFor(2), VolumetricFire.frameCount - 1);
  });
}

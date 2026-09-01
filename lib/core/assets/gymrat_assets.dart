abstract final class GymRatAssets {
  static const String gymBase = 'assets/gyms/gym_base.png';

  static String gymForLevel(int level) {
    final state = level.clamp(1, 50).toInt();
    return 'assets/gyms/gym_level_${state.toString().padLeft(2, '0')}.webp';
  }

  static const String maleLevel1 = 'assets/characters/male/level_01.png';
  static const String maleLevel1Back =
      'assets/characters/male/level_01_back.png';

  static String maleForLevel(int level) {
    return switch (level) {
      _ => maleLevel1,
    };
  }

  static const List<String> maleLevel1IdleFrames = [
    'assets/characters/male/level_01/idle/idle_00.png',
    'assets/characters/male/level_01/idle/idle_01.png',
    'assets/characters/male/level_01/idle/idle_02.png',
    'assets/characters/male/level_01/idle/idle_03.png',
    'assets/characters/male/level_01/idle/idle_04.png',
    'assets/characters/male/level_01/idle/idle_05.png',
    'assets/characters/male/level_01/idle/idle_06.png',
    'assets/characters/male/level_01/idle/idle_07.png',
    'assets/characters/male/level_01/idle/idle_08.png',
    'assets/characters/male/level_01/idle/idle_09.png',
    'assets/characters/male/level_01/idle/idle_10.png',
    'assets/characters/male/level_01/idle/idle_11.png',
    'assets/characters/male/level_01/idle/idle_12.png',
    'assets/characters/male/level_01/idle/idle_13.png',
    'assets/characters/male/level_01/idle/idle_14.png',
    'assets/characters/male/level_01/idle/idle_15.png',
  ];

  static const List<String> maleLevel1BlinkFrames = [
    'assets/characters/male/level_01/blink/blink_00.png',
    'assets/characters/male/level_01/blink/blink_01.png',
    'assets/characters/male/level_01/blink/blink_02.png',
    'assets/characters/male/level_01/blink/blink_03.png',
  ];

  static const List<String> maleLevel1TailFrames = [
    'assets/characters/male/level_01/tail/tail_00.png',
    'assets/characters/male/level_01/tail/tail_01.png',
    'assets/characters/male/level_01/tail/tail_02.png',
    'assets/characters/male/level_01/tail/tail_03.png',
    'assets/characters/male/level_01/tail/tail_04.png',
    'assets/characters/male/level_01/tail/tail_05.png',
    'assets/characters/male/level_01/tail/tail_06.png',
    'assets/characters/male/level_01/tail/tail_07.png',
    'assets/characters/male/level_01/tail/tail_08.png',
    'assets/characters/male/level_01/tail/tail_09.png',
    'assets/characters/male/level_01/tail/tail_10.png',
    'assets/characters/male/level_01/tail/tail_11.png',
  ];

  static const String femaleLevel1 = 'assets/characters/female/level_01.png';
  static const String femaleLevel1Back =
      'assets/characters/female/level_01_back.png';

  static const String nonBinaryLevel1 =
      'assets/characters/non_binary/level_01.png';
  static const String nonBinaryLevel1Back =
      'assets/characters/non_binary/level_01_back.png';

  static const String effectsRoot = 'assets/effects/';
  static const String itemsRoot = 'assets/items/';
}

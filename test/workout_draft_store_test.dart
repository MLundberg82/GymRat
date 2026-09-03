import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/workout/data/workout_draft_store.dart';
import 'package:gymrat/features/workout/domain/workout_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('active workout draft survives a store reload', () async {
    final savedAt = DateTime(2026, 9, 3, 16, 30);
    await WorkoutDraftStore.save(
      WorkoutDraft(
        presetId: 'chest',
        exerciseIndex: 1,
        elapsedSeconds: 312,
        savedAt: savedAt,
        sets: const <String, List<WorkoutSetDraft>>{
          'Bench Press': <WorkoutSetDraft>[
            WorkoutSetDraft(weight: '82,5', reps: '8'),
          ],
        },
      ),
    );

    final restored = await WorkoutDraftStore.loadForPreset('chest');

    expect(restored, isNotNull);
    expect(restored!.exerciseIndex, 1);
    expect(restored.elapsedSeconds, 312);
    expect(restored.savedAt, savedAt);
    expect(restored.sets['Bench Press']!.single.weight, '82,5');
    expect(restored.hasEnteredData, isTrue);
    expect(await WorkoutDraftStore.loadForPreset('back'), isNull);
  });

  test('clearing a completed workout removes its draft', () async {
    await WorkoutDraftStore.save(
      WorkoutDraft(
        presetId: 'legs',
        exerciseIndex: 0,
        elapsedSeconds: 10,
        savedAt: DateTime(2026, 9, 3),
        sets: const <String, List<WorkoutSetDraft>>{},
      ),
    );

    await WorkoutDraftStore.clear();

    expect(await WorkoutDraftStore.load(), isNull);
  });
}

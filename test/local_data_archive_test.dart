import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/profile/data/local_data_archive.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exports and clears only GymRat-owned local values', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'gymrat-total-xp': 420,
      'gymrat-training-profile': '{"gender":"female"}',
      'unrelated-host-value': 'keep',
    });

    final archive = jsonDecode(await LocalDataArchive.exportJson()) as Map;
    final data = archive['data'] as Map;

    expect(archive['format'], 'gymrat-local-export-v1');
    expect(data['gymrat-total-xp'], 420);
    expect(data.containsKey('unrelated-host-value'), isFalse);

    expect(await LocalDataArchive.clear(), 2);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('gymrat-total-xp'), isNull);
    expect(preferences.getString('unrelated-host-value'), 'keep');
  });
}

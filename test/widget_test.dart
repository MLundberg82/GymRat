import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/app/gymrat_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('GymRat app starts successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const GymRatApp());
    await tester.pump();

    expect(find.text('GYMRAT'), findsNothing);
    expect(find.text('START WORKOUT'), findsOneWidget);
    expect(find.text('LVL 1'), findsOneWidget);
  });
}

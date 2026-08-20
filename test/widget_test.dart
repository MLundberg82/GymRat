import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/app/gymrat_app.dart';

void main() {
  testWidgets('GymRat app starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const GymRatApp());

    expect(find.text('GYMRAT'), findsNothing);
    expect(find.text('START WORKOUT'), findsOneWidget);
    expect(find.text('LVL 23'), findsOneWidget);
  });
}
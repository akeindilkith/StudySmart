import 'package:flutter_test/flutter_test.dart';
import 'package:study_smart/main.dart';

void main() {
  testWidgets('StudySmartApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StudySmartApp());
    expect(find.byType(StudySmartApp), findsOneWidget);
  });
}

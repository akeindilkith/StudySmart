import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:study_smart/main.dart';
import 'package:study_smart/providers/app_state.dart';

void main() {
  testWidgets('StudySmartApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const StudySmartApp(),
      ),
    );
    expect(find.byType(StudySmartApp), findsOneWidget);
  });
}

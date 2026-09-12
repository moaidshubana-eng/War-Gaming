import 'package:flutter_test/flutter_test.dart';
import 'package:war_gaming/app.dart';

void main() {
  testWidgets('HomeScreen shows the title and both play-mode buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const WarGamingApp());
    await tester.pumpAndSettle();

    expect(find.text('War Gaming'), findsOneWidget);
    expect(find.text('اللعب أونلاين مع الأصدقاء'), findsOneWidget);
    expect(find.text('اللعب عبر البلوتوث (بدون إنترنت)'), findsOneWidget);
  });
}

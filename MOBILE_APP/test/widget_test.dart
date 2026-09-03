import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel/main.dart';

void main() {
  testWidgets(
    'SENTINEL login screen loads',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SentinelApp());

      expect(find.text('SENTINEL'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(
        find.text('CREATE NEW ACCOUNT'),
        findsOneWidget,
      );
    },
  );
}
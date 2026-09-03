import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel/main.dart';

void main() {
  testWidgets('SENTINEL App loads successfully test', (WidgetTester tester) async {
    // Build SENTINEL app and trigger a frame.
    await tester.pumpWidget(const SentinelApp());

    // Verify that the title on the PaymentScreen is visible.
    expect(find.text('SENTINEL Secure Pay'), findsOneWidget);
  });
}
// ============================================================
// widget_test.dart — Basic smoke test for the app.
//
// This just verifies the app launches without crashing.
// More detailed tests can be added here later.
// ============================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:system_info/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const SystemInfoApp());
  });
}
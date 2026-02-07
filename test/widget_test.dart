import 'package:flutter_test/flutter_test.dart';

import 'package:kalorat/main.dart';

void main() {
  testWidgets('Kalorat app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KaloratApp());

    // Allow widget tree to settle
    await tester.pump();

    // Verify the app builds without errors
    expect(find.byType(KaloratApp), findsOneWidget);
  });
}

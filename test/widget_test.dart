import 'package:flutter_test/flutter_test.dart';
import 'package:lawyer_app_flutter/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: LawyerApp()));

    // Verify that the app starts (showing a loader or login screen)
    expect(find.byType(LawyerApp), findsOneWidget);

    // Wait for the initialization timers (like the 2s update check) to complete
    await tester.pump(const Duration(seconds: 3));
  });
}

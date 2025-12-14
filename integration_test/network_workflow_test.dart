import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_application/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Network Discovery Workflow Tests', () {
    testWidgets('App launches without errors', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // App should launch and show identity setup or main content
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}

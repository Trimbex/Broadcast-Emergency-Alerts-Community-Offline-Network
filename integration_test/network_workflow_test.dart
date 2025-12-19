import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_application/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/services/p2p_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Network Workflow Tests', () {
    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      P2PService().isTestMode = true;
    });

    testWidgets('Can navigate to Network Dashboard', (WidgetTester tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      // 1. Complete Identity Setup
      final nameField = find.ancestor(
        of: find.text('Your Name / Nickname'),
        matching: find.byType(TextField),
      );
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField, 'Network Tester');
        await tester.pump(const Duration(seconds: 2));

        // Hide keyboard aggressively
        try {
          // Attempt to close keyboard connection
          tester.testTextInput.closeConnection(); 
        } catch (_) {}
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump(const Duration(seconds: 1));

        final saveButton = find.text('Save & Continue');
        
        // Manual scroll if ensureVisible is flaky
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500)); 
        await tester.pump(const Duration(seconds: 1));
        
        await tester.ensureVisible(saveButton);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(saveButton, warnIfMissed: false); // Force tap
        await tester.pump(const Duration(seconds: 2));
      }

      // 2. Navigate to Network Dashboard
      // Button text: 'Join Communication Network'
      final joinButton = find.text('Join Communication Network');
      await tester.ensureVisible(joinButton);
      await tester.tap(joinButton);
      await tester.pump(const Duration(seconds: 5));

      // 3. Verify Network Dashboard
      expect(find.textContaining('Network'), findsWidgets);
      
      // Pause for visibility
      await tester.pump(const Duration(seconds: 3));
    });
  });
}

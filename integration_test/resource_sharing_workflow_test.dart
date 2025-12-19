import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_application/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Resource Sharing Workflow Tests', () {
    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('Can navigate to Resources page', (WidgetTester tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));

      // 1. Complete Identity Setup
      final nameField = find.ancestor(
        of: find.text('Your Name / Nickname'),
        matching: find.byType(TextField),
      );
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField, 'Resource Tester');
        await tester.pump(const Duration(seconds: 2));
        
        // Hide keyboard aggressively
        try {
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
        await tester.tap(saveButton, warnIfMissed: false);
        await tester.pump(const Duration(seconds: 2));
      }

      // 2. Navigate to Resources using Quick Access Card
      // Landing Page does not have a drawer. It has a Quick Access Grid.
      // We look for the "Resources" card/text.
      final resourcesCard = find.text('Resources');
      await tester.ensureVisible(resourcesCard);
      await tester.tap(resourcesCard);
      await tester.pump(const Duration(seconds: 2));

      // 3. Verify Resources Page
      expect(find.text('Resource Sharing'), findsWidgets); // Title check
      
      // Pause for user visibility
      await tester.pump(const Duration(seconds: 3));
    });
  });
}

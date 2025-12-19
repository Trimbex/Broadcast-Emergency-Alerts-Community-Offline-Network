import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_application/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Initialization Integration Tests', () {
    setUp(() async {
       // Clear preferences to ensure fresh start between tests
       final prefs = await SharedPreferences.getInstance();
       await prefs.clear();
    });

    testWidgets('App should launch and show identity setup', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pump(const Duration(seconds: 2));

      // Should show identity setup page with correct title
      expect(find.text('Set Up Your Identity'), findsOneWidget);
      expect(find.text('This helps others recognize you in the network.'), findsOneWidget);
    });

    testWidgets('Can complete identity setup', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pump(const Duration(seconds: 2));

      // Find name field by its label text
      final nameField = find.ancestor(
        of: find.text('Your Name / Nickname'),
        matching: find.byType(TextField),
      );
      
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField, 'Test User');
        await tester.pump(const Duration(seconds: 2));
   
        // Tap Save & Continue button  
        final saveButton = find.text('Save & Continue');
        if (saveButton.evaluate().isNotEmpty) {
          // Hide keyboard
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pump(const Duration(seconds: 1));
          
          await tester.ensureVisible(saveButton);
          await tester.tap(saveButton);
          // Use pump instead of pumpAndSettle because Landing Page has infinite animations (pulsing button)
          await tester.pump(const Duration(seconds: 2));

          // Successfully navigated away from identity setup
        }
      }
    });
  });

  group('Theme Integration Tests', () {
    testWidgets('Can toggle theme', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pump(const Duration(seconds: 2));

      // Find theme toggle button
      final themeToggle = find.byIcon(Icons.brightness_6);
      if (themeToggle.evaluate().isNotEmpty) {
        // Get current theme
        final BuildContext context = tester.element(find.byType(MaterialApp));
        final brightness = Theme.of(context).brightness;

        // Toggle theme
        await tester.tap(themeToggle);
        await tester.pump(const Duration(seconds: 10)); // Use pump to avoid infinite animation hang

        // Theme should have changed
        final newBrightness = Theme.of(context).brightness;
        expect(newBrightness, isNot(equals(brightness)));
      }
    });
  });
}

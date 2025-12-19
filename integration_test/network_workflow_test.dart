import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_application/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/services/p2p_service.dart';
import 'package:flutter_application/widgets/network_dashboard/device_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Network Workflow Tests', () {
    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // Bypass permission dialogs but use real Nearby Connections API
      P2PService().isTestMode = true;
      P2PService().shouldUseRealNearbyApi = true;
    });

    testWidgets('Can navigate to Network Dashboard and connect to real device', (WidgetTester tester) async {
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

        // Hide keyboard
        try {
          tester.testTextInput.closeConnection(); 
        } catch (_) {}
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump(const Duration(seconds: 1));

        final saveButton = find.text('Save & Continue');
        
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500)); 
        await tester.pump(const Duration(seconds: 1));
        
        await tester.ensureVisible(saveButton);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(saveButton, warnIfMissed: false);
        await tester.pump(const Duration(seconds: 2));
      }

      // 2. Navigate to Network Dashboard (this starts advertising + discovery)
      final joinButton = find.text('Join Communication Network');
      await tester.ensureVisible(joinButton);
      await tester.tap(joinButton);
      await tester.pump(const Duration(seconds: 5));

      // 3. Verify Network Dashboard loaded
      expect(find.textContaining('Network'), findsWidgets);
      
      // 4. Wait for real device connection (up to 30 seconds)
      // In real life, when another device also joins the network,
      // they connect automatically and appear as a DeviceCard
      print('📡 Waiting for real device to connect...');
      bool deviceFound = false;
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(DeviceCard).evaluate().isNotEmpty) {
          deviceFound = true;
          print('✅ Device found after ${i + 1} seconds!');
          break;
        }
        if (i % 5 == 0) {
          print('⏳ Still waiting... ${30 - i} seconds remaining');
        }
      }

      if (deviceFound) {
        // 5. Connect to the first device (tap chat button)
        final deviceFinder = find.byType(DeviceCard);
        final chatButton = find.descendant(
          of: deviceFinder.first,
          matching: find.byIcon(Icons.chat_bubble_outline),
        );
        
        await tester.tap(chatButton);
        await tester.pumpAndSettle();
        
        // 6. Verify Chat Page opened
        expect(find.byType(TextField), findsOneWidget); // Message input field
        print('✅ Chat page opened successfully!');
        
        // 7. Send a test message
        final messageField = find.byType(TextField);
        await tester.enterText(messageField, 'Hello from integration test!');
        await tester.pump(const Duration(seconds: 1));
        
        // Find and tap send button
        final sendButton = find.byIcon(Icons.send);
        if (sendButton.evaluate().isNotEmpty) {
          await tester.tap(sendButton);
          await tester.pump(const Duration(seconds: 2));
          print('✅ Test message sent!');
        }
        
        // 8. Go back to dashboard
        await tester.pageBack();
        await tester.pumpAndSettle();
      } else {
        print('⚠️ SKIPPING: No devices found for connection test after 30 seconds.');
        print('   Make sure another device is running the app and has joined the network.');
      }

      // Final pause for visibility
      await tester.pump(const Duration(seconds: 3));
    });
  });
}

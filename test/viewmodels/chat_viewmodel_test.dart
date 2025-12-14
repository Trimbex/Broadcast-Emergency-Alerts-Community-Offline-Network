import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/viewmodels/chat_viewmodel.dart';
import 'package:flutter_application/models/device_model.dart';
import 'package:flutter_application/models/message_model.dart';
import '../mocks/mock_services.dart';

void main() {
  group('ChatViewModel Tests', () {
    late MockP2PService mockP2PService;
    late MockDatabaseService mockDatabaseService;
    late ChatViewModel viewModel;

    setUp(() {
      mockP2PService = MockP2PService();
      mockDatabaseService = MockDatabaseService();
      viewModel = ChatViewModel(
        p2pService: mockP2PService,
        databaseService: mockDatabaseService,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('Initial state should be empty', () {
      expect(viewModel.messages, isEmpty);
      expect(viewModel.device, isNull);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('Initialize should load messages from database', () async {
      // Arrange
      final device = DeviceModel(
        id: 'device1',
        name: 'Test Device',
        status: 'Connected',
        distance: '5m',
        batteryLevel: 80,
        endpointId: 'endpoint1',
      );

      final messages = [
        MessageModel(
          id: '1',
          senderId: 'device1',
          senderName: 'Test',
          text: 'Hello',
          timestamp: DateTime.now(),
          isMe: false,
          messageType: 'text',
        ),
      ];

      mockDatabaseService.setMessages(messages);

      // Act
      await viewModel.initialize(device);

      // Assert
      expect(viewModel.device, equals(device));
      expect(viewModel.messages.length, equals(1));
      expect(viewModel.messages.first.text, equals('Hello'));
      expect(viewModel.isLoading, isFalse);
    });

    test('Send message should add message to list', () async {
      // Arrange
      final device = DeviceModel(
        id: 'device1',
        name: 'Test Device',
        status: 'Connected',
        distance: '5m',
        batteryLevel: 80,
        endpointId: 'endpoint1',
      );
      await viewModel.initialize(device);

      // Act
      final result = await viewModel.sendMessage('Test message');

      // Assert
      expect(result, isTrue);
      expect(mockP2PService.lastSentMessage, equals('Test message'));
    });

    test('Send empty message should return false', () async {
      // Arrange
      final device = DeviceModel(
        id: 'device1',
        name: 'Test Device',
        status: 'Connected',
        distance: '5m',
        batteryLevel: 80,
        endpointId: 'endpoint1',
      );
      await viewModel.initialize(device);

      // Act
      final result = await viewModel.sendMessage('   ');

      // Assert
      expect(result, isFalse);
    });

    test('Send quick message should broadcast emergency', () async {
      // Arrange
      final device = DeviceModel(
        id: 'device1',
        name: 'Test Device',
        status: 'Connected',
        distance: '5m',
        batteryLevel: 80,
        endpointId: 'endpoint1',
      );
      await viewModel.initialize(device);

      // Act
      final result = await viewModel.sendQuickMessage('SOS', isEmergency: true);

      // Assert
      expect(result, isTrue);
      expect(mockP2PService.lastEmergencyAlert, equals('SOS'));
    });

    test('isConnected should return true when device is in connected list', () async {
      // Arrange
      final device = DeviceModel(
        id: 'device1',
        name: 'Test Device',
        status: 'Connected',
        distance: '5m',
        batteryLevel: 80,
        endpointId: 'endpoint1',
      );
      mockP2PService.addConnectedDevice(device);
      await viewModel.initialize(device);

      // Assert
      expect(viewModel.isConnected, isTrue);
    });

    test('Error during initialization should set error message', () async {
      // Arrange
      final device = DeviceModel(
        id: 'device1',
        name: 'Test Device',
        status: 'Connected',
        distance: '5m',
        batteryLevel: 80,
        endpointId: 'endpoint1',
      );
      mockDatabaseService.shouldThrowError = true;

      // Act
      await viewModel.initialize(device);

      // Assert
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.isLoading, isFalse);
    });
  });
}

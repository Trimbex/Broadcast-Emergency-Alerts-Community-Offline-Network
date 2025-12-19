import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_application/viewmodels/chat_viewmodel.dart';
import 'package:flutter_application/models/device_model.dart';
import 'package:flutter_application/models/message_model.dart';
import '../mocks/mock_services.mocks.dart';

void main() {
  group('ChatViewModel Tests', () {
    late MockP2PService mockP2PService;
    late MockDatabaseService mockDatabaseService;
    late ChatViewModel viewModel;

    setUp(() {
      mockP2PService = MockP2PService();
      mockDatabaseService = MockDatabaseService();
      
      // Default stubs to prevent null errors during initialization checks or constructor usage
      when(mockP2PService.connectedDevices).thenReturn([]);
      
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

      // Stub mocks
      when(mockP2PService.connectedDevices).thenReturn([device]);
      when(mockDatabaseService.getMessages('endpoint1')).thenAnswer((_) async => messages);
      when(mockDatabaseService.getMessages('device1')).thenAnswer((_) async => []); // Different ID check
      when(mockP2PService.getMessageHistoryForDevice('endpoint1', 'device1')).thenReturn([]);
      when(mockP2PService.getMessageStream('endpoint1')).thenAnswer((_) => Stream.empty());

      // Act
      await viewModel.initialize(device);

      // Assert
      expect(viewModel.device, equals(device));
      expect(viewModel.messages.length, equals(1));
      expect(viewModel.messages.first.text, equals('Hello'));
      expect(viewModel.isLoading, isFalse);
    });

    test('Send message should add message to list and call service', () async {
      // Arrange
      final device = DeviceModel(
        id: 'device1',
        name: 'Test Device',
        status: 'Connected',
        distance: '5m',
        batteryLevel: 80,
        endpointId: 'endpoint1',
      );
      
      // Setup initialization stubs
      when(mockP2PService.connectedDevices).thenReturn([device]);
      when(mockDatabaseService.getMessages(any)).thenAnswer((_) async => []);
      when(mockP2PService.getMessageHistoryForDevice(any, any)).thenReturn([]);
      when(mockP2PService.getMessageStream(any)).thenAnswer((_) => Stream.empty());
      
      await viewModel.initialize(device);

      // Setup sendMessage stub
      when(mockP2PService.sendMessage(any, any)).thenAnswer((_) async {});

      // Act
      final result = await viewModel.sendMessage('Test message');

      // Assert
      expect(result, isTrue);
      // Verify P2P service was called with correct arguments
      verify(mockP2PService.sendMessage('endpoint1', 'Test message')).called(1);
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
      
      // Setup initialization stubs
      when(mockP2PService.connectedDevices).thenReturn([device]);
      when(mockDatabaseService.getMessages(any)).thenAnswer((_) async => []);
      when(mockP2PService.getMessageHistoryForDevice(any, any)).thenReturn([]);
      when(mockP2PService.getMessageStream(any)).thenAnswer((_) => Stream.empty());
      
      await viewModel.initialize(device);

      // Act
      final result = await viewModel.sendMessage('   ');

      // Assert
      expect(result, isFalse);
      verifyNever(mockP2PService.sendMessage(any, any));
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
      
      // Setup initialization stubs
      when(mockP2PService.connectedDevices).thenReturn([device]);
      when(mockDatabaseService.getMessages(any)).thenAnswer((_) async => []);
      when(mockP2PService.getMessageHistoryForDevice(any, any)).thenReturn([]);
      when(mockP2PService.getMessageStream(any)).thenAnswer((_) => Stream.empty());
      
      await viewModel.initialize(device);

      // Setup broadcastEmergencyAlert stub
      when(mockP2PService.broadcastEmergencyAlert(any)).thenAnswer((_) async {});

      // Act
      final result = await viewModel.sendQuickMessage('SOS', isEmergency: true);

      // Assert
      expect(result, isTrue);
      verify(mockP2PService.broadcastEmergencyAlert('SOS')).called(1);
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
      
      // Stub connectedDevices to include our device
      when(mockP2PService.connectedDevices).thenReturn([device]);
      
      // Other stubs for initialize
      when(mockDatabaseService.getMessages(any)).thenAnswer((_) async => []);
      when(mockP2PService.getMessageHistoryForDevice(any, any)).thenReturn([]);
      when(mockP2PService.getMessageStream(any)).thenAnswer((_) => Stream.empty());
      
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

      // Stub database to throw error
      when(mockP2PService.connectedDevices).thenReturn([device]);
      when(mockDatabaseService.getMessages(any)).thenThrow(Exception('Database error'));

      // Act
      await viewModel.initialize(device);

      // Assert
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.isLoading, isFalse);
    });
  });
}

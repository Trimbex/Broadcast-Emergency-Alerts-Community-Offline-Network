import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_application/viewmodels/network_dashboard_viewmodel.dart';
import 'package:flutter_application/models/device_model.dart';
import '../mocks/mock_services.mocks.dart';

void main() {
  group('NetworkDashboardViewModel Tests', () {
    late MockP2PService mockP2PService;
    late MockDatabaseService mockDatabaseService;
    late NetworkDashboardViewModel viewModel;

    setUp(() {
      mockP2PService = MockP2PService();
      mockDatabaseService = MockDatabaseService();
      
      // Default stubs
      when(mockP2PService.isAdvertising).thenReturn(false);
      when(mockP2PService.isDiscovering).thenReturn(false);
      when(mockP2PService.connectedDevices).thenReturn([]);
      
      viewModel = NetworkDashboardViewModel(
        p2pService: mockP2PService,
        databaseService: mockDatabaseService,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('Initial state should be initializing', () {
      expect(viewModel.networkState, equals(NetworkState.initializing));
      expect(viewModel.isRefreshing, isFalse);
      expect(viewModel.connectedDevices, isEmpty);
    });

    test('Initialize should start network services', () async {
      // Arrange
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => {'name': 'Test User'});
      when(mockP2PService.initialize(any)).thenAnswer((_) async => true);
      when(mockP2PService.startAdvertising()).thenAnswer((_) async => true);
      when(mockP2PService.startDiscovery()).thenAnswer((_) async => true);
      
      // Update state getters after calls (if logic checks them again)
      // Usually viewmodels might re-check state, but let's assume it relies on return values first.
      
      // Act
      await viewModel.initialize(mode: 'join');

      // Assert
      expect(viewModel.mode, equals('join'));
      verify(mockP2PService.initialize(any)).called(1);
      verify(mockP2PService.startAdvertising()).called(1);
      verify(mockP2PService.startDiscovery()).called(1);
    });

    test('Successful initialization should set state to searching', () async {
      // Arrange
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => {'name': 'Test User'});
      when(mockP2PService.initialize(any)).thenAnswer((_) async => true);
      when(mockP2PService.startAdvertising()).thenAnswer((_) async => true);
      when(mockP2PService.startDiscovery()).thenAnswer((_) async => true);

      // Act
      await viewModel.initialize();

      // Assert
      expect(viewModel.networkState, equals(NetworkState.searching));
      expect(viewModel.errorMessage, isNull);
    });

    test('Failed initialization should set error state', () async {
      // Arrange
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => {'name': 'Test User'});
      when(mockP2PService.initialize(any)).thenAnswer((_) async => false); // Fail init

      // Act
      await viewModel.initialize();

      // Assert
      expect(viewModel.networkState, equals(NetworkState.error));
      expect(viewModel.errorMessage, isNotNull);
    });

    test('Refresh network should restart discovery', () async {
      // Arrange
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => {'name': 'Test User'});
      when(mockP2PService.initialize(any)).thenAnswer((_) async => true);
      when(mockP2PService.startAdvertising()).thenAnswer((_) async => true);
      when(mockP2PService.startDiscovery()).thenAnswer((_) async => true);
      
      await viewModel.initialize();
      
      when(mockP2PService.stopDiscovery()).thenAnswer((_) async {});

      // Act
      await viewModel.refreshNetwork();

      // Assert
      expect(viewModel.isRefreshing, isFalse);
      verify(mockP2PService.stopDiscovery()).called(1);
      verify(mockP2PService.startDiscovery()).called(2); // 1 from init, 1 from refresh
    });

    test('Connected devices should reflect P2P service state', () async {
      // Arrange
      final device = DeviceModel(
        id: 'device1',
        name: 'Test Device',
        status: 'Connected',
        distance: '5m',
        batteryLevel: 80,
        endpointId: 'endpoint1',
      );
      
      // Setup methods
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => {'name': 'Test User'});
      when(mockP2PService.initialize(any)).thenAnswer((_) async => true);
      when(mockP2PService.startAdvertising()).thenAnswer((_) async => true);
      when(mockP2PService.startDiscovery()).thenAnswer((_) async => true);
      
      // When connectedDevices is accessed, return list with device
      when(mockP2PService.connectedDevices).thenReturn([device]);
      
      await viewModel.initialize();

      // Assert
      expect(viewModel.connectedDevices.length, equals(1));
      expect(viewModel.connectedDevices.first.name, equals('Test Device'));
    });

    test('Broadcast emergency should call P2P service', () async {
      // Arrange
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => {'name': 'Test User'});
      when(mockP2PService.initialize(any)).thenAnswer((_) async => true);
      when(mockP2PService.startAdvertising()).thenAnswer((_) async => true);
      when(mockP2PService.startDiscovery()).thenAnswer((_) async => true);
      
      await viewModel.initialize();
      
      when(mockP2PService.broadcastEmergencyAlert(any)).thenAnswer((_) async {});

      // Act
      await viewModel.broadcastEmergency('Help needed!');

      // Assert
      verify(mockP2PService.broadcastEmergencyAlert('Help needed!')).called(1);
    });

    test('isNetworkActive should be true when advertising and discovering', () async {
      // Arrange
      when(mockDatabaseService.getUserProfile()).thenAnswer((_) async => {'name': 'Test User'});
      when(mockP2PService.initialize(any)).thenAnswer((_) async => true);
      when(mockP2PService.startAdvertising()).thenAnswer((_) async => true);
      when(mockP2PService.startDiscovery()).thenAnswer((_) async => true);
      
      // Update mock state to return true
      when(mockP2PService.isAdvertising).thenReturn(true);
      when(mockP2PService.isDiscovering).thenReturn(true);

      await viewModel.initialize();

      // Assert
      expect(viewModel.isNetworkActive, isTrue);
    });
  });
}

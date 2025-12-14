import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/viewmodels/network_dashboard_viewmodel.dart';
import 'package:flutter_application/models/device_model.dart';
import '../mocks/mock_services.dart';

void main() {
  group('NetworkDashboardViewModel Tests', () {
    late MockP2PService mockP2PService;
    late MockDatabaseService mockDatabaseService;
    late NetworkDashboardViewModel viewModel;

    setUp(() {
      mockP2PService = MockP2PService();
      mockDatabaseService = MockDatabaseService();
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
      mockDatabaseService.setUserProfile({'name': 'Test User'});

      // Act
      await viewModel.initialize(mode: 'join');

      // Assert
      expect(viewModel.mode, equals('join'));
      expect(mockP2PService.isInitialized, isTrue);
      expect(mockP2PService.isAdvertising, isTrue);
      expect(mockP2PService.isDiscovering, isTrue);
    });

    test('Successful initialization should set state to searching', () async {
      // Arrange
      mockDatabaseService.setUserProfile({'name': 'Test User'});

      // Act
      await viewModel.initialize();

      // Assert
      expect(viewModel.networkState, equals(NetworkState.searching));
      expect(viewModel.errorMessage, isNull);
    });

    test('Failed initialization should set error state', () async {
      // Arrange
      mockP2PService.initializeShouldFail = true;
      mockDatabaseService.setUserProfile({'name': 'Test User'});

      // Act
      await viewModel.initialize();

      // Assert
      expect(viewModel.networkState, equals(NetworkState.error));
      expect(viewModel.errorMessage, isNotNull);
    });

    test('Refresh network should restart discovery', () async {
      // Arrange
      mockDatabaseService.setUserProfile({'name': 'Test User'});
      await viewModel.initialize();

      // Act
      await viewModel.refreshNetwork();

      // Assert
      expect(viewModel.isRefreshing, isFalse);
      expect(mockP2PService.discoveryRestartCount, equals(1));
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
      mockP2PService.addConnectedDevice(device);
      mockDatabaseService.setUserProfile({'name': 'Test User'});
      await viewModel.initialize();

      // Assert
      expect(viewModel.connectedDevices.length, equals(1));
      expect(viewModel.connectedDevices.first.name, equals('Test Device'));
    });

    test('Broadcast emergency should call P2P service', () async {
      // Arrange
      mockDatabaseService.setUserProfile({'name': 'Test User'});
      await viewModel.initialize();

      // Act
      await viewModel.broadcastEmergency('Help needed!');

      // Assert
      expect(mockP2PService.lastEmergencyAlert, equals('Help needed!'));
    });

    test('isNetworkActive should be true when advertising and discovering', () async {
      // Arrange
      mockDatabaseService.setUserProfile({'name': 'Test User'});
      await viewModel.initialize();

      // Assert
      expect(viewModel.isNetworkActive, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_application/viewmodels/resource_sharing_viewmodel.dart';
import 'package:flutter_application/models/resource_model.dart';
import '../mocks/mock_services.mocks.dart';

void main() {
  group('ResourceSharingViewModel Tests', () {
    late MockP2PService mockP2PService;
    late ResourceSharingViewModel viewModel;

    setUp(() {
      mockP2PService = MockP2PService();
      
      // Default stubs
      when(mockP2PService.networkResources).thenReturn([]);
      when(mockP2PService.localDeviceId).thenReturn('device1');
      when(mockP2PService.resourceStream).thenAnswer((_) => Stream.empty());
      when(mockP2PService.resourceRequestStream).thenAnswer((_) => Stream.empty());
      
      viewModel = ResourceSharingViewModel(p2pService: mockP2PService);
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('Initial state should have All category selected', () {
      expect(viewModel.selectedCategory, equals('All'));
      expect(viewModel.filteredResources, isEmpty);
    });

    test('Set category should update selected category', () {
      // Act
      viewModel.setCategory('Medical');

      // Assert
      expect(viewModel.selectedCategory, equals('Medical'));
    });

    test('Filtered resources should show all when category is All', () {
      // Arrange
      final resource1 = ResourceModel(
        id: '1',
        name: 'Bandages',
        category: 'Medical',
        quantity: 10,
        location: 'Shelter A',
        provider: 'John',
        status: 'Available',
        deviceId: 'device2',
      );
      final resource2 = ResourceModel(
        id: '2',
        name: 'Water',
        category: 'Water',
        quantity: 20,
        location: 'Shelter B',
        provider: 'Jane',
        status: 'Available',
        deviceId: 'device3',
      );
      
      when(mockP2PService.networkResources).thenReturn([resource1, resource2]);

      // Act
      viewModel.setCategory('All');

      // Assert
      expect(viewModel.filteredResources.length, equals(2));
    });

    test('Filtered resources should show only selected category', () {
      // Arrange
      final resource1 = ResourceModel(
        id: '1',
        name: 'Bandages',
        category: 'Medical',
        quantity: 10,
        location: 'Shelter A',
        provider: 'John',
        status: 'Available',
        deviceId: 'device2',
      );
      final resource2 = ResourceModel(
        id: '2',
        name: 'Water',
        category: 'Water',
        quantity: 20,
        location: 'Shelter B',
        provider: 'Jane',
        status: 'Available',
        deviceId: 'device3',
      );
      
      when(mockP2PService.networkResources).thenReturn([resource1, resource2]);

      // Act
      viewModel.setCategory('Medical');

      // Assert
      expect(viewModel.filteredResources.length, equals(1));
      expect(viewModel.filteredResources.first.name, equals('Bandages'));
    });

    test('Add resource should broadcast to network', () async {
      // Arrange
      final resource = ResourceModel(
        id: '1',
        name: 'First Aid Kit',
        category: 'Medical',
        quantity: 5,
        location: 'Shelter A',
        provider: 'Test User',
        status: 'Available',
      );
      
      when(mockP2PService.broadcastResource(any)).thenAnswer((_) async {});

      // Act
      await viewModel.addResource(resource);

      // Assert
      verify(mockP2PService.broadcastResource(resource)).called(1);
    });

    test('Available count should count non-unavailable resources', () {
      // Arrange
      final resource1 = ResourceModel(
        id: '1',
        name: 'Bandages',
        category: 'Medical',
        quantity: 10,
        location: 'Shelter A',
        provider: 'John',
        status: 'Available',
        deviceId: 'device2',
      );
      final resource2 = ResourceModel(
        id: '2',
        name: 'Water',
        category: 'Water',
        quantity: 20,
        location: 'Shelter B',
        provider: 'Jane',
        status: 'Unavailable',
        deviceId: 'device3',
      );
      
      when(mockP2PService.networkResources).thenReturn([resource1, resource2]);

      // Assert
      expect(viewModel.availableCount, equals(1));
    });

    test('Request resource should call P2P service', () async {
      // Arrange
      const resourceId = 'resource1';
      const deviceId = 'device1';
      const endpointId = 'endpoint1';
      const quantity = 5;
      const requesterName = 'Test User';
      
      when(mockP2PService.requestSpecificResource(any, any, any, any)).thenAnswer((_) async {});

      // Act
      await viewModel.requestResource(
        resourceId,
        deviceId,
        endpointId,
        quantity,
        requesterName,
      );

      // Assert
      verify(mockP2PService.requestSpecificResource(
        endpointId,
        resourceId,
        quantity,
        requesterName,
      )).called(1);
    });
  });
}

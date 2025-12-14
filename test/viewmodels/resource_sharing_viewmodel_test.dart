import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/viewmodels/resource_sharing_viewmodel.dart';
import 'package:flutter_application/models/resource_model.dart';
import '../mocks/mock_services.dart';

void main() {
  group('ResourceSharingViewModel Tests', () {
    late MockP2PService mockP2PService;
    late ResourceSharingViewModel viewModel;

    setUp(() {
      mockP2PService = MockP2PService();
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
      );
      final resource2 = ResourceModel(
        id: '2',
        name: 'Water',
        category: 'Water',
        quantity: 20,
        location: 'Shelter B',
        provider: 'Jane',
        status: 'Available',
      );
      mockP2PService.addResource(resource1);
      mockP2PService.addResource(resource2);

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
      );
      final resource2 = ResourceModel(
        id: '2',
        name: 'Water',
        category: 'Water',
        quantity: 20,
        location: 'Shelter B',
        provider: 'Jane',
        status: 'Available',
      );
      mockP2PService.addResource(resource1);
      mockP2PService.addResource(resource2);

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

      // Act
      await viewModel.addResource(resource);

      // Assert
      expect(mockP2PService.broadcastedResources.length, equals(1));
      expect(mockP2PService.broadcastedResources.first.name, equals('First Aid Kit'));
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
      );
      final resource2 = ResourceModel(
        id: '2',
        name: 'Water',
        category: 'Water',
        quantity: 20,
        location: 'Shelter B',
        provider: 'Jane',
        status: 'Unavailable',
      );
      mockP2PService.addResource(resource1);
      mockP2PService.addResource(resource2);

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

      // Act
      await viewModel.requestResource(
        resourceId,
        deviceId,
        endpointId,
        quantity,
        requesterName,
      );

      // Assert
      expect(mockP2PService.lastResourceRequest, isNotNull);
      expect(mockP2PService.lastResourceRequest!['resourceId'], equals(resourceId));
    });
  });
}

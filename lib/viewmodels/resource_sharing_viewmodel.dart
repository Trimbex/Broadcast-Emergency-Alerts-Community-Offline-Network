import 'dart:async';
import '../models/resource_model.dart';
import '../services/p2p_service.dart';
import 'base_viewmodel.dart';

/// ViewModel for ResourceSharingPage
/// Manages resources, filtering, and resource requests
class ResourceSharingViewModel extends BaseViewModel {
  final P2PService _p2pService;

  ResourceSharingViewModel({required P2PService p2pService})
      : _p2pService = p2pService;

  // UI State
  String _selectedCategory = 'All';
  StreamSubscription<ResourceModel>? _resourceSubscription;
  StreamSubscription<Map<String, dynamic>>? _resourceRequestSubscription;
  final List<String> categories = [
    'All',
    'Medical',
    'Food',
    'Shelter',
    'Water',
    'Other'
  ];

  // Getters
  String get selectedCategory => _selectedCategory;
  List<ResourceModel> get allResources => _p2pService.networkResources;

  /// Get filtered resources based on selected category
  List<ResourceModel> get filteredResources {
    // Remove duplicates (same id and deviceId)
    final uniqueResources = <String, ResourceModel>{};
    for (var resource in allResources) {
      final key = '${resource.id}_${resource.deviceId ?? "unknown"}';
      if (!uniqueResources.containsKey(key)) {
        uniqueResources[key] = resource;
      }
    }

    if (_selectedCategory == 'All') {
      return uniqueResources.values.toList();
    }

    return uniqueResources.values
        .where((r) => r.category == _selectedCategory)
        .toList();
  }

  /// Get available resources count
  int get availableCount =>
      filteredResources.where((r) => r.status != 'Unavailable').length;

  /// Get shared resources count (resources from this device)
  int get sharedCount {
    final localDeviceId = _p2pService.localDeviceId;
    return filteredResources
        .where((r) => r.deviceId == localDeviceId || r.deviceId == null)
        .length;
  }

  /// Initialize resource page
  void initialize() {
    // Listen to resource updates from network
    _resourceSubscription = _p2pService.resourceStream.listen(
      (resource) {
        safeNotifyListeners();
      },
    );

    // Listen to resource requests
    _resourceRequestSubscription = _p2pService.resourceRequestStream.listen(
      (requestData) {
        // This will be handled by the UI to show dialog
        safeNotifyListeners();
      },
    );
  }

  /// Change selected category filter
  void setCategory(String category) {
    _selectedCategory = category;
    safeNotifyListeners();
  }

  /// Add a new resource
  Future<void> addResource(ResourceModel resource) async {
    try {
      await _p2pService.broadcastResource(resource);
      clearError();
      safeNotifyListeners();
    } catch (e) {
      setError('Failed to add resource: $e');
    }
  }

  /// Delete a resource (removes from local cache)
  Future<void> deleteResource(String resourceId, String? deviceId) async {
    try {
      // Remove from network resources cache
      final key = '${resourceId}_${deviceId ?? "unknown"}';
      _p2pService.networkResources.removeWhere(
        (r) => '${r.id}_${r.deviceId ?? "unknown"}' == key,
      );
      clearError();
      safeNotifyListeners();
    } catch (e) {
      setError('Failed to delete resource: $e');
    }
  }

  /// Request a resource from another device
  Future<void> requestResource(
    String resourceId,
    String deviceId,
    String endpointId,
    int quantity,
    String requesterName,
  ) async {
    try {
      await _p2pService.requestSpecificResource(
        endpointId,
        resourceId,
        quantity,
        requesterName,
      );
      clearError();
    } catch (e) {
      setError('Failed to request resource: $e');
    }
  }

  /// Update resource status after approval
  Future<void> updateResourceStatus(
    String resourceId,
    int requestedQuantity,
    String requesterName,
  ) async {
    try {
      _p2pService.updateResourceAfterApproval(
        resourceId,
        requestedQuantity,
        requesterName,
      );
      clearError();
      safeNotifyListeners();
    } catch (e) {
      setError('Failed to update resource: $e');
    }
  }

  /// Get resource request stream
  Stream<Map<String, dynamic>> get resourceRequestStream =>
      _p2pService.resourceRequestStream;

  @override
  void dispose() {
    _resourceSubscription?.cancel();
    _resourceRequestSubscription?.cancel();
    super.dispose();
  }
}

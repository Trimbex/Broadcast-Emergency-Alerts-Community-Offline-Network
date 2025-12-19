import '../services/database_service.dart';
import '../models/device_model.dart';
import 'base_viewmodel.dart';

/// Network state enum
enum NetworkState {
  initializing,
  searching,
  connected,
  error,
}

/// ViewModel for NetworkDashboard
/// Manages network discovery, device connections, and network state
class NetworkDashboardViewModel extends BaseViewModel {
  final dynamic _p2pService;
  final dynamic _databaseService;

  NetworkDashboardViewModel({
    required dynamic p2pService,
    dynamic databaseService,
  })  : _p2pService = p2pService,
        _databaseService = databaseService ?? DatabaseService.instance;

  // UI State
  NetworkState _networkState = NetworkState.initializing;
  bool _isRefreshing = false;
  String? _mode;

  // Getters
  NetworkState get networkState => _networkState;
  bool get isRefreshing => _isRefreshing;
  String get mode => _mode ?? 'join';
  List<DeviceModel> get connectedDevices => _p2pService.connectedDevices;
  bool get isNetworkActive =>
      _p2pService.isAdvertising && _p2pService.isDiscovering;

  /// Initialize P2P network
  Future<void> initialize({String? mode}) async {
    _mode = mode;
    _networkState = NetworkState.initializing;
    safeNotifyListeners();

    try {
      // Get user name from database
      final userName = await _getUserName();

      // Initialize P2P service
      final success = await _p2pService.initialize(userName);

      if (!success) {
        _networkState = NetworkState.error;
        setError('Failed to initialize P2P network. Check permissions.');
        safeNotifyListeners();
        return;
      }

      // Start advertising and discovery
      final advertisingSuccess = await _p2pService.startAdvertising();
      final discoverySuccess = await _p2pService.startDiscovery();

      if (advertisingSuccess && discoverySuccess) {
        _networkState = NetworkState.searching;
        clearError();
      } else {
        _networkState = NetworkState.error;
        setError('Failed to start network services');
      }

      safeNotifyListeners();
    } catch (e) {
      _networkState = NetworkState.error;
      setError('Error: ${e.toString()}');
      safeNotifyListeners();
    }
  }

  /// Get user name from database
  Future<String> _getUserName() async {
    try {
      final userProfile = await _databaseService.getUserProfile();
      return userProfile?['name'] ??
          'User-${DateTime.now().millisecondsSinceEpoch % 10000}';
    } catch (e) {
      return 'User-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
  }

  /// Refresh network (restart discovery)
  Future<void> refreshNetwork() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    safeNotifyListeners();

    try {
      // Stop discovery
      await _p2pService.stopDiscovery();

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 500));

      // Restart discovery
      await _p2pService.startDiscovery();

      clearError();
    } catch (e) {
      setError('Failed to refresh: $e');
    } finally {
      _isRefreshing = false;
      safeNotifyListeners();
    }
  }

  /// Stop network services
  Future<void> stopNetwork() async {
    try {
      await _p2pService.stopAdvertising();
      await _p2pService.stopDiscovery();
      _networkState = NetworkState.initializing;
      safeNotifyListeners();
    } catch (e) {
      setError('Failed to stop network: $e');
    }
  }

  /// Broadcast emergency alert
  Future<void> broadcastEmergency(String message) async {
    try {
      await _p2pService.broadcastEmergencyAlert(message);
      clearError();
    } catch (e) {
      setError('Failed to broadcast emergency: $e');
    }
  }

  /// Broadcast predefined message
  Future<void> broadcastMessage(String message) async {
    try {
      // Broadcast to all connected devices
      for (final device in _p2pService.connectedDevices) {
        if (device.endpointId != null) {
          await _p2pService.sendMessage(device.endpointId!, message);
        }
      }
      clearError();
    } catch (e) {
      setError('Failed to broadcast message: $e');
    }
  }

  /// Disconnect from a device
  Future<void> disconnectDevice(String endpointId) async {
    try {
      // Currently P2PService doesn't expose individual disconnect
      // This would need to be added to the service
      clearError();
    } catch (e) {
      setError('Failed to disconnect: $e');
    }
  }

  /// Update network state based on service changes
  void updateNetworkState() {
    if (isNetworkActive) {
      if (_networkState != NetworkState.searching &&
          _networkState != NetworkState.connected) {
        _networkState = NetworkState.searching;
        safeNotifyListeners();
      }
    } else if (_networkState == NetworkState.searching) {
      _networkState = NetworkState.error;
      setError('Network connection lost');
      safeNotifyListeners();
    }
  }
}

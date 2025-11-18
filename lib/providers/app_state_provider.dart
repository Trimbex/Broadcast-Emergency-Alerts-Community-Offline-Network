import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile_model.dart';
import '../models/device_model.dart';
import '../models/resource_model.dart';
import '../models/network_activity_model.dart';
import '../services/database_helper.dart';
import '../services/p2p_service.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

class AppStateProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final P2PService _p2pService = P2PService.instance;
  final Uuid _uuid = const Uuid();

  // State variables
  UserProfileModel? _currentUser;
  List<DeviceModel> _connectedDevices = [];
  List<ResourceModel> _resources = [];
  List<NetworkActivityModel> _networkActivities = [];
  List<DiscoveredPeers> _discoveredPeers = [];
  bool _isDiscovering = false;
  bool _isP2PInitialized = false;
  WifiP2PInfo? _connectionInfo;

  // Getters
  UserProfileModel? get currentUser => _currentUser;
  List<DeviceModel> get connectedDevices => _connectedDevices;
  List<ResourceModel> get resources => _resources;
  List<NetworkActivityModel> get networkActivities => _networkActivities;
  List<DiscoveredPeers> get discoveredPeers => _discoveredPeers;
  bool get isDiscovering => _isDiscovering;
  bool get isP2PInitialized => _isP2PInitialized;
  WifiP2PInfo? get connectionInfo => _connectionInfo;
  bool get isConnected => _connectionInfo?.isConnected ?? false;
  String get connectionStatus {
    if (_connectionInfo == null) return 'Not Connected';
    if (_connectionInfo!.isConnected) {
      return _connectionInfo!.isGroupOwner ? 'Host' : 'Connected';
    }
    return 'Not Connected';
  }

  // Initialize app state
  Future<void> initialize() async {
    await _loadUserProfile();
    await _loadDevices();
    await _loadResources();
    await _loadNetworkActivities();
    await _initializeP2P();
  }

  // Load user profile from database
  Future<void> _loadUserProfile() async {
    try {
      _currentUser = await _dbHelper.getCurrentUserProfile();
      notifyListeners();
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Load devices from database
  Future<void> _loadDevices() async {
    try {
      _connectedDevices = await _dbHelper.getAllDevices();
      notifyListeners();
    } catch (e) {
      print('Error loading devices: $e');
    }
  }

  // Load resources from database
  Future<void> _loadResources() async {
    try {
      _resources = await _dbHelper.getAllResources();
      notifyListeners();
    } catch (e) {
      print('Error loading resources: $e');
    }
  }

  // Load network activities from database
  Future<void> _loadNetworkActivities() async {
    try {
      _networkActivities = await _dbHelper.getAllActivities();
      notifyListeners();
    } catch (e) {
      print('Error loading network activities: $e');
    }
  }

  // Initialize P2P service
  Future<void> _initializeP2P() async {
    try {
      _isP2PInitialized = await _p2pService.initialize();
      
      if (_isP2PInitialized) {
        // Listen to discovered peers
        _p2pService.devicesStream.listen((peers) {
          _discoveredPeers = peers;
          notifyListeners();
        });

        // Listen to connection status
        _p2pService.connectionStatusStream.listen((info) {
          _connectionInfo = info;
          notifyListeners();
        });

        // Listen to received data
        _p2pService.receivedDataStream.listen(_handleReceivedData);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error initializing P2P: $e');
    }
  }

  // Handle received P2P data
  void _handleReceivedData(Map<String, dynamic> data) async {
    try {
      final type = data['type'] as String;
      final action = data['action'] as String;
      final payload = data['payload'] as Map<String, dynamic>;

      switch (type) {
        case 'resource':
          if (action == 'share') {
            final resource = ResourceModel.fromJson(payload);
            await addResource(resource);
          } else if (action == 'request') {
            // Handle resource request
            print('Resource request received: ${payload['resourceName']}');
          }
          break;
        case 'device':
          if (action == 'info') {
            final device = DeviceModel.fromJson(payload);
            await addDevice(device);
          }
          break;
      }
    } catch (e) {
      print('Error handling received data: $e');
    }
  }

  // User Profile Operations
  Future<void> createUserProfile(UserProfileModel profile) async {
    try {
      await _dbHelper.insertUserProfile(profile);
      _currentUser = profile;
      notifyListeners();
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(UserProfileModel profile) async {
    try {
      await _dbHelper.updateUserProfile(profile);
      _currentUser = profile;
      notifyListeners();
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Device Operations
  Future<void> addDevice(DeviceModel device) async {
    try {
      await _dbHelper.insertDevice(device);
      await _loadDevices();
      
      // Log network activity
      await _addNetworkActivity(NetworkActivityModel(
        id: _uuid.v4(),
        activityType: 'connection',
        deviceId: device.id,
        deviceName: device.name,
        details: 'Device connected',
      ));
    } catch (e) {
      print('Error adding device: $e');
    }
  }

  Future<void> updateDevice(DeviceModel device) async {
    try {
      await _dbHelper.updateDevice(device);
      await _loadDevices();
    } catch (e) {
      print('Error updating device: $e');
    }
  }

  Future<void> removeDevice(String deviceId) async {
    try {
      final device = _connectedDevices.firstWhere((d) => d.id == deviceId);
      await _dbHelper.deleteDevice(deviceId);
      await _loadDevices();
      
      // Log network activity
      await _addNetworkActivity(NetworkActivityModel(
        id: _uuid.v4(),
        activityType: 'disconnection',
        deviceId: device.id,
        deviceName: device.name,
        details: 'Device disconnected',
      ));
    } catch (e) {
      print('Error removing device: $e');
    }
  }

  // Resource Operations
  Future<void> addResource(ResourceModel resource) async {
    try {
      await _dbHelper.insertResource(resource);
      await _loadResources();
      
      // Log network activity
      if (resource.providerId != null) {
        await _addNetworkActivity(NetworkActivityModel(
          id: _uuid.v4(),
          activityType: 'resource_shared',
          deviceId: resource.providerId!,
          deviceName: resource.provider,
          details: 'Shared ${resource.name}',
        ));
      }
    } catch (e) {
      print('Error adding resource: $e');
    }
  }

  Future<void> updateResource(ResourceModel resource) async {
    try {
      await _dbHelper.updateResource(resource);
      await _loadResources();
    } catch (e) {
      print('Error updating resource: $e');
    }
  }

  Future<void> deleteResource(String resourceId) async {
    try {
      await _dbHelper.deleteResource(resourceId);
      await _loadResources();
    } catch (e) {
      print('Error deleting resource: $e');
    }
  }

  // Network Activity Operations
  Future<void> _addNetworkActivity(NetworkActivityModel activity) async {
    try {
      await _dbHelper.insertActivity(activity);
      await _loadNetworkActivities();
    } catch (e) {
      print('Error adding network activity: $e');
    }
  }

  // P2P Operations
  Future<void> startDiscovery() async {
    try {
      _isDiscovering = await _p2pService.startDiscovery();
      notifyListeners();
    } catch (e) {
      print('Error starting discovery: $e');
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _p2pService.stopDiscovery();
      _isDiscovering = false;
      notifyListeners();
    } catch (e) {
      print('Error stopping discovery: $e');
    }
  }

  Future<bool> connectToPeer(String deviceAddress, String deviceName) async {
    try {
      final success = await _p2pService.connectToPeer(deviceAddress);
      
      if (success) {
        // Add device to database
        final device = DeviceModel(
          id: deviceAddress,
          name: deviceName,
          status: 'Connected',
          distance: 'Direct',
          batteryLevel: 100,
          isConnected: true,
        );
        await addDevice(device);
      }
      
      return success;
    } catch (e) {
      print('Error connecting to peer: $e');
      return false;
    }
  }

  Future<void> disconnectFromPeer() async {
    try {
      await _p2pService.disconnect();
      await _dbHelper.disconnectAllDevices();
      await _loadDevices();
      notifyListeners();
    } catch (e) {
      print('Error disconnecting from peer: $e');
    }
  }

  Future<void> shareResource(ResourceModel resource) async {
    try {
      await _p2pService.sendResource(resource);
      await _addNetworkActivity(NetworkActivityModel(
        id: _uuid.v4(),
        activityType: 'resource_shared',
        deviceId: _currentUser?.id ?? 'unknown',
        deviceName: _currentUser?.name ?? 'You',
        details: 'Shared ${resource.name} via P2P',
      ));
    } catch (e) {
      print('Error sharing resource: $e');
    }
  }

  Future<void> requestResource(ResourceModel resource) async {
    try {
      await _p2pService.sendResourceRequest(resource.id, resource.name);
      await _addNetworkActivity(NetworkActivityModel(
        id: _uuid.v4(),
        activityType: 'resource_requested',
        deviceId: resource.providerId ?? 'unknown',
        deviceName: resource.provider,
        details: 'Requested ${resource.name}',
      ));
    } catch (e) {
      print('Error requesting resource: $e');
    }
  }

  // Clean up
  @override
  void dispose() {
    _p2pService.dispose();
    super.dispose();
  }
}


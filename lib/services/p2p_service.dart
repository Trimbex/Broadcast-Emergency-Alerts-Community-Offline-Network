import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:battery_plus/battery_plus.dart';
import '../models/device_model.dart';
import '../models/message_model.dart';
import '../models/resource_model.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
/// P2P Communication Service using Nearby Connections API
/// 
/// This service handles:
/// - Peer discovery and connection management
/// - Message broadcasting and receiving
/// - Connection state management
/// - Automatic reconnection
class P2PService extends ChangeNotifier {
  static final P2PService _instance = P2PService._internal();
  factory P2PService() => _instance;
  P2PService._internal();

  // Service configuration
  static const String SERVICE_ID = 'com.beacon.emergency';
  static const Strategy STRATEGY = Strategy.P2P_CLUSTER; // Multi-device mesh
  
  // Current user info
  String? _localDeviceId;
  String? _localDeviceName;
  
  // Connected devices
  final Map<String, DeviceModel> _connectedDevices = {};
  final Map<String, StreamController<MessageModel>> _messageStreams = {};

  //mesasge history cashe 
  final Map<String, List<MessageModel>> _messageHistory = {};

  // Resource cache - stores all resources from all devices
  final Map<String, ResourceModel> _networkResources = {}; // Key: resourceId_deviceId
  final StreamController<ResourceModel> _resourceStreamController = StreamController<ResourceModel>.broadcast();

  
  // Connection state
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  
  // Battery monitoring
  final Battery _battery = Battery();
  int _batteryLevel = 100;

  // Getters
  List<DeviceModel> get connectedDevices => _connectedDevices.values.toList();
  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;
  String? get localDeviceId => _localDeviceId;
  String? get localDeviceName => _localDeviceName;
  int get batteryLevel => _batteryLevel;
  List<ResourceModel> get networkResources => _networkResources.values.toList();
  Stream<ResourceModel> get resourceStream => _resourceStreamController.stream;

  /// Initialize the P2P service
  Future<bool> initialize(String userName) async {
    _localDeviceName = userName;
    _localDeviceId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Request permissions
    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      debugPrint('❌ P2P: Permissions denied');
      return false;
    }

    // Start battery monitoring
    _startBatteryMonitoring();
    
    debugPrint('✅ P2P: Initialized for user: $userName');
    return true;
  }

  /// Request necessary permissions for P2P communication

Future<bool> _requestPermissions() async {
  List<Permission> permissions = [
    Permission.bluetooth,
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.location,
    Permission.locationWhenInUse,
  ];

  if (Platform.isAndroid) {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // Request NEARBY_WIFI_DEVICES only on Android 13+ (SDK 33+)
    if (sdkInt >= 33) {
      permissions.add(Permission.nearbyWifiDevices);
    }
  }

  Map<Permission, PermissionStatus> statuses = await permissions.request();

  bool allGranted = statuses.values.every(
    (status) => status.isGranted || status.isLimited,
  );

  if (!allGranted) {
    debugPrint('❌ P2P: Some permissions denied: $statuses');
  }

  return allGranted;
}

  /// Start battery level monitoring
  void _startBatteryMonitoring() {
    _battery.batteryLevel.then((level) {
      _batteryLevel = level;
      notifyListeners();
    });
    
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      _battery.batteryLevel.then((level) {
        _batteryLevel = level;
        notifyListeners();
      });
    });
  }

  /// Start advertising this device as available
  Future<bool> startAdvertising() async {
    if (_localDeviceName == null || _localDeviceId == null) {
      debugPrint('❌ P2P: Not initialized');
      return false;
    }

    try {
      await Nearby().startAdvertising(
        _localDeviceName!,
        STRATEGY,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: SERVICE_ID,
      );

      _isAdvertising = true;
      notifyListeners();
      debugPrint('✅ P2P: Started advertising as $_localDeviceName');
      return true;
    } catch (e) {
      debugPrint('❌ P2P: Failed to start advertising: $e');
      return false;
    }
  }

  /// Start discovering nearby devices
  Future<bool> startDiscovery() async {
    if (_localDeviceName == null || _localDeviceId == null) {
      debugPrint('❌ P2P: Not initialized');
      return false;
    }

    try {
      await Nearby().startDiscovery(
        _localDeviceName!,
        STRATEGY,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: SERVICE_ID,
      );

      _isDiscovering = true;
      notifyListeners();
      debugPrint('✅ P2P: Started discovery');
      return true;
    } catch (e) {
      debugPrint('❌ P2P: Failed to start discovery: $e');
      return false;
    }
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    await Nearby().stopAdvertising();
    _isAdvertising = false;
    notifyListeners();
    debugPrint('🛑 P2P: Stopped advertising');
  }

  /// Stop discovery
  Future<void> stopDiscovery() async {
    await Nearby().stopDiscovery();
    _isDiscovering = false;
    notifyListeners();
    debugPrint('🛑 P2P: Stopped discovery');
  }

  /// Stop all P2P operations
  Future<void> stopAll() async {
    await Nearby().stopAllEndpoints();
    _isAdvertising = false;
    _isDiscovering = false;
    _connectedDevices.clear();
    notifyListeners();
    debugPrint('🛑 P2P: Stopped all operations');
  }

  /// Callback when a nearby device is found
  void _onEndpointFound(String endpointId, String endpointName, String serviceId) {
    debugPrint('📡 P2P: Found device - ID: $endpointId, Name: $endpointName');
    
    // Automatically request connection
    Nearby().requestConnection(
      _localDeviceName!,
      endpointId,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    );
  }

  /// Callback when a device is lost
  void _onEndpointLost(String? endpointId) {
    debugPrint('📡 P2P: Lost device - ID: $endpointId');
    if (endpointId != null) {
      _connectedDevices.remove(endpointId);
      notifyListeners();
    }
  }

  /// Callback when connection is initiated
  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    debugPrint('🔗 P2P: Connection initiated with ${info.endpointName}');
    
    // Auto-accept all connections in emergency scenarios
    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (endpointId, payload) => _onPayloadReceived(endpointId, payload),
      onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {
        debugPrint('📦 P2P: Payload transfer update from $endpointId');
      },
    );
  }

  /// Callback when connection result is received
  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      debugPrint('✅ P2P: Connected to $endpointId');
      
      // Add device to connected list
      _connectedDevices[endpointId] = DeviceModel(
        id: endpointId,
        name: 'User-${endpointId.substring(0, 4)}',
        status: 'Active',
        distance: 'Nearby',
        batteryLevel: 100, // Will be updated via messages
        endpointId: endpointId,
      );
      
      // Create message stream for this device
      _messageStreams[endpointId] = StreamController<MessageModel>.broadcast();
      
      notifyListeners();
      
      // Send initial handshake
      _sendHandshake(endpointId);
      
      // Note: Resources are now requested manually by user (on-demand)
    } else {
      debugPrint('❌ P2P: Failed to connect to $endpointId: $status');
    }
  }

  /// Callback when device disconnects
  void _onDisconnected(String endpointId) {
    debugPrint('🔌 P2P: Disconnected from $endpointId');
    _connectedDevices.remove(endpointId);
    _messageStreams[endpointId]?.close();
    _messageStreams.remove(endpointId);
    
    // Remove resources from disconnected device
    _networkResources.removeWhere((key, resource) => resource.deviceId == endpointId);
    notifyListeners();
  }

  /// Send initial handshake with device info
  void _sendHandshake(String endpointId) {
    final handshake = {
      'type': 'handshake',
      'deviceId': _localDeviceId,
      'deviceName': _localDeviceName,
      'batteryLevel': _batteryLevel,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendData(endpointId, handshake);
  }

  /// Send data to a specific device
  Future<void> _sendData(String endpointId, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      await Nearby().sendBytesPayload(
        endpointId,
        Uint8List.fromList(utf8.encode(jsonString)),
      );
      debugPrint('📤 P2P: Sent data to $endpointId: ${data['type']}');
    } catch (e) {
      debugPrint('❌ P2P: Failed to send data to $endpointId: $e');
    }
  }

  /// Broadcast data to all connected devices
  Future<void> broadcastData(Map<String, dynamic> data) async {
    for (final endpointId in _connectedDevices.keys) {
      await _sendData(endpointId, data);
    }
  }

  /// Send a chat message to a specific device
  Future<void> sendMessage(String endpointId, String message) async {
    final messageData = {
      'type': 'message',
      'senderId': _localDeviceId,
      'senderName': _localDeviceName,
      'text': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _sendData(endpointId, messageData);
  }

  /// Broadcast emergency alert to all devices
  Future<void> broadcastEmergencyAlert(String alertMessage) async {
    final alertData = {
      'type': 'emergency',
      'senderId': _localDeviceId,
      'senderName': _localDeviceName,
      'alert': alertMessage,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await broadcastData(alertData);
  }

  /// Handle received payload
  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      try {
        final jsonString = utf8.decode(payload.bytes!);
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        debugPrint('📥 P2P: Received data from $endpointId: ${data['type']}');
        
        _handleReceivedData(endpointId, data);
      } catch (e) {
        debugPrint('❌ P2P: Failed to parse payload: $e');
      }
    }
  }

  /// Handle different types of received data
  void _handleReceivedData(String endpointId, Map<String, dynamic> data) {
    final type = data['type'];
    
    switch (type) {
      case 'handshake':
        _handleHandshake(endpointId, data);
        break;
      case 'message':
        _handleMessage(endpointId, data);
        break;
      case 'emergency':
        _handleEmergencyAlert(endpointId, data);
        break;
      case 'resource':
        _handleResource(endpointId, data);
        break;
      case 'resource_request':
        _handleResourceRequest(endpointId, data);
        break;
      case 'resource_list':
        _handleResourceList(endpointId, data);
        break;
      default:
        debugPrint('⚠️ P2P: Unknown data type: $type');
    }
  }

  /// Handle handshake data
  void _handleHandshake(String endpointId, Map<String, dynamic> data) {
    // Update device info
    if (_connectedDevices.containsKey(endpointId)) {
      _connectedDevices[endpointId] = DeviceModel(
        id: data['deviceId'] ?? endpointId,
        name: data['deviceName'] ?? 'Unknown',
        status: 'Active',
        distance: 'Nearby',
        batteryLevel: data['batteryLevel'] ?? 100,
        endpointId: endpointId,
      );
      notifyListeners();
    }
  }

  /// Handle chat message
  void _handleMessage(String endpointId, Map<String, dynamic> data) {
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: data['senderId'] ?? endpointId,
      text: data['text'] ?? '',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      isMe: false,
      senderName: data['senderName'],
    );
    
     // 1. Store history
  _messageHistory.putIfAbsent(endpointId, () => []);
  _messageHistory[endpointId]!.add(message);

  // 2. Notify stream if chat open
  _messageStreams[endpointId]?.add(message);

  notifyListeners();
  }
  // load message history for a specific device
  List<MessageModel> getMessageHistory(String endpointId) {
  return _messageHistory[endpointId] ?? [];
}


  /// Handle emergency alert
  void _handleEmergencyAlert(String endpointId, Map<String, dynamic> data) {
    debugPrint('🚨 EMERGENCY ALERT from ${data['senderName']}: ${data['alert']}');
    
    // Create emergency message
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: data['senderId'] ?? endpointId,
      text: '🚨 EMERGENCY: ${data['alert']}',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      isMe: false,
      senderName: data['senderName'],
      isEmergency: true,
    );
    
    _messageStreams[endpointId]?.add(message);
  }

  /// Get message stream for a specific device
  Stream<MessageModel>? getMessageStream(String endpointId) {
    return _messageStreams[endpointId]?.stream;
  }

  /// Broadcast a resource to all connected devices
  Future<void> broadcastResource(ResourceModel resource) async {
    // Add deviceId to resource
    final resourceWithDevice = ResourceModel(
      id: resource.id,
      name: resource.name,
      category: resource.category,
      quantity: resource.quantity,
      location: resource.location,
      provider: resource.provider,
      status: resource.status,
      deviceId: _localDeviceId,
    );

    // Store locally
    final resourceKey = '${resource.id}_${_localDeviceId}';
    _networkResources[resourceKey] = resourceWithDevice;
    _resourceStreamController.add(resourceWithDevice);
    notifyListeners();

    // Broadcast to all connected devices
    final resourceData = {
      'type': 'resource',
      'resource': resourceWithDevice.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await broadcastData(resourceData);
    debugPrint('📦 P2P: Broadcasted resource: ${resource.name}');
  }

  /// Request all resources from a specific device (public method for manual requests)
  Future<void> requestResourcesFromDevice(String endpointId) async {
    final requestData = {
      'type': 'resource_request',
      'senderId': _localDeviceId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _sendData(endpointId, requestData);
    debugPrint('📥 P2P: Requested resources from $endpointId');
  }

  /// Send all local resources to a specific device
  Future<void> _sendResourceList(String endpointId, List<ResourceModel> resources) async {
    final resourceListData = {
      'type': 'resource_list',
      'senderId': _localDeviceId,
      'resources': resources.map((r) => r.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _sendData(endpointId, resourceListData);
    debugPrint('📤 P2P: Sent ${resources.length} resources to $endpointId');
  }

  /// Handle received resource
  void _handleResource(String endpointId, Map<String, dynamic> data) {
    try {
      final resourceJson = data['resource'] as Map<String, dynamic>;
      final resource = ResourceModel.fromJson(resourceJson);
      
      // Ensure deviceId is set
      final resourceWithDevice = ResourceModel(
        id: resource.id,
        name: resource.name,
        category: resource.category,
        quantity: resource.quantity,
        location: resource.location,
        provider: resource.provider,
        status: resource.status,
        deviceId: resource.deviceId ?? endpointId,
      );

      final resourceKey = '${resource.id}_${resourceWithDevice.deviceId}';
      
      // Only add if not already exists (avoid duplicates)
      if (!_networkResources.containsKey(resourceKey)) {
        _networkResources[resourceKey] = resourceWithDevice;
        _resourceStreamController.add(resourceWithDevice);
        notifyListeners();
        debugPrint('📦 P2P: Received resource: ${resource.name} from $endpointId');
      }
    } catch (e) {
      debugPrint('❌ P2P: Failed to parse resource: $e');
    }
  }

  /// Handle resource request
  void _handleResourceRequest(String endpointId, Map<String, dynamic> data) {
    // Send all local resources to the requesting device
    final localResources = _networkResources.values
        .where((r) => r.deviceId == _localDeviceId)
        .toList();
    
    if (localResources.isNotEmpty) {
      _sendResourceList(endpointId, localResources);
    }
  }

  /// Handle resource list (multiple resources at once)
  void _handleResourceList(String endpointId, Map<String, dynamic> data) {
    try {
      final resourcesJson = data['resources'] as List<dynamic>;
      
      for (var resourceJson in resourcesJson) {
        final resource = ResourceModel.fromJson(resourceJson as Map<String, dynamic>);
        
        // Ensure deviceId is set
        final resourceWithDevice = ResourceModel(
          id: resource.id,
          name: resource.name,
          category: resource.category,
          quantity: resource.quantity,
          location: resource.location,
          provider: resource.provider,
          status: resource.status,
          deviceId: resource.deviceId ?? endpointId,
        );

        final resourceKey = '${resource.id}_${resourceWithDevice.deviceId}';
        
        // Only add if not already exists
        if (!_networkResources.containsKey(resourceKey)) {
          _networkResources[resourceKey] = resourceWithDevice;
          _resourceStreamController.add(resourceWithDevice);
        }
      }
      
      notifyListeners();
      debugPrint('📦 P2P: Received ${resourcesJson.length} resources from $endpointId');
    } catch (e) {
      debugPrint('❌ P2P: Failed to parse resource list: $e');
    }
  }

  /// Get all resources from a specific device (by deviceId)
  List<ResourceModel> getResourcesByDevice(String deviceId) {
    return _networkResources.values
        .where((r) => r.deviceId == deviceId)
        .toList();
  }
  
  /// Get all resources from a device by endpointId
  /// This checks both endpointId and the device's actual ID (from handshake)
  List<ResourceModel> getResourcesByEndpointId(String endpointId) {
    // First, try to find the device to get its actual deviceId
    final device = _connectedDevices[endpointId];
    final deviceId = device?.id;
    
    // Resources might be stored with:
    // 1. endpointId as deviceId (if handshake not received yet)
    // 2. actual deviceId (from handshake)
    return _networkResources.values
        .where((r) => r.deviceId == endpointId || (deviceId != null && r.deviceId == deviceId))
        .toList();
  }

  /// Dispose resources
  @override
  void dispose() {
    stopAll();
    for (var stream in _messageStreams.values) {
      stream.close();
    }
    _messageStreams.clear();
    _resourceStreamController.close();
    super.dispose();
  }
}


import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:battery_plus/battery_plus.dart';
import '../models/device_model.dart';
import '../models/message_model.dart';

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
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ].request();

    // Check if all critical permissions are granted
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
    
    // Add to message stream
    _messageStreams[endpointId]?.add(message);
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

  /// Dispose resources
  @override
  void dispose() {
    stopAll();
    for (var stream in _messageStreams.values) {
      stream.close();
    }
    _messageStreams.clear();
    super.dispose();
  }
}


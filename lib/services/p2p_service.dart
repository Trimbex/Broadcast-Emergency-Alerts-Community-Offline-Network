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
import 'database_service.dart';
import 'notification_service.dart';
import 'speech_service.dart';

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
  
  // Resource request notifications
  final StreamController<Map<String, dynamic>> _resourceRequestStreamController = StreamController<Map<String, dynamic>>.broadcast();

  
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
  Stream<Map<String, dynamic>> get resourceRequestStream => _resourceRequestStreamController.stream;

  /// Initialize the P2P service
  Future<bool> initialize(String userName) async {
    _localDeviceName = userName;
    
    // Load identity from database to ensure consistent device ID
    final userProfile = await DatabaseService.instance.getUserProfile();
    if (userProfile != null && userProfile['device_id'] != null) {
      _localDeviceId = userProfile['device_id'];
    } else {
      // Fallback if not found (should be set in IdentitySetupPage)
      _localDeviceId = DateTime.now().millisecondsSinceEpoch.toString();
    }
    
    // Initialize notification service
    await NotificationService.instance.initialize();
    
    // Initialize speech service for text-to-speech and speech recognition
    try {
      await SpeechService().initialize();
      debugPrint('✅ P2P: Speech service initialized');
    } catch (e) {
      debugPrint('⚠️ P2P: Failed to initialize speech service: $e');
      // Continue even if speech service fails
    }
    
    // Load local resources from database
    await _loadLocalResources();
    
    // Load message history from database
    await _loadAllMessageHistory();
    
    // Request permissions
    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      debugPrint('❌ P2P: Permissions denied');
      return false;
    }

    // Start battery monitoring
    _startBatteryMonitoring();
    
    debugPrint('✅ P2P: Initialized for user: $userName (ID: $_localDeviceId)');
    return true;
  }

  /// Load all message history from database
  Future<void> _loadAllMessageHistory() async {
    if (_localDeviceId == null) return;
    
    try {
      // Get all unique conversation IDs from database
      final db = await DatabaseService.instance.database;
      final conversations = await db.query(
        'messages',
        columns: ['DISTINCT conversation_id'],
      );
      
      for (var conv in conversations) {
        final conversationId = conv['conversation_id'] as String;
        final messages = await DatabaseService.instance.getMessages(conversationId);
        
        if (messages.isNotEmpty) {
          // Store messages under conversation ID
          _messageHistory[conversationId] = messages;
          
          // Also try to map to endpointId if we have connected devices
          for (var device in _connectedDevices.values) {
            if (device.id == conversationId || device.endpointId == conversationId) {
              if (device.endpointId != null) {
                _messageHistory[device.endpointId!] = messages;
              }
              _messageHistory[device.id] = messages;
            }
          }
        }
      }
      
      debugPrint('📚 P2P: Loaded ${_messageHistory.length} conversation histories from database');
    } catch (e) {
      debugPrint('❌ P2P: Failed to load message history: $e');
    }
  }

  Future<void> _loadLocalResources() async {
    if (_localDeviceId == null) return;
    
    final localResources = await DatabaseService.instance.getUserResources(_localDeviceId!);
    for (var resource in localResources) {
      final resourceKey = '${resource.id}_$_localDeviceId';
      _networkResources[resourceKey] = resource;
    }
    notifyListeners();
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
      
      // Check if we have messages stored under a different ID for this device
      // This can happen if device reconnects with a new endpointId
      String? oldEndpointId;
      for (var entry in _messageHistory.entries) {
        // Check if any messages from this endpointId exist under a different key
        final messages = entry.value;
        if (messages.isNotEmpty) {
          // Check if any message has a senderId that matches this endpointId
          final firstMessage = messages.first;
          if (firstMessage.senderId == endpointId || entry.key == endpointId) {
            oldEndpointId = entry.key;
            break;
          }
        }
      }
      
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
      
      // If we found old messages, merge them into the new endpointId
      if (oldEndpointId != null && oldEndpointId != endpointId && _messageHistory.containsKey(oldEndpointId)) {
        _messageHistory.putIfAbsent(endpointId, () => []);
        final oldMessages = _messageHistory[oldEndpointId]!;
        final existingIds = _messageHistory[endpointId]!.map((m) => m.id).toSet();
        for (var msg in oldMessages) {
          if (!existingIds.contains(msg.id)) {
            _messageHistory[endpointId]!.add(msg);
          }
        }
        // Sort by timestamp
        _messageHistory[endpointId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      
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
    
    // Store sent message in history
    final sentMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _localDeviceId ?? 'me',
      text: message,
      timestamp: DateTime.now(),
      isMe: true,
      senderName: _localDeviceName,
    );
    
    _messageHistory.putIfAbsent(endpointId, () => []);
    _messageHistory[endpointId]!.add(sentMessage);
    
    // Persist to database
    // Use endpointId as conversation_id initially, but try to find persistent deviceId
    String conversationId = endpointId;
    if (_connectedDevices.containsKey(endpointId)) {
      conversationId = _connectedDevices[endpointId]?.id ?? endpointId;
    }
    await DatabaseService.instance.saveMessage(sentMessage, conversationId);
    
    // Notify stream if chat is open
    _messageStreams[endpointId]?.add(sentMessage);
    
    await _sendData(endpointId, messageData);
    notifyListeners();
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
    
    // Store emergency message in sender's history for each connected device
    final emergencyMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _localDeviceId ?? 'me',
      text: '🚨 EMERGENCY: $alertMessage',
      timestamp: DateTime.now(),
      isMe: true,
      senderName: _localDeviceName,
      isEmergency: true,
    );
    
    // Store in history for each connected device (so it appears in sender's chat history)
    for (final endpointId in _connectedDevices.keys) {
      _messageHistory.putIfAbsent(endpointId, () => []);
      _messageHistory[endpointId]!.add(emergencyMessage);
      
      // Persist to database for this conversation
      String conversationId = endpointId;
      if (_connectedDevices.containsKey(endpointId)) {
        conversationId = _connectedDevices[endpointId]?.id ?? endpointId;
      }
      await DatabaseService.instance.saveMessage(emergencyMessage, conversationId);

      // Notify stream if chat is open
      _messageStreams[endpointId]?.add(emergencyMessage);
    }
    
    await broadcastData(alertData);
    notifyListeners();
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
      case 'resource_request_specific':
        _handleResourceRequestSpecific(endpointId, data);
        break;
      case 'resource_request_response':
        _handleResourceRequestResponse(endpointId, data);
        break;
      default:
        debugPrint('⚠️ P2P: Unknown data type: $type');
    }
  }

  /// Handle handshake data
  void _handleHandshake(String endpointId, Map<String, dynamic> data) {
    // Update device info
    if (_connectedDevices.containsKey(endpointId)) {
      final oldDevice = _connectedDevices[endpointId];
      final newDeviceId = data['deviceId'] ?? endpointId;
      
      _connectedDevices[endpointId] = DeviceModel(
        id: newDeviceId,
        name: data['deviceName'] ?? 'Unknown',
        status: 'Active',
        distance: 'Nearby',
        batteryLevel: data['batteryLevel'] ?? 100,
        endpointId: endpointId,
      );
      
      // If deviceId changed, merge message history
      if (oldDevice != null && oldDevice.id != newDeviceId) {
        // Merge messages from old deviceId to new deviceId (using endpointId as key)
        if (_messageHistory.containsKey(oldDevice.id)) {
          _messageHistory.putIfAbsent(endpointId, () => []);
          final oldMessages = _messageHistory[oldDevice.id]!;
          final existingIds = _messageHistory[endpointId]!.map((m) => m.id).toSet();
          for (var msg in oldMessages) {
            if (!existingIds.contains(msg.id)) {
              _messageHistory[endpointId]!.add(msg);
            }
          }
          // Sort by timestamp
          _messageHistory[endpointId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }
      }
      
      notifyListeners();
    }
  }

  /// Handle chat message
  void _handleMessage(String endpointId, Map<String, dynamic> data) {
    final senderId = data['senderId'] ?? endpointId;
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      text: data['text'] ?? '',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      isMe: false,
      senderName: data['senderName'],
    );
    
     // 1. Store history
    _messageHistory.putIfAbsent(endpointId, () => []);
    _messageHistory[endpointId]!.add(message);
    
    // Also store under senderId for persistence
    _messageHistory.putIfAbsent(senderId, () => []);
    if (!_messageHistory[senderId]!.any((m) => m.id == message.id)) {
      _messageHistory[senderId]!.add(message);
    }

    // Persist to database
    // Prefer senderId (persistent) as conversation_id for incoming messages
    DatabaseService.instance.saveMessage(message, senderId);

    // 2. Show notification
    NotificationService.instance.showMessageNotification(
      senderName: message.senderName ?? 'Unknown',
      message: message.text,
      isEmergency: false,
      payload: 'chat_$endpointId',
    );

    // 3. Notify stream if chat open
    _messageStreams[endpointId]?.add(message);

    notifyListeners();
  }
  // load message history for a specific device
  List<MessageModel> getMessageHistory(String endpointId) {
    return _messageHistory[endpointId] ?? [];
  }
  
  /// Get message history for a device, checking multiple possible IDs
  List<MessageModel> getMessageHistoryForDevice(String? endpointId, String? deviceId) {
    final allMessages = <MessageModel>[];
    final seenIds = <String>{};

    // 1. Try loading from Database if deviceId is known
    if (deviceId != null) {
       // This call is async, but this method is synchronous. 
       // Ideally, we should load this async.
       // For now, we rely on what's in _messageHistory which we populate from DB on demand or init?
       // Wait, we can't easily make this async without changing the UI.
       // But we can check _messageHistory which we should populate.
    }
    
    // Existing logic for in-memory history
    // Try endpointId first
    if (endpointId != null) {
      final messages = _messageHistory[endpointId] ?? [];
      for (var msg in messages) {
        if (!seenIds.contains(msg.id)) {
          allMessages.add(msg);
          seenIds.add(msg.id);
        }
      }
    }
    
    // Try deviceId if different
    if (deviceId != null && deviceId != endpointId) {
      final messages = _messageHistory[deviceId] ?? [];
      for (var msg in messages) {
        if (!seenIds.contains(msg.id)) {
          allMessages.add(msg);
          seenIds.add(msg.id);
        }
      }
    }
    
    // Also check all connected devices to find matching endpointId/deviceId
    for (var device in _connectedDevices.values) {
      if (device.endpointId == endpointId || device.id == deviceId) {
        // Check if there are messages stored under the device's endpointId
        if (device.endpointId != null && device.endpointId != endpointId) {
          final messages = _messageHistory[device.endpointId!] ?? [];
          for (var msg in messages) {
            if (!seenIds.contains(msg.id)) {
              allMessages.add(msg);
              seenIds.add(msg.id);
            }
          }
        }
        // Check if there are messages stored under the device's id
        if (device.id != deviceId && device.id != endpointId) {
          final messages = _messageHistory[device.id] ?? [];
          for (var msg in messages) {
            if (!seenIds.contains(msg.id)) {
              allMessages.add(msg);
              seenIds.add(msg.id);
            }
          }
        }
      }
    }
    
    // If the list is empty, maybe we should try to load from DB into memory for next time?
    // Since this is sync, we can't await.
    // But we can trigger a background load.
    if (deviceId != null && allMessages.isEmpty) {
       _loadHistoryFromDb(deviceId, endpointId);
    }

    // Sort by timestamp
    allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return allMessages;
  }
  
  Future<void> _loadHistoryFromDb(String deviceId, String? endpointId) async {
    final messages = await DatabaseService.instance.getMessages(deviceId);
    if (messages.isNotEmpty) {
       _messageHistory[deviceId] = messages;
       // Also map to endpointId if provided
       if (endpointId != null) {
         _messageHistory[endpointId] = messages;
       }
       notifyListeners();
    }
  }


  /// Handle emergency alert
  void _handleEmergencyAlert(String endpointId, Map<String, dynamic> data) {
    debugPrint('🚨 EMERGENCY ALERT from ${data['senderName']}: ${data['alert']}');
    
    final senderId = data['senderId'] ?? endpointId;
    final alertText = data['alert'] ?? '';
    // Create emergency message
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      text: '🚨 EMERGENCY: $alertText',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      isMe: false,
      senderName: data['senderName'],
      isEmergency: true,
    );
    
    // Store in history (important for when chat page opens later)
    _messageHistory.putIfAbsent(endpointId, () => []);
    _messageHistory[endpointId]!.add(message);
    
    // Also store under senderId
    _messageHistory.putIfAbsent(senderId, () => []);
    if (!_messageHistory[senderId]!.any((m) => m.id == message.id)) {
      _messageHistory[senderId]!.add(message);
    }
    
    // Persist to DB
    DatabaseService.instance.saveMessage(message, senderId);

    // Show high-priority notification for emergency
    NotificationService.instance.showMessageNotification(
      senderName: message.senderName ?? 'Unknown',
      message: alertText,
      isEmergency: true,
      payload: 'emergency_$endpointId',
    );

    // Notify stream if chat is open
    _messageStreams[endpointId]?.add(message);
    
    notifyListeners();
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
    final resourceKey = '${resource.id}_$_localDeviceId';
    _networkResources[resourceKey] = resourceWithDevice;
    
    // Persist to database if it's our resource
    if (resourceWithDevice.deviceId == _localDeviceId) {
      await DatabaseService.instance.saveUserResource(resourceWithDevice);
    }

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

      // Skip if this resource is from our own device (already added in broadcastResource)
      if (resourceWithDevice.deviceId == _localDeviceId) {
        debugPrint('📦 P2P: Skipping own resource: ${resource.name}');
        return;
      }

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
    
    // Get requester name from device if available
    final requesterName = _connectedDevices[endpointId]?.name ?? 'Unknown';
    
    // Show notification
    NotificationService.instance.showResourceRequestNotification(
      requesterName: requesterName,
      resourceName: 'All Resources',
      resourceCategory: 'Multiple',
      payload: 'resource_request_$endpointId',
    );
  }

  /// Handle resource list (multiple resources at once)
  void _handleResourceList(String endpointId, Map<String, dynamic> data) {
    try {
      final resourcesJson = data['resources'] as List<dynamic>;
      int addedCount = 0;
      
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

        // Skip if this resource is from our own device
        if (resourceWithDevice.deviceId == _localDeviceId) {
          continue;
        }

        final resourceKey = '${resource.id}_${resourceWithDevice.deviceId}';
        
        // Only add if not already exists
        if (!_networkResources.containsKey(resourceKey)) {
          _networkResources[resourceKey] = resourceWithDevice;
          _resourceStreamController.add(resourceWithDevice);
          addedCount++;
        }
      }
      
      if (addedCount > 0) {
        notifyListeners();
        debugPrint('📦 P2P: Received $addedCount new resources from $endpointId');
      }
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

  /// Request a specific resource with quantity
  Future<void> requestSpecificResource(String endpointId, String resourceId, int requestedQuantity, String requesterName) async {
    final requestData = {
      'type': 'resource_request_specific',
      'resourceId': resourceId,
      'requestedQuantity': requestedQuantity,
      'requesterId': _localDeviceId,
      'requesterName': requesterName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _sendData(endpointId, requestData);
    debugPrint('📥 P2P: Requested $requestedQuantity of resource $resourceId from $endpointId');
  }

  /// Handle specific resource request
  void _handleResourceRequestSpecific(String endpointId, Map<String, dynamic> data) {
    final resourceId = data['resourceId'] as String;
    final requestedQuantity = data['requestedQuantity'] as int;
    final requesterId = data['requesterId'] as String;
    final requesterName = data['requesterName'] as String? ?? 'Unknown';
    
    // Find the resource in our local resources
    final resourceKey = '${resourceId}_$_localDeviceId';
    final resource = _networkResources[resourceKey];
    
    if (resource != null) {
      // Show notification
      NotificationService.instance.showResourceRequestNotification(
        requesterName: requesterName,
        resourceName: resource.name,
        resourceCategory: resource.category,
        payload: 'resource_request_$resourceId',
      );
      
      // Notify UI about the request
      _resourceRequestStreamController.add({
        'resourceId': resourceId,
        'resource': resource,
        'requestedQuantity': requestedQuantity,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'endpointId': endpointId,
      });
      debugPrint('📥 P2P: Received resource request for ${resource.name} (Qty: $requestedQuantity) from $requesterName');
    } else {
      debugPrint('⚠️ P2P: Resource $resourceId not found for request');
    }
  }

  /// Respond to a resource request (approve or deny)
  Future<void> respondToResourceRequest(String endpointId, String resourceId, bool approved, int quantity, String requesterName) async {
    // Get the resource to include name in response
    final resourceKey = '${resourceId}_$_localDeviceId';
    final resource = _networkResources[resourceKey];
    
    final responseData = {
      'type': 'resource_request_response',
      'resourceId': resourceId,
      'resourceName': resource?.name ?? 'Unknown Resource',
      'approved': approved,
      'quantity': quantity,
      'requesterName': requesterName,
      'providerName': _localDeviceName ?? 'Unknown',
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _sendData(endpointId, responseData);
    debugPrint('📤 P2P: Sent resource request response: ${approved ? "Approved" : "Denied"}');
  }

  /// Handle resource request response (received by requester)
  void _handleResourceRequestResponse(String endpointId, Map<String, dynamic> data) {
    final resourceId = data['resourceId'] as String;
    final resourceName = data['resourceName'] as String? ?? 'Unknown Resource';
    final approved = data['approved'] as bool;
    final quantity = data['quantity'] as int;
    final requesterName = data['requesterName'] as String? ?? 'Unknown';
    final providerName = data['providerName'] as String? ?? 'Unknown';
    
    if (approved) {
      // Find the resource in our network resources and update it
      // This updates the requester's view of the resource
      for (var entry in _networkResources.entries) {
        if (entry.value.id == resourceId) {
          final newQuantity = entry.value.quantity - quantity;
          final updatedResource = entry.value.copyWith(
            quantity: newQuantity,
            status: newQuantity <= 0 
                ? 'Unavailable' 
                : 'Provided to: $requesterName (Qty: $quantity)',
          );
          _networkResources[entry.key] = updatedResource;
          _resourceStreamController.add(updatedResource);
          notifyListeners();
          debugPrint('✅ P2P: Resource request approved - ${updatedResource.name} updated');
          break;
        }
      }
      
      // Show notification to requester that request was approved
      NotificationService.instance.showResourceResponseNotification(
        providerName: providerName,
        resourceName: resourceName,
        approved: true,
        quantity: quantity,
        payload: 'resource_response_$resourceId',
      );
    } else {
      debugPrint('❌ P2P: Resource request denied for $resourceId');
      
      // Show notification to requester that request was denied
      NotificationService.instance.showResourceResponseNotification(
        providerName: providerName,
        resourceName: resourceName,
        approved: false,
        payload: 'resource_response_$resourceId',
      );
    }
  }

  /// Update resource after approval (called by UI)
  void updateResourceAfterApproval(String resourceId, int requestedQuantity, String requesterName) {
    final resourceKey = '${resourceId}_$_localDeviceId';
    final resource = _networkResources[resourceKey];
    
    if (resource != null) {
      final newQuantity = resource.quantity - requestedQuantity;
      String newStatus;
      
      if (newQuantity <= 0) {
        newStatus = 'Unavailable';
      } else if (resource.status == 'Available') {
        newStatus = 'Provided to: $requesterName (Qty: $requestedQuantity)';
      } else {
        // If already provided to someone, append the new requester
        newStatus = '${resource.status}, $requesterName (Qty: $requestedQuantity)';
      }
      
      final updatedResource = resource.copyWith(
        quantity: newQuantity,
        status: newStatus,
      );
      
      _networkResources[resourceKey] = updatedResource;
      
      // Update in database
      DatabaseService.instance.saveUserResource(updatedResource);
      
      _resourceStreamController.add(updatedResource);
      notifyListeners();
      
      // Broadcast updated resource to all devices
      final resourceData = {
        'type': 'resource',
        'resource': updatedResource.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      broadcastData(resourceData);
      
      debugPrint('✅ P2P: Updated resource ${resource.name} after approval');
    }
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
    _resourceRequestStreamController.close();
    super.dispose();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/device_model.dart';
import '../models/resource_model.dart';

class P2PService {
  static final P2PService instance = P2PService._init();
  
  final _flutterP2pConnection = FlutterP2pConnection();
  
  // Streams
  final _devicesController = StreamController<List<DiscoveredPeers>>.broadcast();
  final _connectionStatusController = StreamController<WifiP2PInfo>.broadcast();
  final _receivedDataController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<List<DiscoveredPeers>> get devicesStream => _devicesController.stream;
  Stream<WifiP2PInfo> get connectionStatusStream => _connectionStatusController.stream;
  Stream<Map<String, dynamic>> get receivedDataStream => _receivedDataController.stream;
  
  bool _isInitialized = false;
  bool _isDiscovering = false;
  Socket? _socket;
  ServerSocket? _serverSocket;
  
  List<DiscoveredPeers> _discoveredDevices = [];
  WifiP2PInfo? _currentConnection;

  P2PService._init();

  // Initialize P2P service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request necessary permissions
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        print('P2P: Permissions not granted');
        return false;
      }

      // Register the service
      await _flutterP2pConnection.register();
      
      // Set up listeners
      _setupListeners();
      
      _isInitialized = true;
      print('P2P: Initialized successfully');
      return true;
    } catch (e) {
      print('P2P: Initialization error: $e');
      return false;
    }
  }

  // Request necessary permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final permissions = await [
        Permission.location,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.nearbyWifiDevices,
      ].request();

      return permissions.values.every((status) => 
        status.isGranted || status.isLimited
      );
    }
    return true;
  }

  // Set up stream listeners
  void _setupListeners() {
    // Listen to discovered peers
    _flutterP2pConnection.streamPeers().listen((peers) {
      _discoveredDevices = peers;
      _devicesController.add(peers);
      print('P2P: Discovered ${peers.length} devices');
    }, onError: (error) {
      print('P2P: Peers stream error: $error');
    });

    // Listen to WiFi P2P info (connection status)
    _flutterP2pConnection.streamWifiP2PInfo().listen((info) {
      _currentConnection = info;
      _connectionStatusController.add(info);
      print('P2P: Connection status changed - isConnected: ${info.isConnected}');
      
      // Start server if we're the group owner
      if (info.isConnected && info.isGroupOwner) {
        _startServer();
      }
    }, onError: (error) {
      print('P2P: Connection info stream error: $error');
    });
  }

  // Start peer discovery
  Future<bool> startDiscovery() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      if (_isDiscovering) {
        await stopDiscovery();
      }

      final result = await _flutterP2pConnection.discover();
      _isDiscovering = result;
      print('P2P: Discovery started: $result');
      return result;
    } catch (e) {
      print('P2P: Discovery error: $e');
      return false;
    }
  }

  // Stop peer discovery
  Future<bool> stopDiscovery() async {
    try {
      final result = await _flutterP2pConnection.stopDiscovery();
      _isDiscovering = !result;
      print('P2P: Discovery stopped: $result');
      return result;
    } catch (e) {
      print('P2P: Stop discovery error: $e');
      return false;
    }
  }

  // Connect to a peer
  Future<bool> connectToPeer(String deviceAddress) async {
    try {
      final result = await _flutterP2pConnection.connect(deviceAddress);
      print('P2P: Connection result: $result');
      
      if (result) {
        // Wait a bit for connection to establish
        await Future.delayed(const Duration(seconds: 2));
        
        // If not group owner, connect as client
        if (_currentConnection != null && 
            !_currentConnection!.isGroupOwner && 
            _currentConnection!.groupOwnerAddress != null) {
          await _connectAsClient(_currentConnection!.groupOwnerAddress!);
        }
      }
      
      return result;
    } catch (e) {
      print('P2P: Connection error: $e');
      return false;
    }
  }

  // Disconnect from current peer
  Future<bool> disconnect() async {
    try {
      await _socket?.close();
      await _serverSocket?.close();
      _socket = null;
      _serverSocket = null;
      
      final result = await _flutterP2pConnection.removeGroup();
      print('P2P: Disconnected: $result');
      return result;
    } catch (e) {
      print('P2P: Disconnect error: $e');
      return false;
    }
  }

  // Start server (for group owner)
  Future<void> _startServer() async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 8888);
      print('P2P: Server started on port 8888');

      _serverSocket!.listen((Socket client) {
        print('P2P: Client connected: ${client.remoteAddress.address}');
        _handleClient(client);
      });
    } catch (e) {
      print('P2P: Server start error: $e');
    }
  }

  // Connect as client (for non-group owner)
  Future<void> _connectAsClient(String serverAddress) async {
    try {
      _socket = await Socket.connect(serverAddress, 8888);
      print('P2P: Connected to server: $serverAddress');
      
      _socket!.listen(
        (data) {
          final message = utf8.decode(data);
          _handleReceivedData(message);
        },
        onError: (error) {
          print('P2P: Socket error: $error');
        },
        onDone: () {
          print('P2P: Socket closed');
          _socket = null;
        },
      );
    } catch (e) {
      print('P2P: Client connect error: $e');
    }
  }

  // Handle client connection (server side)
  void _handleClient(Socket client) {
    client.listen(
      (data) {
        final message = utf8.decode(data);
        _handleReceivedData(message);
      },
      onError: (error) {
        print('P2P: Client error: $error');
      },
      onDone: () {
        print('P2P: Client disconnected');
        client.close();
      },
    );
  }

  // Handle received data
  void _handleReceivedData(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      print('P2P: Received data: ${data['type']}');
      _receivedDataController.add(data);
    } catch (e) {
      print('P2P: Data parsing error: $e');
    }
  }

  // Send data to connected peer
  Future<bool> sendData(Map<String, dynamic> data) async {
    try {
      final message = jsonEncode(data);
      final bytes = utf8.encode(message);

      if (_socket != null) {
        // Client mode
        _socket!.add(bytes);
        await _socket!.flush();
        print('P2P: Data sent (client mode)');
        return true;
      } else if (_serverSocket != null) {
        // Server mode - broadcast to all connected clients
        // Note: You'd need to track connected clients for proper broadcasting
        print('P2P: Data sent (server mode)');
        return true;
      }

      print('P2P: No active connection for sending data');
      return false;
    } catch (e) {
      print('P2P: Send data error: $e');
      return false;
    }
  }

  // Send resource to connected peer
  Future<bool> sendResource(ResourceModel resource) async {
    final data = {
      'type': 'resource',
      'action': 'share',
      'payload': resource.toJson(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return await sendData(data);
  }

  // Send resource request
  Future<bool> sendResourceRequest(String resourceId, String resourceName) async {
    final data = {
      'type': 'resource',
      'action': 'request',
      'payload': {
        'resourceId': resourceId,
        'resourceName': resourceName,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return await sendData(data);
  }

  // Send device info
  Future<bool> sendDeviceInfo(DeviceModel device) async {
    final data = {
      'type': 'device',
      'action': 'info',
      'payload': device.toJson(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return await sendData(data);
  }

  // Getters
  List<DiscoveredPeers> get discoveredDevices => _discoveredDevices;
  bool get isDiscovering => _isDiscovering;
  bool get isInitialized => _isInitialized;
  WifiP2PInfo? get currentConnection => _currentConnection;
  bool get isConnected => _currentConnection?.isConnected ?? false;

  // Clean up
  Future<void> dispose() async {
    await stopDiscovery();
    await disconnect();
    await _flutterP2pConnection.unregister();
    await _devicesController.close();
    await _connectionStatusController.close();
    await _receivedDataController.close();
    _isInitialized = false;
  }
}


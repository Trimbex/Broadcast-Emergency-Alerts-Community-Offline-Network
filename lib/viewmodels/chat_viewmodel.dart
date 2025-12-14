import 'dart:async';
import '../models/device_model.dart';
import '../models/message_model.dart';
import '../services/database_service.dart';
import 'base_viewmodel.dart';

/// ViewModel for ChatPage
/// Manages chat state, messages, and communication with services
class ChatViewModel extends BaseViewModel {
  final dynamic _p2pService;
  final dynamic _databaseService;

  ChatViewModel({
    required dynamic p2pService,
    dynamic databaseService,
  })  : _p2pService = p2pService,
        _databaseService = databaseService ?? DatabaseService.instance;

  // UI State
  DeviceModel? _device;
  List<MessageModel> _messages = [];
  StreamSubscription<MessageModel>? _messageSubscription;

  // Getters
  DeviceModel? get device => _device;
  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isConnected =>
      _device?.endpointId != null &&
      _p2pService.connectedDevices.any(
        (d) => d.endpointId == _device!.endpointId,
      );

  /// Initialize chat with device
  Future<void> initialize(DeviceModel? device) async {
    _device = device;
    
    if (_device?.endpointId == null) {
      setError('Invalid device');
      return;
    }

    setLoading(true);
    clearError();

    try {
      // Load messages from database
      await _loadMessagesFromDatabase();

      // Listen for new messages
      _setupMessageStream();

      setLoading(false);
    } catch (e) {
      setError('Failed to initialize chat: $e');
      setLoading(false);
    }
  }

  /// Load messages from database
  Future<void> _loadMessagesFromDatabase() async {
    if (_device?.endpointId == null) return;

    final endpointId = _device!.endpointId!;
    final deviceId = _device!.id;

    // Load from both endpointId and deviceId
    final messages1 = await _databaseService.getMessages(endpointId);
    final messages2 = deviceId != endpointId
        ? await _databaseService.getMessages(deviceId)
        : <MessageModel>[];

    // Combine and deduplicate
    final allMessages = <MessageModel>[];
    final seenIds = <String>{};

    for (var msg in [...messages1, ...messages2]) {
      if (!seenIds.contains(msg.id)) {
        allMessages.add(msg);
        seenIds.add(msg.id);
      }
    }

    // Also get from in-memory cache
    final cacheMessages =
        _p2pService.getMessageHistoryForDevice(endpointId, deviceId);
    for (var msg in cacheMessages) {
      if (!seenIds.contains(msg.id)) {
        allMessages.add(msg);
        seenIds.add(msg.id);
      }
    }

    _messages = allMessages;
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    safeNotifyListeners();
  }

  /// Setup message stream listener
  void _setupMessageStream() {
    if (_device?.endpointId == null) return;

    final stream = _p2pService.getMessageStream(_device!.endpointId!);
    _messageSubscription = stream?.listen((message) {
      // Check if message already exists (avoid duplicates)
      if (!_messages.any((m) => m.id == message.id)) {
        _messages.add(message);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        safeNotifyListeners();
      }
    });
  }

  /// Send a text message
  Future<bool> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty || _device?.endpointId == null) {
      return false;
    }

    try {
      await _p2pService.sendMessage(_device!.endpointId!, messageText.trim());
      await refreshMessages();
      return true;
    } catch (e) {
      setError('Failed to send: $e');
      return false;
    }
  }

  /// Send quick message (SOS, Location, Safe)
  Future<bool> sendQuickMessage(String message, {bool isEmergency = false}) async {
    if (_device?.endpointId == null) {
      setError('No device connected');
      return false;
    }

    try {
      if (isEmergency) {
        await _p2pService.broadcastEmergencyAlert(message);
      } else {
        await _p2pService.sendMessage(_device!.endpointId!, message);
      }

      await refreshMessages();
      return true;
    } catch (e) {
      setError('Failed to send: $e');
      return false;
    }
  }

  /// Refresh messages from database
  Future<void> refreshMessages() async {
    await _loadMessagesFromDatabase();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}

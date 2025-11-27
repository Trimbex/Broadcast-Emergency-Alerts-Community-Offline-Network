import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/common/theme_toggle_button.dart';
import '../widgets/chat_page/message_bubble.dart';
import '../widgets/chat_page/chat_app_bar_header.dart';
import '../widgets/chat_page/connection_status_banner.dart';
import '../widgets/chat_page/empty_chat_state.dart';
import '../widgets/chat_page/message_input_bar.dart';
import '../widgets/chat_page/quick_actions_bar.dart';
import '../models/device_model.dart';
import '../models/message_model.dart';
import '../services/p2p_service.dart';
import '../services/database_service.dart';
import '../theme/beacon_colors.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<MessageModel> _messages = [];
  final ScrollController _scrollController = ScrollController();
  DeviceModel? _device;
  P2PService? _p2pService;

@override
void initState() {
  super.initState();

  // Wait for widget to fully build before accessing context
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeChat();
  });
}

  Future<void> _initializeChat() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  if (args != null) {
    _device = args['device'] as DeviceModel?;

    // Initialize P2P service
    _p2pService = Provider.of<P2PService>(context, listen: false);

    if (_device?.endpointId != null) {
        // 1️⃣ Load old messages from database
      final endpointId = _device!.endpointId!;
      final deviceId = _device!.id;
      
        // Load messages from database first
        await _loadMessagesFromDatabase(endpointId, deviceId);

      // 2️⃣ Listen for new incoming messages
      final stream = _p2pService!.getMessageStream(endpointId);
      stream?.listen((message) {
        // Check if message already exists (avoid duplicates)
        if (!_messages.any((m) => m.id == message.id)) {
          setState(() {
            _messages.add(message);
            // Keep sorted
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          });
          _scrollToBottom();
        }
      });
    }

    setState(() {}); // Refresh UI with loaded device & messages
  }
}

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: ChatAppBarHeader(device: _device),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDeviceInfo,
            tooltip: 'Device Info',
          ),
          const ThemeToggleButton(isCompact: true),
        ],
      ),
      body: Consumer<P2PService>(
            builder: (context, p2pService, child) {
              final isConnected = _device?.endpointId != null &&
                  p2pService.connectedDevices.any(
                    (d) => d.endpointId == _device!.endpointId,
                  );

          return Column(
                    children: [
              ConnectionStatusBanner(isConnected: isConnected),
          Expanded(
            child: _messages.isEmpty
                    ? const EmptyChatState()
                : ListView.builder(
                    controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                          return MessageBubble(message: _messages[index]);
                    },
                  ),
          ),
              QuickActionsBar(
                onSOS: () => _sendQuickMessage('🚨 SOS', true),
                onLocation: () => _sendQuickMessage('📍 Location', false),
                onSafe: () => _sendQuickMessage('✅ Safe', false),
              ),
              MessageInputBar(
                    controller: _messageController,
                onSend: _sendMessage,
                isEnabled: isConnected,
                ),
              ],
          );
        },
      ),
    );
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _device?.endpointId == null) {
      return;
    }

    final p2pService = Provider.of<P2PService>(context, listen: false);
    _messageController.clear();

    try {
      await p2pService.sendMessage(_device!.endpointId!, messageText);
      _refreshMessages(p2pService);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: BeaconColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendQuickMessage(String message, bool isEmergency) async {
    if (_device?.endpointId == null) return;

    final p2pService = Provider.of<P2PService>(context, listen: false);

    try {
      if (isEmergency) {
        await p2pService.broadcastEmergencyAlert(message);
      } else {
        await p2pService.sendMessage(_device!.endpointId!, message);
      }
      
      _refreshMessages(p2pService);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: BeaconColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadMessagesFromDatabase(String endpointId, String deviceId) async {
    if (_p2pService == null) return;

    // Load from both endpointId and deviceId
    final messages1 = await DatabaseService.instance.getMessages(endpointId);
    final messages2 = deviceId != endpointId 
        ? await DatabaseService.instance.getMessages(deviceId)
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
    final cacheMessages = _p2pService!.getMessageHistoryForDevice(endpointId, deviceId);
    for (var msg in cacheMessages) {
      if (!seenIds.contains(msg.id)) {
        allMessages.add(msg);
        seenIds.add(msg.id);
      }
    }

    setState(() {
      _messages.clear();
      _messages.addAll(allMessages);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
  }

  void _refreshMessages(P2PService p2pService) {
    if (_device?.endpointId == null) return;

    final endpointId = _device!.endpointId!;
    final deviceId = _device!.id;

    // Reload from database
    _loadMessagesFromDatabase(endpointId, deviceId);
  }

  void _showDeviceInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name:', _device?.name ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow('Status:', _device?.status ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow('Distance:', _device?.distance ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow('Battery:', '${_device?.batteryLevel ?? 0}%'),
            const SizedBox(height: 8),
            _buildInfoRow('Connection:', 'P2P (Nearby Connections)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

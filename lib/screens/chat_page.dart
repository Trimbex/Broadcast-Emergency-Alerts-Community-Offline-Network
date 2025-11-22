import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/voice_command_button.dart';
import '../widgets/theme_toggle_button.dart';
import '../models/device_model.dart';
import '../models/message_model.dart';
import '../services/p2p_service.dart';
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

void _initializeChat() {
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  if (args != null) {
    _device = args['device'] as DeviceModel?;

    // Initialize P2P service
    _p2pService = Provider.of<P2PService>(context, listen: false);

    if (_device?.endpointId != null) {
      // 1️⃣ Load old messages from storage
      // Use the comprehensive method that checks all possible IDs
      final endpointId = _device!.endpointId!;
      final deviceId = _device!.id;
      
      _messages.clear();
      _messages.addAll(_p2pService!.getMessageHistoryForDevice(endpointId, deviceId));

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
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: BeaconColors.accentGradient(context),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      (_device?.name ?? 'U')[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Online indicator
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: BeaconColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _device?.name ?? 'User',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: BeaconColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _device?.status ?? 'Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${_device?.distance ?? 'Nearby'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Signal strength indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.wifi,
              color: BeaconColors.textPrimary(context).withOpacity(0.8),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDeviceInfo,
          ),
          const ThemeToggleButton(isCompact: true),
        ],
      ),
      body: Column(
        children: [
          // Connection status banner
          Consumer<P2PService>(
            builder: (context, p2pService, child) {
              final isConnected = _device?.endpointId != null &&
                  p2pService.connectedDevices.any(
                    (d) => d.endpointId == _device!.endpointId,
                  );

              if (!isConnected) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: BeaconColors.warning,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Connection lost. Messages will be queued.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: BeaconColors.textSecondary(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Quick Actions Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: BeaconColors.surface(context),
              border: Border(
                top: BorderSide(color: BeaconColors.border(context)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionChip('🚨 SOS', Icons.emergency, isEmergency: true),
                _buildQuickActionChip('📍 Location', Icons.location_on),
                _buildQuickActionChip('✅ Safe', Icons.check_circle),
              ],
            ),
          ),

          // Message Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BeaconColors.surface(context),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                const VoiceCommandButton(isCompact: true),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: BeaconColors.primary,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _device?.endpointId == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    final p2pService = Provider.of<P2PService>(context, listen: false);

    // Clear input first
    _messageController.clear();

    // Send via P2P (this will store in history and notify stream)
    try {
      await p2pService.sendMessage(_device!.endpointId!, messageText);
      
      // Reload messages from service to ensure we have the stored version
      final endpointId = _device!.endpointId!;
      final deviceId = _device!.id;
      setState(() {
        _messages.clear();
        _messages.addAll(p2pService.getMessageHistoryForDevice(endpointId, deviceId));
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: BeaconColors.error,
          ),
        );
      }
    }
  }

  Widget _buildMessageBubble(MessageModel message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          gradient: message.isMe
              ? const LinearGradient(
                  colors: BeaconColors.darkAccentGradient,
                )
              : null, 
          color: message.isMe
              ? null
                        : (message.isEmergency ? BeaconColors.error.withOpacity(0.2) : BeaconColors.surface(context)),
          borderRadius: BorderRadius.circular(20),
          border: message.isEmergency
              ? Border.all(color: BeaconColors.error, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isMe && message.senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child:                   Text(
                    message.senderName!,
                    style: TextStyle(
                      color: message.isEmergency ? BeaconColors.error : BeaconColors.textSecondary(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: message.isMe
                    ? Colors.white
                    : (message.isEmergency ? BeaconColors.error : BeaconColors.textPrimary(context)),
                fontSize: 15,
                fontWeight: message.isEmergency ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isMe
                          ? Colors.white.withOpacity(0.8)
                          : BeaconColors.textSecondary(context),
                      fontSize: 11,
                    ),
                  ),
                if (message.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon, {bool isEmergency = false}) {
    return InkWell(
      onTap: () => _sendQuickMessage(label, isEmergency),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isEmergency
              ? BeaconColors.error.withOpacity(0.2)
              : BeaconColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEmergency
                ? BeaconColors.error
                : BeaconColors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isEmergency ? BeaconColors.error : BeaconColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isEmergency ? BeaconColors.error : BeaconColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendQuickMessage(String message, bool isEmergency) async {
    if (_device?.endpointId == null) return;

    final p2pService = Provider.of<P2PService>(context, listen: false);

    // Send via P2P (this will store in history)
    try {
      if (isEmergency) {
        await p2pService.broadcastEmergencyAlert(message);
      } else {
        await p2pService.sendMessage(_device!.endpointId!, message);
      }
      
      // Reload messages from service to ensure we have the stored version
      // For emergency alerts, reload from all connected devices to show the broadcast
      final endpointId = _device!.endpointId!;
      final deviceId = _device!.id;
      
      setState(() {
        _messages.clear();
        _messages.addAll(p2pService.getMessageHistoryForDevice(endpointId, deviceId));
        // Sort by timestamp to ensure proper order
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: BeaconColors.error,
          ),
        );
      }
    }
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
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

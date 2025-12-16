import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/common/theme_toggle_button.dart';
import '../widgets/chat_page/message_bubble.dart';
import '../widgets/chat_page/chat_app_bar_header.dart';
import '../widgets/chat_page/connection_status_banner.dart';
import '../widgets/chat_page/empty_chat_state.dart';
import '../widgets/chat_page/message_input_bar.dart';
import '../widgets/chat_page/quick_actions_bar.dart';
import '../widgets/common/voice_command_listener_animated.dart';
import '../models/device_model.dart';
import '../services/p2p_service.dart';
import '../services/beacon_voice_commands.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../theme/beacon_colors.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatViewModel? _viewModel;
  late BeaconVoiceCommands _voiceCommands;

  @override
  void initState() {
    super.initState();
    _initializeVoiceCommands();

    // Wait for widget to fully build before accessing context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _initializeVoiceCommands() {
    _voiceCommands = BeaconVoiceCommands();
    // Initialize voice commands for chat page
    _voiceCommands.initialize(
      p2pService: P2PService(),
      onCallEmergency: () {
        print('✅ Voice: Send emergency in chat');
        _sendQuickMessage('🚨 EMERGENCY', true);
      },
      onShareLocation: () {
        print('✅ Voice: Share location in chat');
        _sendQuickMessage('📍 Here is my location', false);
      },
      onShowResourcesPage: () {
        print('✅ Voice: Request resources');
        _sendQuickMessage('📦 Can you share resources?', false);
      },
      onShowNetworkPage: () {
        print('✅ Voice: Check network');
        Navigator.pop(context);
      },
      onShowProfilePage: () {
        print('✅ Voice: Show profile');
        // Stay in chat
      },
      onSendMessage: (message) {
        print('✅ Voice: Send message');
        if (message.isEmpty) {
          // Just trigger send
          _sendMessage();
        }
      },
    ).catchError((error) {
      print('❌ Voice init error in chat: $error');
      return false;
    });
  }

  Future<void> _initializeChat() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      final device = args['device'] as DeviceModel?;

      // Create ViewModel with P2P service
      final p2pService = Provider.of<P2PService>(context, listen: false);
      _viewModel = ChatViewModel(p2pService: p2pService);

      // Initialize ViewModel
      await _viewModel!.initialize(device);

      if (mounted) {
        setState(() {}); // Trigger rebuild
      }
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
    _viewModel?.dispose();
    _voiceCommands.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider<ChatViewModel>.value(
      value: _viewModel!,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          title: Consumer<ChatViewModel>(
            builder: (context, viewModel, child) =>
                ChatAppBarHeader(device: viewModel.device),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showDeviceInfo,
              tooltip: 'Device Info',
            ),
            const ThemeToggleButton(isCompact: true),
          ],
        ),
        floatingActionButton: VoiceCommandListenerAnimated(
          commandHandler: _voiceCommands.commandHandler,
          activeColor: BeaconColors.error,
          inactiveColor: BeaconColors.primary,
          size: 56,
          onListeningStart: () {
            print('🎤 Voice listening in chat');
          },
          onListeningStop: () {
            print('🎤 Voice stopped in chat');
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Consumer2<ChatViewModel, P2PService>(
          builder: (context, viewModel, p2pService, child) {
            final isConnected = viewModel.isConnected;

            return Column(
              children: [
                ConnectionStatusBanner(isConnected: isConnected),
                Expanded(
                  child: viewModel.messages.isEmpty
                      ? const EmptyChatState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: viewModel.messages.length,
                          itemBuilder: (context, index) {
                            return MessageBubble(message: viewModel.messages[index]);
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
      ),
    );
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _viewModel == null) {
      return;
    }

    _messageController.clear();

    final success = await _viewModel!.sendMessage(messageText);
    if (success) {
      _scrollToBottom();
    } else {
      // Show error from ViewModel
      if (_viewModel!.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel!.errorMessage!),
            backgroundColor: BeaconColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _viewModel!.clearError();
      }
    }
  }

  Future<void> _sendQuickMessage(String message, bool isEmergency) async {
    if (_viewModel == null) return;

    final success = await _viewModel!.sendQuickMessage(
      message,
      isEmergency: isEmergency,
    );

    if (success) {
      _scrollToBottom();
    } else {
      // Show error from ViewModel
      if (_viewModel!.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel!.errorMessage!),
            backgroundColor: BeaconColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _viewModel!.clearError();
      }
    }
  }

  void _showDeviceInfo() {
    if (_viewModel?.device == null) return;

    final device = _viewModel!.device!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name:', device.name),
            const SizedBox(height: 8),
            _buildInfoRow('Status:', device.status),
            const SizedBox(height: 8),
            _buildInfoRow('Distance:', device.distance),
            const SizedBox(height: 8),
            _buildInfoRow('Battery:', '${device.batteryLevel}%'),
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

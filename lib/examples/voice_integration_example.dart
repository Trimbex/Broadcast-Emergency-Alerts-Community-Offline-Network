import 'package:flutter/material.dart';
import '../../services/speech_service.dart';
import '../../theme/beacon_colors.dart';

/// Quick integration example for Voice features in ChatPage
/// 
/// This mixin demonstrates how to add voice input/output to any screen
mixin VoiceIntegrationMixin {
  late SpeechService speechService;

  /// Initialize voice service
  void initializeVoiceService() {
    speechService = SpeechService();
  }

  /// Send message via voice
  Future<void> sendVoiceMessage(
    Function(String) onMessageSend, {
    VoidCallback? onListeningStart,
    VoidCallback? onListeningStop,
  }) async {
    try {
      onListeningStart?.call();

      final success = await speechService.startListening();
      if (!success) {
        debugPrint('⚠️ Failed to start voice input');
        return;
      }

      // Wait for user to finish speaking (adjustable)
      await Future.delayed(const Duration(seconds: 5));

      await speechService.stopListening();
      final recognizedText = speechService.getRecognizedText();

      if (recognizedText.isNotEmpty) {
        // Send the recognized text as message
        onMessageSend(recognizedText);

        // Speak confirmation
        await speechService.speak('Message sent');
      }

      onListeningStop?.call();
    } catch (e) {
      debugPrint('❌ Voice message error: $e');
    }
  }

  /// Read message aloud (for accessibility)
  Future<void> readMessageAloud(String message, {String? senderName}) async {
    final fullMessage = senderName != null
        ? 'Message from $senderName: $message'
        : message;

    await speechService.speak(fullMessage);
  }

  /// Clean up resources
  void disposeVoiceService() {
    speechService.stopListening();
    speechService.stop();
  }
}

/// Example implementation in ChatPage
class ChatPageWithVoiceExample extends StatefulWidget {
  const ChatPageWithVoiceExample({super.key});

  @override
  State<ChatPageWithVoiceExample> createState() =>
      _ChatPageWithVoiceExampleState();
}

class _ChatPageWithVoiceExampleState extends State<ChatPageWithVoiceExample>
    with VoiceIntegrationMixin {
  final TextEditingController _messageController = TextEditingController();
  bool _isVoiceActive = false;

  @override
  void initState() {
    super.initState();
    initializeVoiceService();
  }

  void _sendMessage(String text) {
    // TODO: Implement actual message sending
    debugPrint('Sending message: $text');
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: Icon(
              _isVoiceActive ? Icons.mic : Icons.mic_none,
              color: _isVoiceActive ? Colors.red : Colors.white,
            ),
            onPressed: () async {
              if (_isVoiceActive) {
                await speechService.stopListening();
              } else {
                final success = await speechService.startListening();
                setState(() => _isVoiceActive = success);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              // Messages list
              children: const [
                // Message bubbles here
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      _sendMessage(_messageController.text);
                    }
                  },
                  child: const Icon(Icons.send),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  backgroundColor: BeaconColors.error,
                  onPressed: () => sendVoiceMessage(
                    _sendMessage,
                    onListeningStart: () {
                      setState(() => _isVoiceActive = true);
                    },
                    onListeningStop: () {
                      setState(() => _isVoiceActive = false);
                    },
                  ),
                  child: Icon(
                    _isVoiceActive ? Icons.mic : Icons.mic_none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    disposeVoiceService();
    _messageController.dispose();
    super.dispose();
  }
}

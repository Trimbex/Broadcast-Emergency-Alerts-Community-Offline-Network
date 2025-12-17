import 'package:flutter/material.dart';
import '../../theme/beacon_colors.dart';
import '../../services/speech_service.dart';

class MessageInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isEnabled;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.isEnabled = true,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  late SpeechService _speechService;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechService = SpeechService();
    _speechService.initialize();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      final recognizedText = _speechService.getRecognizedText();
      if (recognizedText.isNotEmpty) {
        widget.controller.text = recognizedText;
      }
      setState(() => _isListening = false);
    } else {
      final success = await _speechService.startListening(
        onTextUpdate: (text) {
          // Update text field in real-time as speech is recognized
          widget.controller.text = text;
        },
      );
      if (success) {
        setState(() => _isListening = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to start listening'),
              backgroundColor: BeaconColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _speechService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BeaconColors.surface(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: widget.isEnabled,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: BeaconColors.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: BeaconColors.border(context),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: BeaconColors.border(context),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: BeaconColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => widget.onSend(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            // Speech-to-text button - Green when listening, Orange when idle
            Container(
              decoration: BoxDecoration(
                color: _isListening 
                    ? Colors.green // Green when listening
                    : const Color(0xFFFF8C42), // Orange when idle
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isEnabled ? _toggleListening : null,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: BeaconColors.accentGradient(context),
                ),
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isEnabled ? widget.onSend : null,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


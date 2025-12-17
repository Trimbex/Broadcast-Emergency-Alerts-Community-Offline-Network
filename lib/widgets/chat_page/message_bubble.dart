import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../theme/beacon_colors.dart';
import '../../services/speech_service.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final SpeechService _speechService = SpeechService();
  bool _isSpeaking = false;

  Future<void> _toggleSpeak() async {
    if (_isSpeaking) {
      await _speechService.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _speechService.speak(widget.message.text);
      // Wait a bit then check if still speaking
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_speechService.isSpeaking) {
          setState(() => _isSpeaking = false);
        }
      });
    }
  }

  @override
  void dispose() {
    if (_isSpeaking) {
      _speechService.stop();
    }
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  MessageModel get message => widget.message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: message.isMe
              ? LinearGradient(
                  colors: BeaconColors.accentGradient(context),
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
                child: Text(
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
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TTS Button - tap to hear message
                GestureDetector(
                  onTap: _toggleSpeak,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isSpeaking
                          ? (message.isMe ? Colors.white.withOpacity(0.3) : BeaconColors.primary.withOpacity(0.2))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                      size: 16,
                      color: message.isMe
                          ? Colors.white.withOpacity(_isSpeaking ? 1.0 : 0.7)
                          : (_isSpeaking ? BeaconColors.primary : BeaconColors.textSecondary(context)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}


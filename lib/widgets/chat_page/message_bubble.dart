import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../theme/beacon_colors.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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


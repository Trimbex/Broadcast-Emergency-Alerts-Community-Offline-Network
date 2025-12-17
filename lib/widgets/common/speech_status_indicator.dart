import 'package:flutter/material.dart';
import '../../theme/beacon_colors.dart';

class SpeechStatusIndicator extends StatelessWidget {
  final bool isListening;
  final bool isSpeaking;
  final String recognizedText;
  final VoidCallback? onClose;

  const SpeechStatusIndicator({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    this.recognizedText = '',
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!isListening && !isSpeaking && recognizedText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BeaconColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isListening ? BeaconColors.error : BeaconColors.success,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (isListening)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              BeaconColors.error,
                            ),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    if (isSpeaking)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.volume_up,
                          color: BeaconColors.success,
                          size: 20,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        isListening
                            ? 'Listening...'
                            : isSpeaking
                                ? 'Speaking...'
                                : 'Recognized',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isListening ? BeaconColors.error : BeaconColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (recognizedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BeaconColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                recognizedText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BeaconColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

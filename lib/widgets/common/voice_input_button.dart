import 'package:flutter/material.dart';
import '../../services/speech_service.dart';
import '../../theme/beacon_colors.dart';

class VoiceInputButton extends StatefulWidget {
  final Function(String) onTextRecognized;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final bool speakConfirmation;

  const VoiceInputButton({
    super.key,
    required this.onTextRecognized,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 56,
    this.speakConfirmation = true,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  late SpeechService _speechService;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechService = SpeechService();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      final recognizedText = _speechService.getRecognizedText();
      
      if (recognizedText.isNotEmpty) {
        widget.onTextRecognized(recognizedText);
        
        if (widget.speakConfirmation) {
          await _speechService.speak('Recognized: $recognizedText');
        }
      }
      
      setState(() => _isListening = false);
    } else {
      final success = await _speechService.startListening();
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
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _toggleListening,
      backgroundColor: widget.backgroundColor ?? (_isListening ? BeaconColors.error : BeaconColors.primary),
      child: Icon(
        _isListening ? Icons.mic : Icons.mic_none,
        color: widget.foregroundColor ?? Colors.white,
        size: widget.size * 0.5,
      ),
    );
  }

  @override
  void dispose() {
    _speechService.stopListening();
    super.dispose();
  }
}

class VoiceCommandButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool readLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;

  const VoiceCommandButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.readLabel = true,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 56,
  });

  @override
  State<VoiceCommandButton> createState() => _VoiceCommandButtonState();
}

class _VoiceCommandButtonState extends State<VoiceCommandButton> {
  late SpeechService _speechService;

  @override
  void initState() {
    super.initState();
    _speechService = SpeechService();
  }

  Future<void> _handlePress() async {
    widget.onPressed();
    
    if (widget.readLabel) {
      await _speechService.speak(widget.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: _handlePress,
          backgroundColor: widget.backgroundColor ?? BeaconColors.primary,
          child: Icon(
            widget.icon,
            color: widget.foregroundColor ?? Colors.white,
            size: widget.size * 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

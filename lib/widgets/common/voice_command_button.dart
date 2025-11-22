import 'package:flutter/material.dart';
import '../../theme/beacon_colors.dart';

class VoiceCommandButton extends StatefulWidget {
  final bool isCompact;

  const VoiceCommandButton({
    super.key,
    this.isCompact = false,
  });

  @override
  State<VoiceCommandButton> createState() => _VoiceCommandButtonState();
}

class _VoiceCommandButtonState extends State<VoiceCommandButton>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _animationController.repeat(reverse: true);
        _showVoiceCommandDialog();
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    });
  }

  void _showVoiceCommandDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Voice Command Active'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Listening...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Say a command or tap to cancel',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Try: "Send help", "Show resources", "Call emergency contact"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isListening = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    ).then((_) {
      setState(() {
        _isListening = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return IconButton(
        icon: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: _isListening 
              ? BeaconColors.error 
              : BeaconColors.textPrimary(context),
        ),
        tooltip: 'Voice Commands',
        onPressed: _toggleListening,
      );
    }

    // Floating Action Button for chatbot-style voice command
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _isListening
            ? const LinearGradient(
                colors: [BeaconColors.error, Color(0xFFC62828)],
              )
            : LinearGradient(
                colors: BeaconColors.accentGradient(context),
              ),
        boxShadow: [
          BoxShadow(
            color: (_isListening 
                ? BeaconColors.error 
                : BeaconColors.primary
            ).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _toggleListening,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _scaleAnimation.value : 1.0,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 28,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}
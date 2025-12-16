import 'package:flutter/material.dart';
import '../../services/voice_command_handler.dart';
import '../../theme/beacon_colors.dart';

/// Animated voice command listener with circular wave effect
/// Shows a FAB that listens for voice commands with wave animation
class VoiceCommandListenerAnimated extends StatefulWidget {
  final VoiceCommandHandler commandHandler;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;
  final VoidCallback? onListeningStart;
  final VoidCallback? onListeningStop;

  const VoiceCommandListenerAnimated({
    super.key,
    required this.commandHandler,
    this.activeColor,
    this.inactiveColor,
    this.size = 56,
    this.onListeningStart,
    this.onListeningStop,
  });

  @override
  State<VoiceCommandListenerAnimated> createState() => _VoiceCommandListenerAnimatedState();
}

class _VoiceCommandListenerAnimatedState extends State<VoiceCommandListenerAnimated>
    with TickerProviderStateMixin {
  String _lastCommandResult = '';
  bool _isError = false;
  late AnimationController _waveController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
    
    // Wave animation controller
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _setupCallbacks() {
    widget.commandHandler.onCommandRecognized((commandName) {
      setState(() {
        _lastCommandResult = 'Recognized: $commandName';
        _isError = false;
      });
    });

    widget.commandHandler.onCommandExecuted((commandName, feedback) {
      setState(() {
        _lastCommandResult = 'Executed: $commandName';
        _isError = false;
      });
    });

    widget.commandHandler.onCommandFailed((error) {
      setState(() {
        _lastCommandResult = 'Error: $error';
        _isError = true;
      });
    });
  }

  Future<void> _toggleListening() async {
    if (widget.commandHandler.isListeningForCommands) {
      await widget.commandHandler.stopListeningForCommands();
      widget.onListeningStop?.call();
      _waveController.stop();
      _waveController.reset();
    } else {
      widget.onListeningStart?.call();
      print('🎤 Starting voice command listener...');
      final success =
          await widget.commandHandler.startListeningForCommands();
      print('🎤 Voice listener result: $success');
      
      if (success) {
        // Start wave animation when listening
        _waveController.repeat();
      } else if (mounted) {
        print('❌ Voice listener failed - showing error snackbar');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to start voice listener.\n\n'
              'Check:\n'
              '• Microphone permissions granted\n'
              '• Device language is English\n'
              '• Internet connection available',
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Color.fromARGB(255, 244, 67, 54),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.commandHandler.isListeningForCommands;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_lastCommandResult.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isError
                  ? BeaconColors.error.withValues(alpha: 0.08)
                  : BeaconColors.success.withValues(alpha: 0.08),
              border: Border.all(
                color: _isError ? BeaconColors.error.withValues(alpha: 0.3) : BeaconColors.success.withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: _isError ? BeaconColors.error.withValues(alpha: 0.8) : BeaconColors.success.withValues(alpha: 0.8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _lastCommandResult,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _isError ? BeaconColors.error.withValues(alpha: 0.8) : BeaconColors.success.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Circular wave animation container
        Container(
          width: widget.size + 40,
          height: widget.size + 40,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Wave animations (only visible when listening)
              if (isListening) ...[
                _buildWaveRing(0, 0.5),
                _buildWaveRing(1, 0.35),
                _buildWaveRing(2, 0.2),
              ],
              // Main button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isListening 
                          ? const Color(0xFFFF6B35) // Beacon Orange
                          : const Color(0xFFFF8C42)).withValues(alpha: 0.35),
                      blurRadius: isListening ? 24 : 14,
                      spreadRadius: isListening ? 3 : 1.5,
                    ),
                    // Extra glow layer for sparkle effect
                    BoxShadow(
                      color: (isListening 
                          ? const Color(0xFFFF8C42) // Lighter orange glow
                          : const Color(0xFFFFAB7A)).withValues(alpha: 0.18),
                      blurRadius: isListening ? 40 : 20,
                      spreadRadius: isListening ? 5 : 2.5,
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: _toggleListening,
                  backgroundColor: isListening
                      ? const Color(0xFFFF6B35) // Bright Beacon Orange when listening
                      : const Color(0xFFFF8C42), // Lighter orange when idle
                  elevation: 0,
                  shape: const CircleBorder(),
                  child: Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: widget.size * 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build animated wave ring
  Widget _buildWaveRing(int index, double initialOpacity) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final delay = index * 0.15;
        final progress = (_waveController.value + delay) % 1.0;
        
        return Transform.scale(
          scale: 1.0 + (progress * 0.8),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF6B35).withValues(
                  alpha: initialOpacity * (1.0 - progress),
                ),
                width: 2,
              ),
            ),
            width: widget.size + (index * 20),
            height: widget.size + (index * 20),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    widget.commandHandler.stopListeningForCommands();
    super.dispose();
  }
}

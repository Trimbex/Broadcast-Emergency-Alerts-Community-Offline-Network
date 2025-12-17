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
  bool _isListening = false; // Track listening state locally for reliable animation
  late AnimationController _waveController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
    
    // Wave animation controller - faster for smoother Siri-like effect
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? BeaconColors.error : BeaconColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  void _setupCallbacks() {
    widget.commandHandler.onCommandRecognized((commandName) {
      if (mounted) {
        _showToast('Recognized: $commandName');
      }
    });

    widget.commandHandler.onCommandExecuted((commandName, feedback) {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
        _waveController.stop();
        _waveController.reset();
        _showToast('Executed: $commandName');
      }
    });

    widget.commandHandler.onCommandFailed((error) {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
        _waveController.stop();
        _waveController.reset();
        _showToast('Error: $error', isError: true);
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await widget.commandHandler.stopListeningForCommands();
      widget.onListeningStop?.call();
      _waveController.stop();
      _waveController.reset();
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } else {
      // Start animation IMMEDIATELY for instant visual feedback
      setState(() {
        _isListening = true;
      });
      _waveController.repeat();
      widget.onListeningStart?.call();
      
      // Show listening toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Listening...'),
            ],
          ),
          backgroundColor: const Color(0xFFFF6B35),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 10), // Long duration, will be dismissed manually
        ),
      );
      
      print('🎤 Starting voice command listener...');
      
      final success =
          await widget.commandHandler.startListeningForCommands();
      print('🎤 Voice listener result: $success');
      
      if (!success) {
        _waveController.stop();
        _waveController.reset();
        if (mounted) {
          setState(() {
            _isListening = false;
          });
          print('❌ Voice listener failed - showing error snackbar');
          _showToast(
            'Failed to start voice listener. Check microphone permissions.',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _isListening; // Use local state for reliable animation

    // Circular wave animation container - expanded for Siri-like waves
    return Container(
          width: widget.size + 120,
          height: widget.size + 120,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Enhanced wave animations (only visible when listening) - Siri-like effect
              if (isListening) ...[
                _buildWaveRing(0, 0.6, 0.0),
                _buildWaveRing(1, 0.5, 0.2),
                _buildWaveRing(2, 0.4, 0.4),
                _buildWaveRing(3, 0.3, 0.6),
                _buildWaveRing(4, 0.2, 0.8),
              ],
              // Main button with enhanced surfacing effect
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isListening ? (1.0 + _pulseController.value * 0.08) : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          // Primary glow - more intense when listening
                          BoxShadow(
                            color: (isListening 
                                ? const Color(0xFFFF6B35) // Beacon Orange
                                : const Color(0xFFFF8C42)).withValues(
                              alpha: isListening ? (0.6 + _pulseController.value * 0.4) : 0.35
                            ),
                            blurRadius: isListening ? (30 + _pulseController.value * 12) : 14,
                            spreadRadius: isListening ? (4 + _pulseController.value * 3) : 1.5,
                          ),
                          // Secondary glow layer
                          BoxShadow(
                            color: (isListening 
                                ? const Color(0xFFFF8C42) // Lighter orange glow
                                : const Color(0xFFFFAB7A)).withValues(
                              alpha: isListening ? (0.3 + _pulseController.value * 0.2) : 0.18
                            ),
                            blurRadius: isListening ? (50 + _pulseController.value * 20) : 20,
                            spreadRadius: isListening ? (6 + _pulseController.value * 4) : 2.5,
                          ),
                          // Outer glow for surfacing effect
                          if (isListening)
                            BoxShadow(
                              color: const Color(0xFFFFAB7A).withValues(
                                alpha: 0.15 + _pulseController.value * 0.1,
                              ),
                              blurRadius: 70 + _pulseController.value * 30,
                              spreadRadius: 8 + _pulseController.value * 5,
                            ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: _toggleListening,
                        backgroundColor: isListening
                            ? const Color(0xFFFF6B35) // Bright Beacon Orange when listening
                            : const Color(0xFFFF8C42), // Lighter orange when idle
                        elevation: isListening ? 12 : 4,
                        highlightElevation: isListening ? 16 : 8,
                        shape: const CircleBorder(),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isListening ? Icons.mic : Icons.mic_none,
                            key: ValueKey(isListening),
                            color: Colors.white,
                            size: widget.size * 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
  }

  /// Build animated wave ring with Siri-like surfacing effect
  Widget _buildWaveRing(int index, double initialOpacity, double delayOffset) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final delay = delayOffset + (index * 0.2);
        final progress = (_waveController.value + delay) % 1.0;
        final opacity = initialOpacity * (1.0 - progress);
        final scale = 1.0 + (progress * 1.5); // Larger expansion for surfacing effect
        
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Container(
              width: widget.size + (index * 25),
              height: widget.size + (index * 25),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Filled gradient for surfacing effect (like Siri) - more visible
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B35).withValues(alpha: opacity * 0.6),
                    const Color(0xFFFF8C42).withValues(alpha: opacity * 0.4),
                    const Color(0xFFFFAB7A).withValues(alpha: opacity * 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
                // Border for definition - more visible
                border: Border.all(
                  color: const Color(0xFFFF6B35).withValues(
                    alpha: opacity * 0.8,
                  ),
                  width: 3.0,
                ),
                // Shadow for depth and surfacing effect - more prominent
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withValues(
                      alpha: opacity * 0.5,
                    ),
                    blurRadius: 20 + (progress * 25),
                    spreadRadius: 3 + (progress * 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF8C42).withValues(
                      alpha: opacity * 0.3,
                    ),
                    blurRadius: 30 + (progress * 35),
                    spreadRadius: 4 + (progress * 10),
                  ),
                ],
              ),
            ),
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

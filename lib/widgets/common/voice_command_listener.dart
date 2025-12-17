import 'package:flutter/material.dart';
import '../../services/voice_command_handler.dart';
import '../../theme/beacon_colors.dart';

/// Voice command listener widget
/// Shows a FAB that listens for voice commands and provides feedback
class VoiceCommandListener extends StatefulWidget {
  final VoiceCommandHandler commandHandler;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;
  final VoidCallback? onListeningStart;
  final VoidCallback? onListeningStop;

  const VoiceCommandListener({
    super.key,
    required this.commandHandler,
    this.activeColor,
    this.inactiveColor,
    this.size = 56,
    this.onListeningStart,
    this.onListeningStop,
  });

  @override
  State<VoiceCommandListener> createState() => _VoiceCommandListenerState();
}

class _VoiceCommandListenerState extends State<VoiceCommandListener> {
  String _lastCommandResult = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
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
    } else {
      widget.onListeningStart?.call();
      print('🎤 Starting voice command listener...');
      final success =
          await widget.commandHandler.startListeningForCommands();
      print('🎤 Voice listener result: $success');
      if (!success && mounted) {
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
    );
  }

  @override
  void dispose() {
    widget.commandHandler.stopListeningForCommands();
    super.dispose();
  }
}

/// Voice command quick reference card
class VoiceCommandReference extends StatelessWidget {
  final VoiceCommandHandler commandHandler;
  final bool showKeywords;

  const VoiceCommandReference({
    super.key,
    required this.commandHandler,
    this.showKeywords = true,
  });

  @override
  Widget build(BuildContext context) {
    final commands = commandHandler.getAllCommands();

    return Card(
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        title: const Text('📢 Voice Commands'),
        subtitle: Text('${commands.length} commands available'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final command in commands) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: BeaconColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: BeaconColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          command.description,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: BeaconColors.primary,
                          ),
                        ),
                        if (showKeywords) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: command.keywords
                                .map(
                                  (keyword) => Chip(
                                    label: Text(
                                      keyword,
                                      style:
                                          Theme.of(context).textTheme.labelSmall,
                                    ),
                                    backgroundColor:
                                        BeaconColors.primary.withValues(alpha: 0.1),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (command.requiresConfirmation) ...[
                          const SizedBox(height: 8),
                          Chip(
                            label: const Text('Requires Confirmation'),
                            backgroundColor: BeaconColors.error.withValues(alpha: 0.1),
                            labelStyle: TextStyle(
                              color: BeaconColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

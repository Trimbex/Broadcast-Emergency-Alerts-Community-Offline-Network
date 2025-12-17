import 'package:flutter/material.dart';
import 'speech_service.dart';

/// Command action callback
typedef CommandAction = Future<void> Function();

/// Voice command definition
class VoiceCommand {
  final String commandName;
  final List<String> keywords; // Words that trigger this command
  final CommandAction action;
  final String description;
  final bool requiresConfirmation;

  VoiceCommand({
    required this.commandName,
    required this.keywords,
    required this.action,
    required this.description,
    this.requiresConfirmation = false,
  });
}

/// Voice command handler with intent recognition
class VoiceCommandHandler {
  static final VoiceCommandHandler _instance =
      VoiceCommandHandler._internal();
  factory VoiceCommandHandler() => _instance;
  VoiceCommandHandler._internal();

  final SpeechService _speechService = SpeechService();
  final Map<String, VoiceCommand> _registeredCommands = {};
  bool _isListeningForCommands = false;

  // Callbacks
  Function(String)? _onCommandRecognized;
  Function(String, String)? _onCommandExecuted; // commandName, feedback
  Function(String)? _onCommandFailed; // error message

  // Getters
  bool get isListeningForCommands => _isListeningForCommands;
  Map<String, VoiceCommand> get registeredCommands => _registeredCommands;

  /// Initialize voice command handler
  Future<bool> initialize() async {
    try {
      final success = await _speechService.initialize();
      debugPrint('✅ Voice Command Handler: Initialized');
      return success;
    } catch (e) {
      debugPrint('❌ Voice Command Handler: Failed to initialize: $e');
      return false;
    }
  }

  /// Register a voice command
  void registerCommand(VoiceCommand command) {
    _registeredCommands[command.commandName] = command;
    debugPrint('📝 Voice Command: Registered "${command.commandName}"');
    debugPrint('   Keywords: ${command.keywords.join(", ")}');
  }

  /// Register multiple commands
  void registerCommands(List<VoiceCommand> commands) {
    for (final command in commands) {
      registerCommand(command);
    }
  }

  /// Unregister a command
  void unregisterCommand(String commandName) {
    _registeredCommands.remove(commandName);
    debugPrint('🗑️ Voice Command: Unregistered "$commandName"');
  }

  /// Start listening for voice commands
  Future<bool> startListeningForCommands() async {
    if (_isListeningForCommands) {
      debugPrint('⚠️ Already listening for commands');
      return false;
    }

    try {
      final success = await _speechService.startListening();
      if (success) {
        _isListeningForCommands = true;
        debugPrint('🎤 Voice Command: Started listening for commands');

        // Process the recognized text
        await Future.delayed(const Duration(seconds: 5));
        await _processRecognizedText();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Voice Command: Failed to start listening: $e');
      _onCommandFailed?.call('Failed to start listening: $e');
      return false;
    }
  }

  /// Stop listening for commands
  Future<void> stopListeningForCommands() async {
    try {
      await _speechService.stopListening();
      _isListeningForCommands = false;
      debugPrint('🛑 Voice Command: Stopped listening');
    } catch (e) {
      debugPrint('❌ Voice Command: Failed to stop listening: $e');
    }
  }

  /// Process recognized text and execute matching command
  Future<void> _processRecognizedText() async {
    try {
      final recognizedText = _speechService.getRecognizedText().toLowerCase();

      if (recognizedText.isEmpty) {
        _onCommandFailed?.call('No speech recognized');
        return;
      }

      debugPrint('📝 Processing recognized text: "$recognizedText"');

      // Find matching command
      final matchedCommand = _findMatchingCommand(recognizedText);

      if (matchedCommand == null) {
        _onCommandFailed?.call('Command not recognized: "$recognizedText"');
        await _speechService.speak('Command not recognized');
        return;
      }

      _onCommandRecognized?.call(matchedCommand.commandName);

      // Handle confirmation if required
      if (matchedCommand.requiresConfirmation) {
        final confirmed = await _requestConfirmation(
          'Execute ${matchedCommand.commandName}?',
        );
        if (!confirmed) {
          await _speechService.speak('Command cancelled');
          return;
        }
      }

      // Execute the command
      await _executeCommand(matchedCommand);
    } catch (e) {
      debugPrint('❌ Voice Command: Error processing text: $e');
      _onCommandFailed?.call('Error: $e');
    } finally {
      _isListeningForCommands = false;
    }
  }

  /// Find matching command using keyword matching
  VoiceCommand? _findMatchingCommand(String text) {
    VoiceCommand? bestMatch;
    int maxMatchCount = 0;

    for (final command in _registeredCommands.values) {
      int matchCount = 0;

      for (final keyword in command.keywords) {
        if (text.contains(keyword.toLowerCase())) {
          matchCount++;
        }
      }

      // Exact keyword match found
      if (matchCount > 0 && matchCount > maxMatchCount) {
        bestMatch = command;
        maxMatchCount = matchCount;
      }
    }

    if (bestMatch != null) {
      debugPrint('✅ Matched command: "${bestMatch.commandName}" (score: $maxMatchCount)');
    }

    return bestMatch;
  }

  /// Execute a command
  Future<void> _executeCommand(VoiceCommand command) async {
    try {
      debugPrint('⚡ Executing command: "${command.commandName}"');

      await _speechService.speak('Executing ${command.commandName}');
      await command.action();

      _onCommandExecuted?.call(
        command.commandName,
        'Command executed successfully',
      );

      debugPrint('✅ Command executed: "${command.commandName}"');
    } catch (e) {
      debugPrint('❌ Command failed: ${command.commandName}: $e');
      _onCommandFailed?.call('Failed to execute command: $e');
      await _speechService.speak('Command failed');
    }
  }

  /// Request user confirmation for a command
  Future<bool> _requestConfirmation(String prompt) async {
    debugPrint('❓ Requesting confirmation: $prompt');
    await _speechService.speak('$prompt Say yes or no');

    // In a real implementation, you would listen for "yes" or "no"
    // For now, return true (could be enhanced with another STT call)
    return true;
  }

  /// Set callback for recognized commands
  void onCommandRecognized(Function(String) callback) {
    _onCommandRecognized = callback;
  }

  /// Set callback for executed commands
  void onCommandExecuted(Function(String, String) callback) {
    _onCommandExecuted = callback;
  }

  /// Set callback for failed commands
  void onCommandFailed(Function(String) callback) {
    _onCommandFailed = callback;
  }

  /// Get all registered commands
  List<VoiceCommand> getAllCommands() => _registeredCommands.values.toList();

  /// Get command by name
  VoiceCommand? getCommand(String commandName) =>
      _registeredCommands[commandName];
}

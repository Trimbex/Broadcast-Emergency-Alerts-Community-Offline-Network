import 'package:flutter/material.dart';
import 'voice_command_handler.dart';
import 'p2p_service.dart';

/// App-specific voice commands for BEACON
class BeaconVoiceCommands {
  static final BeaconVoiceCommands _instance =
      BeaconVoiceCommands._internal();
  factory BeaconVoiceCommands() => _instance;
  BeaconVoiceCommands._internal();

  final VoiceCommandHandler commandHandler = VoiceCommandHandler();

  bool _initialized = false;

  /// Initialize BEACON voice commands
  Future<bool> initialize({
    required P2PService p2pService,
    required VoidCallback onShowResourcesPage,
    required VoidCallback onShowNetworkPage,
    required VoidCallback onShowProfilePage,
    required Function(String) onSendMessage,
    required VoidCallback onCallEmergency,
    required VoidCallback onShareLocation,
  }) async {
    try {
      // Initialize command handler
      final success = await commandHandler.initialize();
      if (!success) {
        debugPrint('❌ BEACON Voice: Command handler init failed');
        return false;
      }

      // Register all BEACON commands
      _registerEmergencyCommands(
        onCallEmergency: onCallEmergency,
        onShareLocation: onShareLocation,
      );

      _registerNavigationCommands(
        onShowResourcesPage: onShowResourcesPage,
        onShowNetworkPage: onShowNetworkPage,
        onShowProfilePage: onShowProfilePage,
      );

      _registerMessageCommands(
        onSendMessage: onSendMessage,
      );

      _initialized = true;
      debugPrint('✅ BEACON Voice: All commands registered');
      return true;
    } catch (e) {
      debugPrint('❌ BEACON Voice: Init failed: $e');
      return false;
    }
  }

  /// Register emergency-related commands
  void _registerEmergencyCommands({
    required VoidCallback onCallEmergency,
    required VoidCallback onShareLocation,
  }) {
    commandHandler.registerCommands([
      VoiceCommand(
        commandName: 'CallEmergency',
        keywords: ['call emergency', 'emergency call', 'help', 'call 911'],
        action: () async => onCallEmergency(),
        description: 'Calls emergency contact',
        requiresConfirmation: true,
      ),
      VoiceCommand(
        commandName: 'ShareLocation',
        keywords: ['share location', 'share my location', 'send location'],
        action: () async => onShareLocation(),
        description: 'Shares current location with network',
        requiresConfirmation: false,
      ),
    ]);

    debugPrint('📍 BEACON Voice: Emergency commands registered');
  }

  /// Register navigation commands
  void _registerNavigationCommands({
    required VoidCallback onShowResourcesPage,
    required VoidCallback onShowNetworkPage,
    required VoidCallback onShowProfilePage,
  }) {
    commandHandler.registerCommands([
      VoiceCommand(
        commandName: 'ShowResources',
        keywords: ['show resources', 'resources', 'open resources', 'resources page'],
        action: () async => onShowResourcesPage(),
        description: 'Opens resources sharing page',
        requiresConfirmation: false,
      ),
      VoiceCommand(
        commandName: 'ShowNetwork',
        keywords: ['show network', 'network', 'connected devices', 'show devices'],
        action: () async => onShowNetworkPage(),
        description: 'Opens network dashboard',
        requiresConfirmation: false,
      ),
      VoiceCommand(
        commandName: 'ShowProfile',
        keywords: ['show profile', 'profile', 'my profile', 'open profile'],
        action: () async => onShowProfilePage(),
        description: 'Opens user profile',
        requiresConfirmation: false,
      ),
    ]);

    debugPrint('🧭 BEACON Voice: Navigation commands registered');
  }

  /// Register message-related commands
  void _registerMessageCommands({
    required Function(String) onSendMessage,
  }) {
    commandHandler.registerCommands([
      VoiceCommand(
        commandName: 'SendMessage',
        keywords: ['send message', 'message', 'chat'],
        action: () async {
          // This will be handled by a dialog in the UI
          onSendMessage('');
        },
        description: 'Sends a message to connected device',
        requiresConfirmation: false,
      ),
    ]);

    debugPrint('💬 BEACON Voice: Message commands registered');
  }

  /// Start listening for voice commands
  Future<bool> startListening() async {
    if (!_initialized) {
      debugPrint('⚠️ BEACON Voice: Not initialized yet');
      return false;
    }

    return await commandHandler.startListeningForCommands();
  }

  /// Stop listening for voice commands
  Future<void> stopListening() async {
    await commandHandler.stopListeningForCommands();
  }

  /// Check if listening
  bool get isListening => commandHandler.isListeningForCommands;

  /// Set callbacks
  void setCallbacks({
    Function(String)? onCommandRecognized,
    Function(String, String)? onCommandExecuted,
    Function(String)? onCommandFailed,
  }) {
    if (onCommandRecognized != null) {
      commandHandler.onCommandRecognized(onCommandRecognized);
    }
    if (onCommandExecuted != null) {
      commandHandler.onCommandExecuted(onCommandExecuted);
    }
    if (onCommandFailed != null) {
      commandHandler.onCommandFailed(onCommandFailed);
    }
  }

  /// Get all registered commands
  List<VoiceCommand> getAllCommands() => commandHandler.getAllCommands();

  /// Dispose resources
  void dispose() {
    commandHandler.stopListeningForCommands();
  }
}

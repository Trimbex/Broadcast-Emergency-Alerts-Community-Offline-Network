import 'package:flutter/material.dart';
import '../../services/beacon_voice_commands.dart';
import '../../services/p2p_service.dart';
import '../../widgets/common/voice_command_listener.dart';
import '../../theme/beacon_colors.dart';

/// Example integration of voice commands in the Landing Page
/// 
/// This shows how to add voice command support to any screen
class LandingPageWithVoiceCommands extends StatefulWidget {
  const LandingPageWithVoiceCommands({super.key});

  @override
  State<LandingPageWithVoiceCommands> createState() =>
      _LandingPageWithVoiceCommandsState();
}

class _LandingPageWithVoiceCommandsState
    extends State<LandingPageWithVoiceCommands> {
  late BeaconVoiceCommands _voiceCommands;
  late P2PService _p2pService;
  String _voiceStatus = '';

  @override
  void initState() {
    super.initState();
    _initializeVoiceCommands();
  }

  Future<void> _initializeVoiceCommands() async {
    _p2pService = P2PService(); // Or get from Provider
    _voiceCommands = BeaconVoiceCommands();

    // Initialize with callbacks for app actions
    final success = await _voiceCommands.initialize(
      p2pService: _p2pService,
      onShowResourcesPage: _navigateToResources,
      onShowNetworkPage: _navigateToNetwork,
      onShowProfilePage: _navigateToProfile,
      onSendMessage: _prepareMessageComposer,
      onCallEmergency: _callEmergencyContact,
      onShareLocation: _shareLocation,
    );

    if (!success) {
      if (mounted) {
        setState(() => _voiceStatus = 'Voice commands unavailable');
      }
    }

    // Set feedback callbacks
    _voiceCommands.setCallbacks(
      onCommandRecognized: (commandName) {
        debugPrint('Voice: Recognized command: $commandName');
      },
      onCommandExecuted: (commandName, feedback) {
        if (mounted) {
          setState(() =>
              _voiceStatus = '✅ Executed: $commandName');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(feedback)),
          );
        }
      },
      onCommandFailed: (error) {
        if (mounted) {
          setState(() => _voiceStatus = '❌ $error');
        }
      },
    );
  }

  void _navigateToResources() {
    Navigator.of(context).pushNamed('/resources');
  }

  void _navigateToNetwork() {
    Navigator.of(context).pushNamed('/network_dashboard');
  }

  void _navigateToProfile() {
    Navigator.of(context).pushNamed('/profile');
  }

  void _prepareMessageComposer(String message) {
    // Could open a dialog or navigate to chat with pre-filled message
    debugPrint('Preparing message: $message');
  }

  Future<void> _callEmergencyContact() async {
    // Get emergency contact from database
    debugPrint('Calling emergency contact...');
    // Implement actual calling logic
  }

  Future<void> _shareLocation() async {
    debugPrint('Sharing location...');
    // Implement location sharing logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BEACON - Emergency Network'),
        actions: [
          IconButton(
            icon: Icon(
              _voiceCommands.isListening ? Icons.mic : Icons.mic_none,
              color: _voiceCommands.isListening ? BeaconColors.error : Colors.white,
            ),
            onPressed: _toggleVoiceCommands,
            tooltip: 'Voice Commands',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Voice status indicator
            if (_voiceStatus.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: _voiceStatus.startsWith('✅')
                    ? BeaconColors.success.withValues(alpha: 0.1)
                    : BeaconColors.error.withValues(alpha: 0.1),
                child: Text(
                  _voiceStatus,
                  style: TextStyle(
                    color: _voiceStatus.startsWith('✅')
                        ? BeaconColors.success
                        : BeaconColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  Text(
                    'Welcome to BEACON',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BeaconColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try voice commands like:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  
                  // Voice command examples
                  _buildCommandExample('🎯 "show resources"', 'Opens resources page'),
                  _buildCommandExample('🌐 "show network"', 'Shows connected devices'),
                  _buildCommandExample('👤 "show profile"', 'Opens your profile'),
                  _buildCommandExample('📍 "share location"', 'Shares your location'),
                  _buildCommandExample('🚨 "call emergency"', 'Calls emergency contact'),

                  const SizedBox(height: 24),

                  // Voice command reference card
                  VoiceCommandReference(
                    commandHandler: _voiceCommands.commandHandler,
                    showKeywords: true,
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToResources,
                          icon: const Icon(Icons.inventory_2),
                          label: const Text('Resources'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToNetwork,
                          icon: const Icon(Icons.hub),
                          label: const Text('Network'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToProfile,
                          icon: const Icon(Icons.person),
                          label: const Text('Profile'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareLocation,
                          icon: const Icon(Icons.location_on),
                          label: const Text('Share Location'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _callEmergencyContact,
                      icon: const Icon(Icons.phone),
                      label: const Text('Call Emergency'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BeaconColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: VoiceCommandListener(
        commandHandler: _voiceCommands.commandHandler,
        activeColor: BeaconColors.error,
        inactiveColor: BeaconColors.primary,
        onListeningStart: () {
          setState(() => _voiceStatus = '🎤 Listening for commands...');
        },
        onListeningStop: () {
          // Status will be updated by callbacks
        },
      ),
    );
  }

  Widget _buildCommandExample(String command, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: BeaconColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              command,
              style: TextStyle(
                color: BeaconColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleVoiceCommands() async {
    if (_voiceCommands.isListening) {
      await _voiceCommands.stopListening();
      setState(() => _voiceStatus = 'Voice commands stopped');
    } else {
      setState(() => _voiceStatus = '🎤 Listening for commands...');
      final success = await _voiceCommands.startListening();
      if (!success && mounted) {
        setState(() => _voiceStatus = 'Failed to start voice commands');
      }
    }
  }

  @override
  void dispose() {
    _voiceCommands.dispose();
    super.dispose();
  }
}

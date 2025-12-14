import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/common/theme_toggle_button.dart';
import '../widgets/landing_page/welcome_header.dart';
import '../widgets/landing_page/quick_access_card.dart';
import '../widgets/landing_page/quick_stats_widget.dart';
import '../theme/beacon_colors.dart';
import '../services/database_service.dart';
import '../services/beacon_voice_commands.dart';
import '../services/p2p_service.dart';
import '../widgets/common/voice_command_listener.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String? _userName;
  bool _isLoading = true;
  late BeaconVoiceCommands _voiceCommands;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _initializeVoiceCommands();
  }

  void _initializeVoiceCommands() {
    _voiceCommands = BeaconVoiceCommands();
    // Initialize voice commands asynchronously
    _voiceCommands.initialize(
      p2pService: P2PService(),
      onCallEmergency: _handleCallEmergency,
      onShareLocation: _handleShareLocation,
      onShowResourcesPage: _handleShowResources,
      onShowNetworkPage: _handleShowNetwork,
      onShowProfilePage: _handleShowProfile,
      onSendMessage: _handleSendMessage,
    ).then((success) {
      if (success) {
        print('✅ Voice commands initialized successfully');
      } else {
        print('❌ Failed to initialize voice commands');
      }
    }).catchError((error) {
      print('❌ Voice command initialization error: $error');
    });

    // Subscribe to callbacks for UI feedback
    _voiceCommands.commandHandler.onCommandRecognized((command) {
      print('🎤 Command Recognized: $command');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recognized: $command'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });

    _voiceCommands.commandHandler.onCommandExecuted((command, feedback) {
      print('✅ Command Executed: $command');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Executed: $command'),
            duration: const Duration(seconds: 2),
            backgroundColor: BeaconColors.primary,
          ),
        );
      }
    });

    _voiceCommands.commandHandler.onCommandFailed((error) {
      print('❌ Command Failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $error'),
            duration: const Duration(seconds: 2),
            backgroundColor: BeaconColors.error,
          ),
        );
      }
    });
  }

  void _handleCallEmergency() {
    print('✅ CallEmergency action triggered!');
    Navigator.pushNamed(context, '/profile');
  }

  void _handleShareLocation() {
    print('✅ ShareLocation action triggered!');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location shared!')),
    );
  }

  void _handleShowResources() {
    print('✅ ShowResources action triggered!');
    Navigator.pushNamed(context, '/resources');
  }

  void _handleShowNetwork() {
    print('✅ ShowNetwork action triggered!');
    Navigator.pushNamed(context, '/network_dashboard', arguments: {'mode': 'join'});
  }

  void _handleShowProfile() {
    print('✅ ShowProfile action triggered!');
    Navigator.pushNamed(context, '/profile');
  }

  void _handleSendMessage(String message) {
    print('✅ SendMessage action triggered!');
    Navigator.pushNamed(context, '/chat');
  }

  Future<void> _loadUserInfo() async {
    try {
      final profile = await DatabaseService.instance.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _userName = profile['name']?.toString();
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshUserName() async {
    await _loadUserInfo();
  }

  @override
  void dispose() {
    _voiceCommands.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Exit the app when back button is pressed
        exit(0);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              exit(0);
            },
          ),
          actions: const [ThemeToggleButton(isCompact: true), SizedBox(width: 8)],
        ),
        floatingActionButton: VoiceCommandListener(
          commandHandler: _voiceCommands.commandHandler,
          activeColor: BeaconColors.error,
          inactiveColor: BeaconColors.primary,
          onListeningStart: () {
            print('🎤 Listening for commands...');
          },
          onListeningStop: () {
            // Status will be updated by callbacks
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Welcome Header
                      WelcomeHeader(userName: _userName),

                      const SizedBox(height: 32),

                      // Main Action Button
                      _buildMainActionButton(context),

                      const SizedBox(height: 24),

                      // Quick Access Grid
                      _buildQuickAccessGrid(context),

                      const SizedBox(height: 24),

                      // Quick Stats
                      const QuickStatsWidget(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMainActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/network_dashboard',
            arguments: {'mode': 'join'},
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.group_add, size: 24),
            SizedBox(width: 12),
            Text(
              'Join Communication Network',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: QuickAccessCard(
                icon: Icons.person,
                label: 'Profile',
                color: BeaconColors.primary,
                onTap: () async {
                  await Navigator.pushNamed(context, '/profile');
                  // Refresh the user name when returning from profile
                  await _refreshUserName();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickAccessCard(
                icon: Icons.inventory_2,
                label: 'Resources',
                color: BeaconColors.secondary,
                onTap: () => Navigator.pushNamed(context, '/resources'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

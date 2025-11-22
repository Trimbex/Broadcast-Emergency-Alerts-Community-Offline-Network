import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/voice_command_button.dart';
import '../widgets/theme_toggle_button.dart';
import '../models/device_model.dart';
import '../services/p2p_service.dart';
import '../theme/beacon_colors.dart';
import 'resource_sharing_page.dart';
import 'chat_page.dart';

class NetworkDashboard extends StatefulWidget {
  const NetworkDashboard({super.key});

  @override
  State<NetworkDashboard> createState() => _NetworkDashboardState();
}

class _NetworkDashboardState extends State<NetworkDashboard> {
  bool _isInitialized = false;

  final List<String> _predefinedMessages = [
    'Need immediate help',
    'Medical assistance required',
    'Safe location found',
    'Resources available',
    'All clear in my area',
  ];

  @override
  void initState() {
    super.initState();
    _initializeP2P();
  }

  Future<void> _initializeP2P() async {
    final p2pService = Provider.of<P2PService>(context, listen: false);
    
    // Initialize with saved user name or default
    final userName = await _getUserName();
    final success = await p2pService.initialize(userName);
    
    if (success) {
      // Start both advertising and discovery for mesh network
      await p2pService.startAdvertising();
      await p2pService.startDiscovery();
      
      setState(() {
        _isInitialized = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📡 P2P Network Active - Searching for nearby devices...'),
            backgroundColor: BeaconColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Failed to start P2P network. Check permissions.'),
            backgroundColor: BeaconColors.error,
          ),
        );
      }
    }
  }

  Future<String> _getUserName() async {
    // Get from Database (set in identity setup)
    final userProfile = await DatabaseService.instance.getUserProfile();
    return userProfile?['name'] ?? 'User-${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  @override
  void dispose() {
    // Don't stop P2P when leaving this screen
    // It should run in background
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final mode = args?['mode'] ?? 'join';

    return Consumer<P2PService>(
      builder: (context, p2pService, child) {
        final connectedDevices = p2pService.connectedDevices;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              mode == 'join' ? 'Emergency Network' : 'Your Network',
            ),
            actions: [
              // P2P Status indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: p2pService.isAdvertising && p2pService.isDiscovering
                          ? BeaconColors.success
                          : BeaconColors.warning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          p2pService.isAdvertising && p2pService.isDiscovering
                              ? Icons.wifi
                              : Icons.wifi_off,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          p2pService.isAdvertising && p2pService.isDiscovering
                              ? 'ACTIVE'
                              : 'INACTIVE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshNetwork,
              ),
              const ThemeToggleButton(isCompact: true),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: BeaconColors.primaryGradient(context),
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Header with stats
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: BeaconColors.surface(context),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusItem(
                        icon: Icons.people,
                        label: 'Connected',
                        value: '${connectedDevices.length}',
                        color: connectedDevices.isNotEmpty ? BeaconColors.success : BeaconColors.textSecondary(context),
                      ),
                      Container(width: 1, height: 40, color: BeaconColors.border(context)),
                      _buildStatusItem(
                        icon: Icons.battery_std,
                        label: 'Battery',
                        value: '${p2pService.batteryLevel}%',
                        color: p2pService.batteryLevel > 50 ? BeaconColors.success : BeaconColors.warning,
                      ),
                    ],
                  ),
                ),

                // Quick actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showQuickMessageDialog,
                          icon: const Icon(Icons.message),
                          label: const Text('Quick Message'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ResourceSharingPage()),
                          ),
                          icon: const Icon(Icons.inventory),
                          label: const Text('Resources'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Devices list or empty message
                Expanded(
                  child: connectedDevices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                             const Icon(
                                Icons.search,
                                size: 64,
                              
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isInitialized
                                    ? 'Searching for nearby devices...'
                                    : 'Initializing P2P network...',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Make sure both devices have\nBluetooth and Location enabled',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 24),
                              if (_isInitialized)
                                const CircularProgressIndicator(
                                  color: BeaconColors.primary,
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: connectedDevices.length,
                          itemBuilder: (context, index) {
                            return _buildDeviceCard(connectedDevices[index], p2pService);
                          },
                        ),
                ),

                // Voice button
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: VoiceCommandButton(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color ?? BeaconColors.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color ?? BeaconColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDeviceCard(DeviceModel device, P2PService p2pService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar box with online indicator
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: BeaconColors.accentGradient(context),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      device.name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: BeaconColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Device info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: BeaconColors.textSecondary(context)),
                      const SizedBox(width: 4),
                      Text(
                        device.distance,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: BeaconColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        device.status,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Battery + Chat
            Column(
              children: [
                Icon(
                  Icons.battery_std,
                  color: device.batteryLevel > 50
                      ? BeaconColors.success
                      : BeaconColors.warning,
                  size: 20,
                ),
                Text(
                  '${device.batteryLevel}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: BeaconColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                color: Colors.white,
                iconSize: 20,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatPage(),
                      settings: RouteSettings(
                        arguments: {'device': device},
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshNetwork() async {
    final p2pService = Provider.of<P2PService>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Refreshing network...'),
        duration: Duration(seconds: 2),
      ),
    );

    // Restart discovery
    await p2pService.stopDiscovery();
    await Future.delayed(const Duration(milliseconds: 500));
    await p2pService.startDiscovery();
  }

  void _showQuickMessageDialog() {
    final p2pService = Provider.of<P2PService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Quick Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _predefinedMessages.map((message) {
            return ListTile(
              title: Text(message),
              leading: Icon(
                message.contains('Emergency') || message.contains('help')
                    ? Icons.emergency
                    : Icons.message,
                color: message.contains('Emergency') || message.contains('help')
                    ? BeaconColors.error
                    : BeaconColors.primary,
              ),
              onTap: () {
                Navigator.pop(context);
                
                // Broadcast to all connected devices
                if (message.contains('help') || message.contains('Emergency') || message.contains('immediate')) {
                  p2pService.broadcastEmergencyAlert(message);
                } else {
                  // Send as regular message to all connected devices
                  for (final device in p2pService.connectedDevices) {
                    if (device.endpointId != null) {
                      p2pService.sendMessage(device.endpointId!, message);
                    }
                  }
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📤 Sent: $message'),
                    backgroundColor: BeaconColors.success,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

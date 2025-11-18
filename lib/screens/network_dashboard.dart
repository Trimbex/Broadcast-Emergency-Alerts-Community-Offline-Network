import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/voice_command_button.dart';
import '../models/device_model.dart';
import '../providers/app_state_provider.dart';
import 'resource_sharing_page.dart';

class NetworkDashboard extends StatefulWidget {
  const NetworkDashboard({super.key});

  @override
  State<NetworkDashboard> createState() => _NetworkDashboardState();
}

class _NetworkDashboardState extends State<NetworkDashboard> {
  final Color primaryColor = const Color(0xFF898AC4);
  String _selectedRange = '1 km';
  final List<String> _ranges = ['500 m', '1 km', '5 km', '10 km'];
  bool _isScanning = false;

  final List<String> _predefinedMessages = [
    'Need immediate help',
    'Medical assistance required',
    'Safe location found',
    'Resources available',
    'All clear in my area',
  ];

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final mode = args?['mode'] ?? 'join';

    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final connectedDevices = appState.connectedDevices;
        final discoveredPeers = appState.discoveredPeers;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Text(
              mode == 'join' ? 'Emergency Network' : 'Your Network',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isScanning ? Icons.stop : Icons.search,
                  color: Colors.white,
                ),
                onPressed: () => _toggleDiscovery(appState),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: _showRangeSettings,
              ),
            ],
          ),
          body: _buildBody(context, appState, mode, connectedDevices, discoveredPeers),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppStateProvider appState, String mode, 
                     List<DeviceModel> connectedDevices, List discoveredPeers) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF898AC4), Color(0xFFD1C4E9)],
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
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusItem(
                    icon: Icons.wifi,
                    label: 'Status',
                    value: appState.connectionStatus,
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildStatusItem(
                    icon: Icons.people,
                    label: 'Connected',
                    value: '${connectedDevices.length}',
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildStatusItem(
                    icon: Icons.devices,
                    label: 'Discovered',
                    value: '${discoveredPeers.length}',
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
                      onPressed: () => _showNetworkActivities(appState),
                      icon: const Icon(Icons.history),
                      label: const Text('Activities'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResourceSharingPage(),
                        ),
                      ),
                      icon: const Icon(Icons.inventory),
                      label: const Text('Resources'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab selector
            if (discoveredPeers.isNotEmpty || connectedDevices.isNotEmpty)
              DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.white,
                      tabs: const [
                        Tab(text: 'Connected'),
                        Tab(text: 'Discovered'),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: TabBarView(
                        children: [
                          // Connected devices
                          connectedDevices.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No connected devices',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: connectedDevices.length,
                                  itemBuilder: (context, index) {
                                    return _buildDeviceCard(
                                      connectedDevices[index],
                                      appState,
                                    );
                                  },
                                ),
                          // Discovered peers
                          discoveredPeers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'No devices discovered',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () => _toggleDiscovery(appState),
                                        icon: const Icon(Icons.search),
                                        label: const Text('Start Discovery'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: discoveredPeers.length,
                                  itemBuilder: (context, index) {
                                    return _buildDiscoveredPeerCard(
                                      discoveredPeers[index],
                                      appState,
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 64,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No devices found',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start discovery to find nearby devices',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _toggleDiscovery(appState),
                        icon: const Icon(Icons.search),
                        label: const Text('Start Discovery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
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
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: primaryColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(DeviceModel device, AppStateProvider appState) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar box
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, const Color(0xFFB5B6E0)],
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
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        _formatLastSeen(device.lastSeen),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: device.isConnected
                              ? const Color(0xFF4CAF50)
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        device.status,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Disconnect button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () async {
                await appState.removeDevice(device.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${device.name} removed'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveredPeerCard(dynamic peer, AppStateProvider appState) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor,
          child: const Icon(Icons.phone_android, color: Colors.white),
        ),
        title: Text(
          peer.deviceName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Address: ${peer.deviceAddress}'),
        trailing: ElevatedButton(
          onPressed: () => _connectToPeer(peer, appState),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Connect'),
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _toggleDiscovery(AppStateProvider appState) async {
    setState(() {
      _isScanning = !_isScanning;
    });

    if (_isScanning) {
      await appState.startDiscovery();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discovering nearby devices...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await appState.stopDiscovery();
    }
  }

  Future<void> _connectToPeer(dynamic peer, AppStateProvider appState) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Connecting...'),
          ],
        ),
      ),
    );

    final success = await appState.connectToPeer(
      peer.deviceAddress,
      peer.deviceName,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Connected to ${peer.deviceName}'
                : 'Failed to connect to ${peer.deviceName}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showNetworkActivities(AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Activities'),
        content: SizedBox(
          width: double.maxFinite,
          child: appState.networkActivities.isEmpty
              ? const Center(child: Text('No activities yet'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: appState.networkActivities.length,
                  itemBuilder: (context, index) {
                    final activity = appState.networkActivities[index];
                    return ListTile(
                      leading: Icon(_getActivityIcon(activity.activityType)),
                      title: Text(activity.deviceName),
                      subtitle: Text(activity.details ?? activity.activityType),
                      trailing: Text(
                        _formatLastSeen(activity.timestamp),
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'connection':
        return Icons.link;
      case 'disconnection':
        return Icons.link_off;
      case 'resource_shared':
        return Icons.share;
      case 'resource_requested':
        return Icons.request_page;
      case 'message_sent':
        return Icons.message;
      default:
        return Icons.circle;
    }
  }

  void _showRangeSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _ranges.map((range) {
            return ListTile(
              title: Text(range),
              leading: Radio<String>(
                value: range,
                groupValue: _selectedRange,
                onChanged: (value) {
                  setState(() => _selectedRange = value!);
                  Navigator.pop(context);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

}

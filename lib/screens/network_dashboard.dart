import 'package:flutter/material.dart';
import '../widgets/voice_command_button.dart';
import '../models/device_model.dart';

class NetworkDashboard extends StatefulWidget {
  const NetworkDashboard({super.key});

  @override
  State<NetworkDashboard> createState() => _NetworkDashboardState();
}

class _NetworkDashboardState extends State<NetworkDashboard> {
  final Color primaryColor = const Color(0xFF898AC4);
  String _selectedRange = '1 km';
  final List<String> _ranges = ['500 m', '1 km', '5 km', '10 km'];

  // Mock data for connected devices
  final List<DeviceModel> _connectedDevices = [
    DeviceModel(
      id: '1',
      name: 'Sarah Johnson',
      status: 'Active',
      distance: '0.3 km',
      batteryLevel: 85,
    ),
    DeviceModel(
      id: '2',
      name: 'Mike Chen',
      status: 'Active',
      distance: '0.7 km',
      batteryLevel: 60,
    ),
    DeviceModel(
      id: '3',
      name: 'Emergency Center',
      status: 'Online',
      distance: '2.1 km',
      batteryLevel: 100,
    ),
    DeviceModel(
      id: '4',
      name: 'Lisa Rodriguez',
      status: 'Active',
      distance: '1.5 km',
      batteryLevel: 45,
    ),
  ];

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          mode == 'join' ? 'Emergency Network' : 'Your Network',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showRangeSettings,
          ),
        ],
      ),
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
                    label: 'Range',
                    value: _selectedRange,
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildStatusItem(
                    icon: Icons.people,
                    label: 'Connected',
                    value: '${_connectedDevices.length}',
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _buildStatusItem(
                    icon: Icons.signal_cellular_alt,
                    label: 'Signal',
                    value: 'Strong',
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/resources'),
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

            // Devices list or empty message
            Expanded(
              child: _connectedDevices.isEmpty
                  ? const Center(
                      child: Text(
                        'No connected devices yet',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _connectedDevices.length,
                      itemBuilder: (context, index) {
                        return _buildDeviceCard(_connectedDevices[index]);
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

  Widget _buildDeviceCard(DeviceModel device) {
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
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        device.distance,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        device.status,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF9800),
                  size: 20,
                ),
                Text(
                  '${device.batteryLevel}%',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                color: Colors.white,
                iconSize: 20,
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: {'device': device},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showQuickMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Quick Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _predefinedMessages.map((message) {
            return ListTile(
              title: Text(message),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sent: $message'),
                    backgroundColor: Colors.green,
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

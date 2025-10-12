import 'package:flutter/material.dart';
import '../widgets/voice_command_button.dart';
import '../models/device_model.dart';

class NetworkDashboard extends StatefulWidget {
  const NetworkDashboard({super.key});

  @override
  State<NetworkDashboard> createState() => _NetworkDashboardState();
}

class _NetworkDashboardState extends State<NetworkDashboard> {
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final mode = args?['mode'] ?? 'join';

    return Scaffold(
      appBar: AppBar(
        title: Text(mode == 'join' ? 'Emergency Network' : 'Your Network'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Refresh device list
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showRangeSettings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Network Status Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
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
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildStatusItem(
                  icon: Icons.people,
                  label: 'Connected',
                  value: '${_connectedDevices.length}',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildStatusItem(
                  icon: Icons.signal_cellular_alt,
                  label: 'Signal',
                  value: 'Strong',
                ),
              ],
            ),
          ),
          
          // Quick Actions
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
                    onPressed: () => Navigator.pushNamed(context, '/resources'),
                    icon: const Icon(Icons.inventory),
                    label: const Text('Resources'),
                  ),
                ),
              ],
            ),
          ),

          // Connected Devices List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _connectedDevices.length,
              itemBuilder: (context, index) {
                final device = _connectedDevices[index];
                return _buildDeviceCard(device);
              },
            ),
          ),

          // Voice Command Button
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: VoiceCommandButton(),
          ),
        ],
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
        Icon(icon, size: 24, color: const Color(0xFF1976D2)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(DeviceModel device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
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
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        device.distance,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
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
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
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
            return             ListTile(
              title: Text(range),
              leading: Radio<String>(
                value: range,
                groupValue: _selectedRange,
                onChanged: (value) {
                  setState(() {
                    _selectedRange = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                setState(() {
                  _selectedRange = range;
                });
                Navigator.pop(context);
              },
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


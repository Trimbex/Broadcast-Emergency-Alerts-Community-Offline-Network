import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/common/theme_toggle_button.dart';
import '../widgets/network_dashboard/device_card.dart';
import '../widgets/network_dashboard/network_status_indicator.dart';
import '../widgets/network_dashboard/empty_network_state.dart';
import '../widgets/network_dashboard/network_stats_header.dart';
import '../widgets/network_dashboard/quick_actions_bar.dart';
import '../services/p2p_service.dart';
import '../theme/beacon_colors.dart';

class NetworkDashboard extends StatefulWidget {
  const NetworkDashboard({super.key});

  @override
  State<NetworkDashboard> createState() => _NetworkDashboardState();
}

class _NetworkDashboardState extends State<NetworkDashboard> {
  NetworkState _networkState = NetworkState.initializing;
  bool _isRefreshing = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeP2P();
    });
  }

  Future<void> _initializeP2P() async {
    if (!mounted) return;

    setState(() {
      _networkState = NetworkState.initializing;
    });

    try {
      final p2pService = Provider.of<P2PService>(context, listen: false);

      // Initialize with saved user name or default
      final userName = await _getUserName();
      final success = await p2pService.initialize(userName);

      if (!mounted) return;

      if (success) {
        // Start both advertising and discovery for mesh network
        final advertisingSuccess = await p2pService.startAdvertising();
        final discoverySuccess = await p2pService.startDiscovery();

        if (!mounted) return;

        if (advertisingSuccess && discoverySuccess) {
          setState(() {
            _networkState = NetworkState.searching;
          });

          _showSuccessMessage('📡 Network Active - Searching for nearby devices...');
        } else {
          setState(() {
            _networkState = NetworkState.error;
          });
          _showErrorMessage('Failed to start network services');
        }
      } else {
        setState(() {
          _networkState = NetworkState.error;
        });
        _showErrorMessage('Failed to initialize P2P network. Check permissions.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _networkState = NetworkState.error;
      });
      _showErrorMessage('Error: ${e.toString()}');
    }
  }

  Future<String> _getUserName() async {
    try {
      final userProfile = await DatabaseService.instance.getUserProfile();
      return userProfile?['name'] ??
          'User-${DateTime.now().millisecondsSinceEpoch % 10000}';
    } catch (e) {
      return 'User-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BeaconColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: BeaconColors.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _initializeP2P,
        ),
      ),
    );
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
        final isNetworkActive =
            p2pService.isAdvertising && p2pService.isDiscovering;

        // Update state based on network status
        if (_networkState == NetworkState.searching && isNetworkActive) {
          // Network is active, show devices or empty state
        } else if (_networkState == NetworkState.searching && !isNetworkActive) {
          // Network stopped, show error
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _networkState = NetworkState.error;
              });
              _showErrorMessage('Network connection lost');
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              mode == 'join' ? 'Emergency Network' : 'Your Network',
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: NetworkStatusIndicator(isActive: isNetworkActive),
                ),
              ),
              if (_isRefreshing)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isRefreshing ? null : _refreshNetwork,
                  tooltip: 'Refresh Network',
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
                // Stats Header
                const NetworkStatsHeader(),

                // Quick Actions
                if (isNetworkActive && connectedDevices.isNotEmpty)
                  QuickActionsBar(
                    onQuickMessage: _showQuickMessageDialog,
                  ),

                // Devices List or Empty State
                Expanded(
                  child: _buildContent(
                    context,
                    p2pService,
                    connectedDevices,
                    isNetworkActive,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    P2PService p2pService,
    List connectedDevices,
    bool isNetworkActive,
  ) {
    // Show error state if initialization failed
    if (_networkState == NetworkState.error) {
      return EmptyNetworkState(
        state: NetworkState.error,
        onRetry: _initializeP2P,
      );
    }

    // Show initializing state
    if (_networkState == NetworkState.initializing) {
      return const EmptyNetworkState(state: NetworkState.initializing);
    }

    // Show devices list if available
    if (connectedDevices.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshNetwork,
        color: BeaconColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: connectedDevices.length,
          itemBuilder: (context, index) {
            return DeviceCard(
              device: connectedDevices[index],
              p2pService: p2pService,
            );
          },
        ),
      );
    }

    // Show searching state
    return const EmptyNetworkState(state: NetworkState.searching);
  }


  Future<void> _refreshNetwork() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final p2pService = Provider.of<P2PService>(context, listen: false);

      // Restart discovery
      await p2pService.stopDiscovery();
      await Future.delayed(const Duration(milliseconds: 500));
      final success = await p2pService.startDiscovery();

      if (!mounted) return;

      if (success) {
        _showSuccessMessage('🔄 Network refreshed');
      } else {
        _showErrorMessage('Failed to refresh network');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error refreshing: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
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

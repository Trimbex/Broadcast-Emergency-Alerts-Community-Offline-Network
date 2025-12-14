import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/common/theme_toggle_button.dart';
import '../widgets/network_dashboard/device_card.dart';
import '../widgets/network_dashboard/network_status_indicator.dart';
import '../widgets/network_dashboard/empty_network_state.dart' as widget;
import '../widgets/network_dashboard/network_stats_header.dart';
import '../widgets/network_dashboard/quick_actions_bar.dart';
import '../services/p2p_service.dart';
import '../viewmodels/network_dashboard_viewmodel.dart';
import '../theme/beacon_colors.dart';

class NetworkDashboard extends StatefulWidget {
  const NetworkDashboard({super.key});

  @override
  State<NetworkDashboard> createState() => _NetworkDashboardState();
}

class _NetworkDashboardState extends State<NetworkDashboard> {
  NetworkDashboardViewModel? _viewModel;

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

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final mode = args?['mode'] ?? 'join';

    final p2pService = Provider.of<P2PService>(context, listen: false);
    _viewModel = NetworkDashboardViewModel(p2pService: p2pService);

    await _viewModel!.initialize(mode: mode);

    if (!mounted) return;

    if (_viewModel!.networkState == NetworkState.searching) {
      _showSuccessMessage('📡 Network Active - Searching for nearby devices...');
    } else if (_viewModel!.errorMessage != null) {
      _showErrorMessage(_viewModel!.errorMessage!);
    }

    setState(() {}); // Trigger rebuild
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
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider<NetworkDashboardViewModel>.value(
      value: _viewModel!,
      child: Consumer2<NetworkDashboardViewModel, P2PService>(
        builder: (context, viewModel, p2pService, child) {
          final connectedDevices = viewModel.connectedDevices;
          final isNetworkActive = viewModel.isNetworkActive;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                viewModel.mode == 'join' ? 'Emergency Network' : 'Your Network',
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: NetworkStatusIndicator(isActive: isNetworkActive),
                  ),
                ),
                if (viewModel.isRefreshing)
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
                    onPressed: viewModel.isRefreshing ? null : () => _refreshNetwork(viewModel),
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
                      viewModel,
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
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NetworkDashboardViewModel viewModel,
    P2PService p2pService,
    List connectedDevices,
    bool isNetworkActive,
  ) {
    // Show error state if initialization failed
    if (viewModel.networkState == NetworkState.error) {
      return widget.EmptyNetworkState(
        state: widget.NetworkState.error,
        onRetry: _initializeP2P,
      );
    }

    // Show initializing state
    if (viewModel.networkState == NetworkState.initializing) {
      return widget.EmptyNetworkState(state: widget.NetworkState.initializing);
    }

    // Show devices list if available
    if (connectedDevices.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: () => _refreshNetwork(viewModel),
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
    return widget.EmptyNetworkState(state: widget.NetworkState.searching);
  }


  Future<void> _refreshNetwork(NetworkDashboardViewModel viewModel) async {
    await viewModel.refreshNetwork();

    if (!mounted) return;

    if (viewModel.errorMessage != null) {
      _showErrorMessage(viewModel.errorMessage!);
      viewModel.clearError();
    } else {
      _showSuccessMessage('🔄 Network refreshed');
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

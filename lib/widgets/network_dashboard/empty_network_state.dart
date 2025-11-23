import 'package:flutter/material.dart';
import '../../theme/beacon_colors.dart';

enum NetworkState {
  initializing,
  searching,
  error,
}

class EmptyNetworkState extends StatelessWidget {
  final NetworkState state;
  final VoidCallback? onRetry;

  const EmptyNetworkState({
    super.key,
    required this.state,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String title;
    String subtitle;
    Widget action;

    switch (state) {
      case NetworkState.initializing:
        icon = Icons.settings;
        title = 'Initializing Network...';
        subtitle = 'Setting up P2P communication';
        action = const Padding(
          padding: EdgeInsets.only(top: 24),
          child: CircularProgressIndicator(
            color: BeaconColors.primary,
          ),
        );
        break;
      case NetworkState.searching:
        icon = Icons.search;
        title = 'Searching for Devices';
        subtitle = 'Make sure both devices have\nBluetooth and Location enabled';
        action = Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            children: [
              const CircularProgressIndicator(
                color: BeaconColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Waiting for nearby devices...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BeaconColors.textSecondary(context),
                    ),
              ),
            ],
          ),
        );
        break;
      case NetworkState.error:
        icon = Icons.error_outline;
        title = 'Connection Failed';
        subtitle = 'Unable to start P2P network.\nPlease check permissions and try again.';
        action = Padding(
          padding: const EdgeInsets.only(top: 24),
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        );
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BeaconColors.surface(context),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 64,
                color: state == NetworkState.error
                    ? BeaconColors.error
                    : BeaconColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BeaconColors.textSecondary(context),
                  ),
              textAlign: TextAlign.center,
            ),
            action,
          ],
        ),
      ),
    );
  }
}


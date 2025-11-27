import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/beacon_colors.dart';
import '../../services/p2p_service.dart';
import 'stat_item.dart';

class QuickStatsWidget extends StatelessWidget {
  const QuickStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<P2PService>(
      builder: (context, p2pService, child) {
        final connectedCount = p2pService.connectedDevices.length;
        final isActive = p2pService.isAdvertising && p2pService.isDiscovering;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BeaconColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BeaconColors.border(context),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatItem(
                icon: Icons.people_outline,
                label: 'Connected',
                value: '$connectedCount',
                color: connectedCount > 0 ? BeaconColors.success : BeaconColors.textSecondary(context),
              ),
              Container(
                width: 1,
                height: 40,
                color: BeaconColors.border(context),
              ),
              StatItem(
                icon: Icons.network_check,
                label: 'Network',
                value: isActive ? 'Active' : 'Inactive',
                color: isActive ? BeaconColors.success : BeaconColors.warning,
              ),
              Container(
                width: 1,
                height: 40,
                color: BeaconColors.border(context),
              ),
              StatItem(
                icon: Icons.battery_std,
                label: 'Battery',
                value: '${p2pService.batteryLevel}%',
                color: p2pService.batteryLevel > 50 ? BeaconColors.success : BeaconColors.warning,
              ),
            ],
          ),
        );
      },
    );
  }
}


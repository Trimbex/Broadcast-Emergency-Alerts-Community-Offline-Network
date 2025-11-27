import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/p2p_service.dart';
import '../../theme/beacon_colors.dart';
import 'status_item.dart';

class NetworkStatsHeader extends StatelessWidget {
  const NetworkStatsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<P2PService>(
      builder: (context, p2pService, child) {
        final connectedDevices = p2pService.connectedDevices;

        return Container(
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatusItem(
                icon: Icons.people,
                label: 'Connected',
                value: '${connectedDevices.length}',
                color: connectedDevices.isNotEmpty
                    ? BeaconColors.success
                    : BeaconColors.textSecondary(context),
              ),
              Container(
                width: 1,
                height: 40,
                color: BeaconColors.border(context),
              ),
              StatusItem(
                icon: Icons.battery_std,
                label: 'Battery',
                value: '${p2pService.batteryLevel}%',
                color: p2pService.batteryLevel > 50
                    ? BeaconColors.success
                    : BeaconColors.warning,
              ),
            ],
          ),
        );
      },
    );
  }
}


import 'package:flutter/material.dart';
import '../../theme/beacon_colors.dart';

class NetworkStatusIndicator extends StatelessWidget {
  final bool isActive;

  const NetworkStatusIndicator({
    super.key,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? BeaconColors.success : BeaconColors.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


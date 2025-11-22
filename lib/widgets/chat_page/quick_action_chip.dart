import 'package:flutter/material.dart';
import '../../theme/beacon_colors.dart';

class QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isEmergency;
  final VoidCallback onTap;

  const QuickActionChip({
    super.key,
    required this.label,
    required this.icon,
    this.isEmergency = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isEmergency
              ? BeaconColors.error.withOpacity(0.2)
              : BeaconColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEmergency
                ? BeaconColors.error
                : BeaconColors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isEmergency ? BeaconColors.error : BeaconColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isEmergency ? BeaconColors.error : BeaconColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


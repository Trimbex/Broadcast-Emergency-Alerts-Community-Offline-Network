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
    final color = isEmergency ? BeaconColors.error : BeaconColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


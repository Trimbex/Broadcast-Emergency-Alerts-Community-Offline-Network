import 'package:flutter/material.dart';
import 'quick_action_chip.dart';

class QuickActionsBar extends StatelessWidget {
  final VoidCallback onSOS;
  final VoidCallback onLocation;
  final VoidCallback onSafe;

  const QuickActionsBar({
    super.key,
    required this.onSOS,
    required this.onLocation,
    required this.onSafe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          QuickActionChip(
            label: 'SOS',
            icon: Icons.emergency,
            isEmergency: true,
            onTap: onSOS,
          ),
          QuickActionChip(
            label: 'Location',
            icon: Icons.location_on,
            onTap: onLocation,
          ),
          QuickActionChip(
            label: 'Safe',
            icon: Icons.check_circle,
            onTap: onSafe,
          ),
        ],
      ),
    );
  }
}


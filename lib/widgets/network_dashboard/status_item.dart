import 'package:flutter/material.dart';
import '../../theme/beacon_colors.dart';

class StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const StatusItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color ?? BeaconColors.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color ?? BeaconColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}


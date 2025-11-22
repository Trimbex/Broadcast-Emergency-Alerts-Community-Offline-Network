import 'package:flutter/material.dart';
import '../../theme/beacon_colors.dart';

class WelcomeHeader extends StatelessWidget {
  final String? userName;

  const WelcomeHeader({
    super.key,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: BeaconColors.accentGradient(context),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: BeaconColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.emergency_outlined,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName != null ? 'Welcome, $userName!' : 'Welcome to BEACON',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Emergency Communication Network',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BeaconColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


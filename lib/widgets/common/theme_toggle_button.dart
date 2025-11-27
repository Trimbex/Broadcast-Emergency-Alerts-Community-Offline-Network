import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../theme/beacon_colors.dart';

/// A reusable theme toggle button widget
class ThemeToggleButton extends StatelessWidget {
  final bool isCompact;
  final bool showLabel;

  const ThemeToggleButton({
    super.key,
    this.isCompact = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        
        if (isCompact) {
          return IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: BeaconColors.textPrimary(context),
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => themeService.toggleTheme(),
          );
        }

        return ElevatedButton.icon(
          onPressed: () => themeService.toggleTheme(),
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            size: 20,
          ),
          label: showLabel
              ? Text(isDark ? 'Light Mode' : 'Dark Mode')
              : const SizedBox.shrink(),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
    );
  }
}


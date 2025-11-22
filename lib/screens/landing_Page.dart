import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/voice_command_button.dart';
import '../widgets/theme_toggle_button.dart';
import '../theme/beacon_colors.dart';
import '../services/database_service.dart';
import '../services/p2p_service.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final profile = await DatabaseService.instance.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _userName = profile['name']?.toString();
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ThemeToggleButton(isCompact: true),
          SizedBox(width: 8),
        ],
      ),
      floatingActionButton: const VoiceCommandButton(isCompact: false),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Welcome Header
                    _buildWelcomeHeader(),

                    const SizedBox(height: 32),

                    // Main Action Button
                    _buildMainActionButton(context),

                    const SizedBox(height: 24),

                    // Quick Access Grid
                    _buildQuickAccessGrid(context),

                    const SizedBox(height: 24),

                    // Quick Stats
                    _buildQuickStats(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
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
                _userName != null ? 'Welcome, $_userName!' : 'Welcome to BEACON',
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

  Widget _buildMainActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/network_dashboard',
            arguments: {'mode': 'join'},
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.group_add, size: 24),
            SizedBox(width: 12),
            Text(
              'Join Communication Network',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessCard(
                context,
                icon: Icons.person,
                label: 'Profile',
                color: BeaconColors.primary,
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickAccessCard(
                context,
                icon: Icons.inventory_2,
                label: 'Resources',
                color: BeaconColors.secondary,
                onTap: () => Navigator.pushNamed(context, '/resources'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: BeaconColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: BeaconColors.border(context),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
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
              _buildStatItem(
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
              _buildStatItem(
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
              _buildStatItem(
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

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

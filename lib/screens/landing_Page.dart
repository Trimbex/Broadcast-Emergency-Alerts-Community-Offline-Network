import 'package:flutter/material.dart';
import '../widgets/common/voice_command_button.dart';
import '../widgets/common/theme_toggle_button.dart';
import '../widgets/landing_page/welcome_header.dart';
import '../widgets/landing_page/quick_access_card.dart';
import '../widgets/landing_page/quick_stats_widget.dart';
import '../theme/beacon_colors.dart';
import '../services/database_service.dart';

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
        actions: const [ThemeToggleButton(isCompact: true), SizedBox(width: 8)],
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
                    WelcomeHeader(userName: _userName),

                    const SizedBox(height: 32),

                    // Main Action Button
                    _buildMainActionButton(context),

                    const SizedBox(height: 24),

                    // Quick Access Grid
                    _buildQuickAccessGrid(context),

                    const SizedBox(height: 24),

                    // Quick Stats
                    const QuickStatsWidget(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: QuickAccessCard(
                icon: Icons.person,
                label: 'Profile',
                color: BeaconColors.primary,
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickAccessCard(
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
}

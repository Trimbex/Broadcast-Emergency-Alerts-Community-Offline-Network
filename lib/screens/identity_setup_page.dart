import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/common/theme_toggle_button.dart';
import '../theme/beacon_colors.dart';

class IdentitySetupPage extends StatefulWidget {
  const IdentitySetupPage({super.key});

  @override
  State<IdentitySetupPage> createState() => _IdentitySetupPageState();
}

class _IdentitySetupPageState extends State<IdentitySetupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkIfIdentityExists();
  }

  // If identity already exists, skip this page
  Future<void> _checkIfIdentityExists() async {
    final userProfile = await DatabaseService.instance.getUserProfile();
    if (userProfile != null && userProfile['name'] != null) {
      // Automatically go to landing page
        if (mounted) {
          Future.delayed(Duration.zero, () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/landing');
            }
          });
        }
    }
  }

  Future<void> _saveIdentity() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your name or nickname.'),
          backgroundColor: BeaconColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Generate a persistent device ID
    final deviceId = DateTime.now().millisecondsSinceEpoch.toString();

    await DatabaseService.instance.saveUserProfile(
      name: _nameController.text.trim(),
      deviceId: deviceId,
      role: _roleController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/landing');
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // Logo Circle (same as landing page)
              Container(
                padding: const EdgeInsets.all(28),
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
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 80,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Set Up Your Identity',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(letterSpacing: 1.2),
              ),

              const SizedBox(height: 10),

              Text(
                'This helps others recognize you in the network.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 40),

              // Name Input
              _buildTextField(
                controller: _nameController,
                label: 'Your Name / Nickname',
                icon: Icons.person,
              ),

              const SizedBox(height: 20),

              // Role Input
              _buildTextField(
                controller: _roleController,
                label: 'Emergency Role or Note (optional)',
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 40),

              // Save & Continue Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveIdentity,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(_isSaving ? 'Saving...' : 'Save & Continue'),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Your information stays only on your device.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Modern TextField ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: BeaconColors.textSecondary(context)),
        labelText: label,
      ),
    );
  }
}

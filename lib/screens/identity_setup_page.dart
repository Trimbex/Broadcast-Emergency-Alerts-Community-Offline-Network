import 'package:flutter/material.dart';
import '../services/database_service.dart';

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
          Navigator.pushReplacementNamed(context, '/landing');
        });
      }
    }
  }

  Future<void> _saveIdentity() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name or nickname.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    // Generate a persistent device ID
    final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
    
    await DatabaseService.instance.saveUserProfile(
      _nameController.text.trim(),
      _roleController.text.trim(),
      deviceId,
    );
    
    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF898AC4),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF3F3F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 80,
                  color: Color(0xFFFF5F6D),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Set Up Your Identity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'This helps others recognize you in the network.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.white70,
                ),
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
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save & Continue',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1976D2),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Your information stays only on your device.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
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
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Poppins',
        fontSize: 15,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white54, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }
}

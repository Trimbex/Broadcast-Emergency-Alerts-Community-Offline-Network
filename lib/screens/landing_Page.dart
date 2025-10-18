import 'package:flutter/material.dart';
import '../widgets/voice_command_button.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF898AC4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Logo Circle
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
                  Icons.emergency_outlined,
                  size: 80,
                  color: Color(0xFFFF5F6D),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'BEACON',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle
              const Text(
                'Emergency Communication Network',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 40),

              // Action Buttons
              _buildActionButton(
                context,
                icon: Icons.group_add,
                label: 'Join Communication',
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/network-dashboard',
                    arguments: {'mode': 'join'},
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context,
                icon: Icons.emergency_share,
                label: 'Start New Communication',
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/network-dashboard',
                    arguments: {'mode': 'initiate'},
                  );
                },
              ),

              const SizedBox(height: 36),

              // Quick Access Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAccessIcon(
                    context,
                    icon: Icons.inventory,
                    label: 'Resources',
                    onTap: () => Navigator.pushNamed(context, '/resources'),
                  ),
                  _buildQuickAccessIcon(
                    context,
                    icon: Icons.person,
                    label: 'Profile',
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Voice Command Button
              const VoiceCommandButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Modern Action Button ---
  static Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
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
    );
  }

  // --- Compact Quick Access Icon ---
  static Widget _buildQuickAccessIcon(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: const Color(0xFF1976D2)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

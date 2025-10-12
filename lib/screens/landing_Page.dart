import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          
        color : Color(0xFF898AC4), 
          
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Circle 
                Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white, // solid white
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emergency_outlined,
                    size: 100,
                    color: Color(0xFFFF5F6D), 
                  ),
                ),

                const SizedBox(height: 50),

                // Title
                const Text(
                  'BEACON',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 10,
                    fontFamily: 'Montserrat',
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                const Text(
                  'Emergency Communication Network',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 80),


                Column(
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.group_add,
                      label: 'Join Emergency Communication',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/network-dashboard',
                          arguments: {'mode': 'join'},
                        );
                      },
                    ),

                    const SizedBox(height:20),
                    _buildActionButton(
                      context,
                      icon: Icons.emergency_share,
                      label: 'Initiate New Communication',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/network-dashboard',
                          arguments: {'mode': 'initiate'},
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: const Color(0xFF1976D2),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1976D2),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}


  
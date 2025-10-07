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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

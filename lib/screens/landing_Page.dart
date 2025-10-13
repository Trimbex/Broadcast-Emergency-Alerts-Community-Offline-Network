import 'package:flutter/material.dart';
import 'network_dashboard.dart'; // make sure this import is correct

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF898AC4),
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

                // Start Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NetworkDashboard(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5F6D),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black45,
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
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

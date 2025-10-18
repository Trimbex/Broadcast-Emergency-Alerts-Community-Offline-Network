import 'package:flutter/material.dart';
import 'screens/landing_Page.dart';
import 'screens/identity_setup_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beacon Network',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      // 👇 Define routes here
      initialRoute: '/identity',
      routes: {
        '/identity': (context) => const IdentitySetupPage(),
        '/landing': (context) => const LandingPage(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/landing_Page.dart';
import 'screens/identity_setup_page.dart';
import 'screens/resource_sharing_page.dart';
import 'screens/profile_page.dart';
import 'screens/network_dashboard.dart';
import 'services/p2p_service.dart';
import 'services/theme_service.dart';
import 'theme/beacon_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => P2PService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'BEACON - Emergency Network',
            debugShowCheckedModeBanner: false,
            theme: beaconLightTheme,
            darkTheme: beaconDarkTheme,
            themeMode: themeService.themeMode,

            // 👇 Define routes here
            initialRoute: '/identity',
            routes: {
              '/identity': (context) => const IdentitySetupPage(),
              '/landing': (context) => const LandingPage(),
              '/resources': (context) => ResourceSharingPage(),
              '/profile': (context) => const ProfilePage(),
              '/network_dashboard': (context) => const NetworkDashboard(),
            },
          );
        },
      ),
    );
  }
}

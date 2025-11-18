import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/landing_Page.dart';
import 'screens/identity_setup_page.dart';
import 'screens/resource_sharing_page.dart';
import 'screens/profile_page.dart';
import 'screens/network_dashboard.dart';
import 'providers/app_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppStateProvider()..initialize(),
      child: MaterialApp(
        title: 'BEACON Network',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        // Define routes here
        initialRoute: '/identity',
        routes: {
          '/identity': (context) => const IdentitySetupPage(),
          '/landing': (context) => const LandingPage(),
          '/resources': (context) => const ResourceSharingPage(),
          '/profile': (context) => const ProfilePage(),
          '/network_dashboard': (context) => const NetworkDashboard(),
        },
      ),
    );
  }
}

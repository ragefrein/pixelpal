import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/wifi_setup_screen.dart';
import 'screens/main_layout.dart';
import 'providers/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedIp = prefs.getString('esp_ip');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(initialIp: savedIp)),
      ],
      child: PixelPalApp(hasSavedIp: savedIp != null && savedIp.isNotEmpty),
    ),
  );
}

class PixelPalApp extends StatelessWidget {
  final bool hasSavedIp;
  const PixelPalApp({super.key, required this.hasSavedIp});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PixelPal Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6B48FF),
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161824),
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161824),
          selectedItemColor: Color(0xFF6B48FF),
          unselectedItemColor: Colors.grey,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: hasSavedIp ? const MainLayout() : const WifiSetupScreen(),
    );
  }
}

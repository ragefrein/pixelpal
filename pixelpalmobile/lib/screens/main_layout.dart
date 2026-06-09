import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'dashboard_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.espIp != '192.168.4.1') {
        appState.connectToWiFi();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DashboardScreen(),
    );
  }
}

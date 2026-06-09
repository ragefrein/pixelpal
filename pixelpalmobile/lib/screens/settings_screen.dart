import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsTile(
            icon: Icons.api,
            title: 'Telegram Bot API Token',
            subtitle: 'Configure your bot token here',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.bluetooth_audio,
            title: 'Bluetooth Settings',
            subtitle: 'Manage paired devices',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.wifi_tethering,
            title: 'ESP32 IP Address',
            subtitle: '192.168.4.1 (Default)',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF6B48FF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6B48FF)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
      trailing: const Icon(Icons.chevron_right),
      tileColor: const Color(0xFF1E2130),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onTap: onTap,
    );
  }
}

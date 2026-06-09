import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'wifi_setup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _botTokenController = TextEditingController();

  @override
  void dispose() {
    _botTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PixelPal Control', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2130),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: appState.isConnected ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (appState.isConnected ? Colors.green : Colors.red).withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    appState.isConnected ? Icons.check_circle_outline : Icons.error_outline,
                    color: appState.isConnected ? Colors.green : Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    appState.isConnected ? 'Connected to ${appState.deviceName}' : 'Disconnected',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appState.isConnected ? 'via ${appState.connectionType}' : 'Please connect to your PixelPal',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Connection Actions
            if (!appState.isConnected) ...[
              const Text('Connect Using', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connecting to WiFi...')));
                    final appState = context.read<AppState>();
                    await appState.connectToWiFi();
                    if (!appState.isConnected && context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const WifiSetupScreen()),
                      );
                    }
                  },
                  icon: const Icon(Icons.wifi),
                  label: const Text('Connect via WiFi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B48FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ] else ...[
              const Text('Quick Expressions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildExpressionBtn(context, Icons.sentiment_satisfied_alt, 'Smile', 'smile', Colors.green),
                  _buildExpressionBtn(context, Icons.sentiment_neutral, 'Normal', 'normal', Colors.blue),
                  _buildExpressionBtn(context, Icons.remove_red_eye, 'Blink', 'blink', Colors.orange),
                  _buildExpressionBtn(context, Icons.swipe_left, 'Look Left', 'left', Colors.purple),
                  _buildExpressionBtn(context, Icons.swipe_right, 'Look Right', 'right', Colors.purple),
                  _buildExpressionBtn(context, Icons.autorenew, 'Auto Mode', 'auto', Colors.teal),
                  _buildExpressionBtn(context, Icons.info_outline, 'Info Mode', 'info', Colors.amber),
                  _buildExpressionBtn(context, Icons.face, 'Face Mode', 'face', Colors.pink),
                ],
              ),
              const SizedBox(height: 30),
              const Text('Pengaturan Jaringan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'PixelPal IP',
                        filled: true,
                        fillColor: Color(0xFF1E2130),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                      ),
                      controller: TextEditingController(text: appState.espIp)..selection = TextSelection.collapsed(offset: appState.espIp.length),
                      onSubmitted: (val) {
                        context.read<AppState>().setEspIp(val);
                      },
                      onChanged: (val) {
                        context.read<AppState>().setEspIp(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AppState>().connectToWiFi();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mencoba terhubung...')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B48FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kirim Alamat IP'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Telegram Bot Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _botTokenController,
                      decoration: const InputDecoration(
                        labelText: 'Bot Token (e.g. 1234:ABC...)',
                        filled: true,
                        fillColor: Color(0xFF1E2130),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (val) {
                        context.read<AppState>().sendCommand('bot:$val');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bot Token dikirim!')));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final val = _botTokenController.text;
                      if (val.isNotEmpty) {
                        context.read<AppState>().sendCommand('bot:$val');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bot Token dikirim!')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B48FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kirim'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    context.read<AppState>().clearEspIp();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const WifiSetupScreen()),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset WiFi / IP'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpressionBtn(BuildContext context, IconData icon, String label, String cmd, Color color) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 20),
      label: Text(label),
      backgroundColor: const Color(0xFF202336),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      onPressed: () {
        context.read<AppState>().sendCommand(cmd);
      },
    );
  }
}

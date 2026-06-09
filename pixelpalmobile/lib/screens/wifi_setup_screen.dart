import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'main_layout.dart';

class WifiSetupScreen extends StatefulWidget {
  const WifiSetupScreen({super.key});

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  int _currentStep = 0;
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _sendWifiCredentials() async {
    if (_ssidController.text.isNotEmpty) {
      final cmd = 'wifi:${_ssidController.text}:${_passController.text}';
      
      // Force connected state temporarily to send the setup command
      context.read<AppState>().setConnectedForSetup();
      await context.read<AppState>().sendCommand(cmd);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kredensial WiFi berhasil dikirim ke PixelPal!')),
      );
    }
    _nextStep(); // Go to Step 3
  }

  void _completeSetup() {
    if (_ipController.text.isNotEmpty) {
      context.read<AppState>().setEspIp(_ipController.text);
    }
    // Navigate to Main Dashboard
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainLayout()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup PixelPal WiFi', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainLayout()),
              );
            },
            child: const Text('Lewati', style: TextStyle(color: Colors.white70)),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentStep >= 0 ? const Color(0xFF6B48FF) : Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentStep >= 1 ? const Color(0xFF6B48FF) : Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentStep >= 2 ? const Color(0xFF6B48FF) : Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              _currentStep == 0 
                  ? _buildStep1() 
                  : (_currentStep == 1 ? _buildStep2() : _buildStep3()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.wifi_tethering, size: 80, color: Color(0xFF6B48FF)),
        const SizedBox(height: 24),
        const Text(
          'Langkah 1: Hubungkan ke PixelPal',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Silakan keluar dari aplikasi sebentar dan buka Pengaturan WiFi di HP Anda.',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2130),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6B48FF).withOpacity(0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hubungkan ke WiFi berikut:', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('Nama WiFi : PixelPal_ESP32', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Password   : pixelpal_pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B48FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Lanjutkan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.router, size: 80, color: Color(0xFF6B48FF)),
        const SizedBox(height: 24),
        const Text(
          'Langkah 2: Beri Akses Internet',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Masukkan WiFi rumah/kantor Anda agar PixelPal bisa terhubung ke jaringan internet yang sama dengan Anda.',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _ssidController,
          decoration: InputDecoration(
            labelText: 'Nama WiFi (SSID)',
            filled: true,
            fillColor: const Color(0xFF1E2130),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password WiFi',
            filled: true,
            fillColor: const Color(0xFF1E2130),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _sendWifiCredentials,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B48FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Kirim ke PixelPal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              setState(() => _currentStep--);
            },
            child: const Text('Kembali', style: TextStyle(fontSize: 16, color: Colors.white70)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.important_devices, size: 80, color: Color(0xFF6B48FF)),
        const SizedBox(height: 24),
        const Text(
          'Langkah 3: Masukkan Alamat IP',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Silakan hubungkan HP Anda ke WiFi rumah/kantor yang sama. Lalu lihat layar PixelPal Anda, catat alamat IP yang muncul (misal: 192.168.1.15), dan masukkan di bawah ini.',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _ipController,
          decoration: InputDecoration(
            labelText: 'Alamat IP PixelPal',
            filled: true,
            fillColor: const Color(0xFF1E2130),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _completeSetup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B48FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Mulai PixelPal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  bool _isConnected = false;
  String _deviceName = '';
  String _connectionType = 'None';
  String _espIp = '192.168.4.1'; // Default IP when acting as AP

  AppState({String? initialIp}) {
    if (initialIp != null && initialIp.isNotEmpty) {
      _espIp = initialIp;
    }
  }

  bool get isConnected => _isConnected;
  String get connectionType => _connectionType;
  String get deviceName => _deviceName;
  String get espIp => _espIp;

  void setEspIp(String ip) async {
    _espIp = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp_ip', ip);
    notifyListeners();
  }

  void clearEspIp() async {
    _espIp = '192.168.4.1';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('esp_ip');
    disconnect();
    notifyListeners();
  }

  void setConnectedForSetup() {
    _isConnected = true;
    _connectionType = 'WiFi';
    notifyListeners();
  }

  Future<void> connectToWiFi() async {
    try {
      final response = await http.get(Uri.parse('http://$_espIp/')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        _isConnected = true;
        _connectionType = 'WiFi';
        _deviceName = 'PixelPal-ESP32 (WiFi)';
        notifyListeners();
      }
    } catch (e) {
      print("WiFi Connection Error: $e");
    }
  }

  Future<void> sendCommand(String cmd) async {
    if (!_isConnected) return;

    if (_connectionType == 'WiFi') {
      try {
        await http.get(Uri.parse('http://$_espIp/api?cmd=$cmd'));
      } catch (e) {
        print("HTTP command failed: $e");
      }
    }
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _connectionType = 'None';
    _deviceName = '';
    notifyListeners();
  }
}

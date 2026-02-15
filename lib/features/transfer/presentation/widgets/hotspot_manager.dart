import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:android_intent_plus/android_intent_plus.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';

class HotspotManager extends StatefulWidget {
  final Function(String ip) onConnected;

  const HotspotManager({super.key, required this.onConnected});

  @override
  State<HotspotManager> createState() => _HotspotManagerState();
}

class _HotspotManagerState extends State<HotspotManager> {
  final NetworkInfo _networkInfo = NetworkInfo();
  String? _wifiName;
  String? _ipAddress;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    try {
      var wifiName = await _networkInfo.getWifiName();
      var ip = await _networkInfo.getWifiIP();
      
      // Clean up SSID (remove quotes on Android)
      if (wifiName != null) {
        wifiName = wifiName.replaceAll('"', '');
      }

      setState(() {
        _wifiName = wifiName;
        _ipAddress = ip;
      });

      if (ip != null && ip.isNotEmpty && ip != '0.0.0.0') {
        widget.onConnected(ip);
      }
    } catch (e) {
      print("Error checking WiFi: $e");
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _openHotspotSettings() async {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.settings.TETHER_SETTINGS',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_tethering, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              "Hotspot Mode",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              "No WiFi router? Create a hotspot!",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            if (_ipAddress == null) ...[
               ElevatedButton.icon(
                onPressed: _openHotspotSettings,
                icon: const Icon(Icons.settings),
                label: const Text("Open Hotspot Settings"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _checkConnection,
                icon: const Icon(Icons.refresh),
                label: const Text("Check Status"),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(height: 8),
                    Text(
                      "Hotspot Active!",
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    Text("IP: $_ipAddress"),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

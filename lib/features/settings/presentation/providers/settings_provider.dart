import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

const String _wakelockEnabledKey = 'wakelock_enabled';
const String _highPerformanceModeKey = 'high_performance_mode';

final settingsProvider = Provider<SettingsProvider>((ref) {
  return SettingsProvider();
});

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;

  bool _isWakelockEnabled = true;
  bool _isHighPerformanceModeEnabled = false;

  bool get isWakelockEnabled => _isWakelockEnabled;
  bool get isHighPerformanceModeEnabled => _isHighPerformanceModeEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _isWakelockEnabled = _prefs.getBool(_wakelockEnabledKey) ?? true;
    _isHighPerformanceModeEnabled =
        _prefs.getBool(_highPerformanceModeKey) ?? false;
    notifyListeners();
  }

  Future<void> setWakelock(bool enabled) async {
    _isWakelockEnabled = enabled;
    await _prefs.setBool(_wakelockEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setHighPerformanceMode(bool enabled) async {
    if (enabled) {
      // Request permissions for high performance mode on Android
      await _requestHighPerformancePermissions();
    }
    _isHighPerformanceModeEnabled = enabled;
    await _prefs.setBool(_highPerformanceModeKey, enabled);
    notifyListeners();
  }

  /// Request required Android permissions for high performance mode
  /// Includes location for WiFi band preference (5GHz if available)
  Future<void> _requestHighPerformancePermissions() async {
    if (!Platform.isAndroid) return;

    // Request location permission to enable WiFi band preferences
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Key for storing theme mode in SharedPreferences
const String _themeKey = "theme_mode";

// Provider for the ThemeNotifier
final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<ThemeMode> {
  ThemeNotifier() {
    _loadTheme();
  }

  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  // Toggle theme and persist the change
  void toggleTheme(ThemeMode mode) {
    state = mode;
    _saveTheme(mode);
  }

  // Load theme from local storage
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final int? themeIndex = prefs.getInt(_themeKey);

    if (themeIndex != null) {
      state = ThemeMode.values[themeIndex];
    }
  }

  // Persist theme to local storage
  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }
}

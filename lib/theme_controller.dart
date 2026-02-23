import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light);

  static const _themeModeKey = 'theme_mode';

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeModeKey);

    switch (raw) {
      case 'dark':
        value = ThemeMode.dark;
        break;
      case 'light':
      default:
        value = ThemeMode.light;
        break;
    }
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = mode == ThemeMode.dark ? 'dark' : 'light';
    await prefs.setString(_themeModeKey, raw);
  }

  Future<void> setTheme(ThemeMode mode) async {
    value = mode;
    await _saveTheme(mode);
  }

  Future<void> toggle() async {
    final next = (value == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    await setTheme(next);
  }
}

final themeController = ThemeController();

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const _prefKey = 'theme_mode';

  ThemeMode _mode;

  ThemeNotifier._(this._mode);

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name); // 'system' | 'light' | 'dark'
  }

  static Future<ThemeNotifier> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    ThemeMode mode;
    switch (saved) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }
    final notifier = ThemeNotifier._(mode);
    _instance = notifier;
    return notifier;
  }

  // Global singleton — set once in main() after load()
  static ThemeNotifier? _instance;
  static ThemeNotifier get instance => _instance!;
}

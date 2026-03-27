import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart'; // enum UserRole

class ThemeProvider extends ChangeNotifier {
  static String _keyFor(UserRole? role) {
    if (role == null) return 'theme_mode_guest';
    switch (role) {
      case UserRole.admin:
        return 'theme_mode_admin';
      case UserRole.hotelOwner:
        return 'theme_mode_owner';
      case UserRole.user:
        return 'theme_mode_user';
    }
  }

  // ✅ default theo mockup:
  // - Admin: dark
  // - Owner/User: light
  // - Guest: system
  static String _defaultValueForKey(String key) {
    switch (key) {
      case 'theme_mode_admin':
        return 'dark';
      case 'theme_mode_owner':
      case 'theme_mode_user':
        return 'light';
      default:
        return 'system';
    }
  }

  final Map<String, ThemeMode> _modes = {};

  UserRole? _currentRole; // null = guest
  UserRole? get currentRole => _currentRole;

  /// themeMode hiện tại theo role đang active
  ThemeMode get mode => _modes[_keyFor(_currentRole)] ?? ThemeMode.system;

  void setCurrentRole(UserRole? role) {
    if (_currentRole == role) return;
    _currentRole = role;
    notifyListeners();
  }

  bool isDark(BuildContext context) {
    final m = mode;
    if (m == ThemeMode.dark) return true;
    if (m == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    Future<void> loadKey(String key) async {
      final v = prefs.getString(key) ?? _defaultValueForKey(key);
      _modes[key] = switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    }

    await loadKey(_keyFor(null));
    await loadKey(_keyFor(UserRole.user));
    await loadKey(_keyFor(UserRole.hotelOwner));
    await loadKey(_keyFor(UserRole.admin));

    notifyListeners();
  }

  Future<void> setModeFor(UserRole? role, ThemeMode mode) async {
    final key = _keyFor(role);
    _modes[key] = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString(key, v);
  }

  Future<void> toggleFor(UserRole? role, BuildContext context) async {
    final key = _keyFor(role);
    final current = _modes[key] ?? ThemeMode.system;

    final nowDark = (current == ThemeMode.dark)
        ? true
        : (current == ThemeMode.light)
        ? false
        : (MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    await setModeFor(role, nowDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> toggle(BuildContext context) async {
    await toggleFor(_currentRole, context);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options for display
enum AppThemeMode {
  light('Light'),
  dark('Dark'),
  system('System');

  final String label;
  const AppThemeMode(this.label);

  /// Convert to Flutter ThemeMode
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Create from Flutter ThemeMode
  static AppThemeMode fromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
      case ThemeMode.system:
        return AppThemeMode.system;
    }
  }
}

/// Theme Mode Provider
/// Manages dark/light/system theme switching with persistence
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Provider for the app theme mode (includes system option)
final appThemeModeProvider = StateNotifierProvider<AppThemeModeNotifier, AppThemeMode>((ref) {
  return AppThemeModeNotifier(ref);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  /// Called by AppThemeModeNotifier to sync the theme
  void setTheme(ThemeMode mode) {
    state = mode;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setTheme(newMode);
  }

  bool get isDark => state == ThemeMode.dark;
}

class AppThemeModeNotifier extends StateNotifier<AppThemeMode> {
  static const String _themeKey = 'theme_mode';
  final Ref _ref;
  bool _initialized = false;

  AppThemeModeNotifier(this._ref) : super(AppThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);

    if (themeIndex != null && themeIndex >= 0 && themeIndex < AppThemeMode.values.length) {
      state = AppThemeMode.values[themeIndex];
    }

    // Only sync with ThemeNotifier after we've loaded
    _ref.read(themeProvider.notifier).setTheme(state.toThemeMode());
    _initialized = true;
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    // Sync with ThemeNotifier
    _ref.read(themeProvider.notifier).setTheme(mode.toThemeMode());
  }
}

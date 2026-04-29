import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _restoreThemeMode();
  }

  static const String _themeModeKey = 'theme_mode';

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _serialize(mode));
  }

  Future<void> _restoreThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(_themeModeKey);
    final restored = _deserialize(storedMode);
    if (restored != state) {
      state = restored;
    }
  }

  String _serialize(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  ThemeMode _deserialize(String? rawMode) => switch (rawMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}

String themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };

ThemeMode? themeModeFromLabel(String label) => switch (label) {
      'Light' => ThemeMode.light,
      'Dark' => ThemeMode.dark,
      'System' => ThemeMode.system,
      _ => null,
    };

List<ThemeMode> get supportedThemeModes => const [
      ThemeMode.system,
      ThemeMode.light,
      ThemeMode.dark,
    ];

final themeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

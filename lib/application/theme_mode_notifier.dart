import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier that manages app ThemeMode and persists to SharedPreferences.
///
/// It exposes the current [ThemeMode] and allows updating it via [setMode].
/// Persisted under [storageKey] with values: 'system', 'light', 'dark'.
class ThemeModeNotifier extends ChangeNotifier {
  /// Key used in SharedPreferences storage.
  static const String storageKey = 'theme_mode';

  ThemeMode _mode;
  final SharedPreferences _prefs;

  /// Create a notifier with the given [SharedPreferences] and [initialMode].
  ThemeModeNotifier(this._prefs, ThemeMode initialMode) : _mode = initialMode;

  /// Current theme mode.
  ThemeMode get mode => _mode;

  /// Update theme mode and persist the change.
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setString(storageKey, _mode.name);
  }

  /// Parse a stored string into a [ThemeMode]. Defaults to [ThemeMode.system].
  static ThemeMode parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

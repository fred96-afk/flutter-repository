import 'package:flutter/material.dart';
import 'package:polleria_movil/data/app_storage.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme([BuildContext? context]) {
    if (context != null && _themeMode == ThemeMode.system) {
      final currentBrightness = MediaQuery.platformBrightnessOf(context);
      _themeMode = currentBrightness == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    } else {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    }
    AppStorage.setThemeMode(_themeMode);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode, {bool persist = true}) {
    final changed = _themeMode != mode;
    _themeMode = mode;
    if (persist) {
      AppStorage.setThemeMode(mode);
    }
    if (changed) {
      notifyListeners();
    }
  }
}

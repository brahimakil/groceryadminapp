import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/services/dark_them_preferences.dart';

class DarkThemeProvider with ChangeNotifier {
  bool _darkTheme = false;
  DarkThemePreference darkThemePreference = DarkThemePreference();

  bool get darkTheme => _darkTheme;

  Future<void> loadThemePreferences() async {
    _darkTheme = await darkThemePreference.getTheme();
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _darkTheme = value;
    await darkThemePreference.setDarkTheme(value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
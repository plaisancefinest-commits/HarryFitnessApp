import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

enum AppThemeChoice { cream, carabinero }

/// Holds the selected visual theme and persists it across launches.
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'app_theme';

  AppThemeChoice _choice = AppThemeChoice.cream;
  AppThemeChoice get choice => _choice;

  AppColors get palette => _choice == AppThemeChoice.carabinero
      ? AppColors.carabinero
      : AppColors.cream;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == AppThemeChoice.carabinero.name) {
      _choice = AppThemeChoice.carabinero;
      notifyListeners();
    }
  }

  Future<void> setChoice(AppThemeChoice choice) async {
    if (choice == _choice) return;
    _choice = choice;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, choice.name);
  }
}

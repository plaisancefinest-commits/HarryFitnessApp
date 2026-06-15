import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

enum AppThemeChoice { cream, blackGold, carabinero, knicks }

/// Holds the selected visual theme and persists it across launches.
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'app_theme';

  AppThemeChoice _choice = AppThemeChoice.cream;
  AppThemeChoice get choice => _choice;

  AppColors get palette {
    switch (_choice) {
      case AppThemeChoice.blackGold:
        return AppColors.blackGold;
      case AppThemeChoice.carabinero:
        return AppColors.carabinero;
      case AppThemeChoice.knicks:
        return AppColors.knicks;
      case AppThemeChoice.cream:
        return AppColors.cream;
    }
  }

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    for (final c in AppThemeChoice.values) {
      if (saved == c.name) {
        _choice = c;
        notifyListeners();
        break;
      }
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

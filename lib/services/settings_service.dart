import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _titleKey = 'app_title';
  static const String _colorKey = 'app_theme_color';

  String _appTitle = 'Ajandam';
  Color _themeColor = const Color(0xFF673AB7); // Default Deep Purple

  String get appTitle => _appTitle;
  Color get themeColor => _themeColor;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Title
    _appTitle = prefs.getString(_titleKey) ?? 'Ajandam';
    
    // Load Color
    final colorValue = prefs.getInt(_colorKey);
    if (colorValue != null) {
      _themeColor = Color(colorValue);
    }
    
    notifyListeners();
  }

  Future<void> setAppTitle(String title) async {
    if (title.isEmpty) return;
    _appTitle = title;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_titleKey, title);
  }

  Future<void> setThemeColor(Color color) async {
    _themeColor = color;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.value);
  }
}

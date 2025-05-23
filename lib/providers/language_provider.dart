import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String _langKey = 'isBangla';
  bool _isBangla = false;

  bool get isBangla => _isBangla;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _isBangla = prefs.getBool(_langKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _isBangla = !_isBangla;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_langKey, _isBangla);
    notifyListeners();
  }

  Future<void> setLanguage(bool value) async {
    _isBangla = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_langKey, value);
    notifyListeners();
  }
}

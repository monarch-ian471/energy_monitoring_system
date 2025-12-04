import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en', '');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  /// Load saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'en';
      _locale = Locale(languageCode, '');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading locale: $e');
    }
  }

  /// Change locale and save to SharedPreferences
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  /// Toggle between English and Chichewa
  Future<void> toggleLocale() async {
    if (_locale.languageCode == 'en') {
      await setLocale(const Locale('ny', ''));
    } else {
      await setLocale(const Locale('en', ''));
    }
  }

  /// Get display name for current locale
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'ny':
        return 'Chichewa';
      default:
        return 'English';
    }
  }

  /// Get flag emoji for current locale
  String get currentLanguageFlag {
    switch (_locale.languageCode) {
      case 'en':
        return '🇺🇸';
      case 'ny':
        return '🇲🇼';
      default:
        return '🇺🇸';
    }
  }
}

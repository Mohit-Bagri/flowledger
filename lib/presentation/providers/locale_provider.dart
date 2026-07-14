import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages with their display names
class SupportedLanguage {
  final String code;
  final String name;
  final String nativeName;

  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  Locale get locale => Locale(code);
}

/// All supported languages in the app
class SupportedLanguages {
  static const List<SupportedLanguage> all = [
    SupportedLanguage(code: 'en', name: 'English', nativeName: 'English'),
    SupportedLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    SupportedLanguage(code: 'es', name: 'Spanish', nativeName: 'Español'),
    SupportedLanguage(code: 'fr', name: 'French', nativeName: 'Français'),
    SupportedLanguage(code: 'de', name: 'German', nativeName: 'Deutsch'),
    SupportedLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
    SupportedLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
    SupportedLanguage(code: 'zh', name: 'Chinese', nativeName: '中文'),
    SupportedLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語'),
    SupportedLanguage(code: 'ko', name: 'Korean', nativeName: '한국어'),
    SupportedLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский'),
    SupportedLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano'),
  ];

  /// Get all supported locales
  static List<Locale> get supportedLocales => all.map((l) => l.locale).toList();

  /// Get a language by code
  static SupportedLanguage? getByCode(String code) {
    try {
      return all.firstWhere((l) => l.code == code);
    } catch (_) {
      return null;
    }
  }
}

/// Locale Provider
/// Manages the selected locale with persistence
/// null means system default
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale?> {
  static const String _localeKey = 'selected_locale';

  LocaleNotifier() : super(null) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null) {
      state = Locale(code);
    }
  }

  /// Set a specific locale (or null for system default)
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale != null) {
      await prefs.setString(_localeKey, locale.languageCode);
    } else {
      await prefs.remove(_localeKey);
    }
  }

  /// Get the current language display name
  String getLanguageName(Locale? deviceLocale) {
    if (state == null) {
      return 'System Default';
    }
    final language = SupportedLanguages.getByCode(state!.languageCode);
    return language?.name ?? state!.languageCode;
  }
}

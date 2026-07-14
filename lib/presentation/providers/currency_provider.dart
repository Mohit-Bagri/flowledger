import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/currency.dart';
import '../../core/utils/currency_formatter.dart';

/// Currency Provider
/// Manages the selected display currency with persistence
/// Default is determined by device locale, not network/VPN
final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<Currency> {
  static const String _currencyKey = 'selected_currency';
  static const String _hasSetInitialCurrencyKey = 'has_set_initial_currency';

  CurrencyNotifier() : super(Currencies.inr) {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_currencyKey);

    if (code != null) {
      // User has previously set a currency, use that
      final currency = Currencies.getByCode(code);
      state = currency;
      CurrencyFormatter.setSelectedCurrency(currency);
    } else {
      // First time - detect from device locale
      final hasSetInitial = prefs.getBool(_hasSetInitialCurrencyKey) ?? false;
      if (!hasSetInitial) {
        final detectedCurrency = _detectCurrencyFromLocale();
        state = detectedCurrency;
        CurrencyFormatter.setSelectedCurrency(detectedCurrency);
        // Save the detected currency as default
        await prefs.setString(_currencyKey, detectedCurrency.code);
        await prefs.setBool(_hasSetInitialCurrencyKey, true);
        debugPrint('Currency: Auto-detected ${detectedCurrency.code} from device locale');
      }
    }
  }

  /// Detect currency based on device locale
  /// This uses the device's system locale, NOT network-based location
  /// So VPN won't affect this - it's based on the phone's language/region setting
  Currency _detectCurrencyFromLocale() {
    // Get the device's primary locale
    final locale = ui.PlatformDispatcher.instance.locale;
    final countryCode = locale.countryCode?.toUpperCase();
    final languageCode = locale.languageCode.toLowerCase();

    debugPrint('Currency: Detecting from locale - country: $countryCode, language: $languageCode');

    // Map country codes to currencies
    final currencyFromCountry = _countryCurrencyMap[countryCode];
    if (currencyFromCountry != null) {
      final currency = Currencies.getByCodeSafe(currencyFromCountry);
      if (currency != null) return currency;
    }

    // Fallback: Try to detect from language code
    final currencyFromLanguage = _languageCurrencyMap[languageCode];
    if (currencyFromLanguage != null) {
      final currency = Currencies.getByCodeSafe(currencyFromLanguage);
      if (currency != null) return currency;
    }

    // Default to INR (Indian Rupee) as the app is primarily for Indian market
    return Currencies.inr;
  }

  /// Map of country codes to currency codes
  static const Map<String, String> _countryCurrencyMap = {
    // South Asia
    'IN': 'INR', // India
    'PK': 'PKR', // Pakistan
    'BD': 'BDT', // Bangladesh
    'LK': 'LKR', // Sri Lanka
    'NP': 'NPR', // Nepal
    // Americas
    'US': 'USD', // USA
    'CA': 'CAD', // Canada
    'MX': 'MXN', // Mexico
    'BR': 'BRL', // Brazil
    // Europe
    'GB': 'GBP', // UK
    'DE': 'EUR', // Germany
    'FR': 'EUR', // France
    'IT': 'EUR', // Italy
    'ES': 'EUR', // Spain
    'NL': 'EUR', // Netherlands
    'BE': 'EUR', // Belgium
    'AT': 'EUR', // Austria
    'IE': 'EUR', // Ireland
    'PT': 'EUR', // Portugal
    'CH': 'CHF', // Switzerland
    'SE': 'SEK', // Sweden
    'NO': 'NOK', // Norway
    'DK': 'DKK', // Denmark
    'PL': 'PLN', // Poland
    'RU': 'RUB', // Russia
    // Asia Pacific
    'JP': 'JPY', // Japan
    'CN': 'CNY', // China
    'KR': 'KRW', // South Korea
    'SG': 'SGD', // Singapore
    'MY': 'MYR', // Malaysia
    'TH': 'THB', // Thailand
    'ID': 'IDR', // Indonesia
    'PH': 'PHP', // Philippines
    'VN': 'VND', // Vietnam
    'HK': 'HKD', // Hong Kong
    'TW': 'TWD', // Taiwan
    // Middle East
    'AE': 'AED', // UAE
    'SA': 'SAR', // Saudi Arabia
    'QA': 'QAR', // Qatar
    'KW': 'KWD', // Kuwait
    'IL': 'ILS', // Israel
    'TR': 'TRY', // Turkey
    // Oceania
    'AU': 'AUD', // Australia
    'NZ': 'NZD', // New Zealand
    // Africa
    'ZA': 'ZAR', // South Africa
    'NG': 'NGN', // Nigeria
    'EG': 'EGP', // Egypt
    'KE': 'KES', // Kenya
  };

  /// Fallback map for language codes (when country not available)
  static const Map<String, String> _languageCurrencyMap = {
    'hi': 'INR', // Hindi -> India
    'en': 'USD', // English -> USD (default)
    'ja': 'JPY', // Japanese
    'zh': 'CNY', // Chinese
    'ko': 'KRW', // Korean
    'de': 'EUR', // German
    'fr': 'EUR', // French
    'es': 'EUR', // Spanish (default to EUR, could be MXN)
    'pt': 'BRL', // Portuguese (likely Brazil)
    'ru': 'RUB', // Russian
    'ar': 'SAR', // Arabic (default to Saudi)
    'th': 'THB', // Thai
    'vi': 'VND', // Vietnamese
    'id': 'IDR', // Indonesian
    'ms': 'MYR', // Malay
    'ta': 'INR', // Tamil -> India
    'te': 'INR', // Telugu -> India
    'mr': 'INR', // Marathi -> India
    'bn': 'INR', // Bengali -> India (could be BDT)
    'gu': 'INR', // Gujarati -> India
    'kn': 'INR', // Kannada -> India
    'ml': 'INR', // Malayalam -> India
    'pa': 'INR', // Punjabi -> India
  };

  Future<void> setCurrency(Currency currency) async {
    state = currency;
    CurrencyFormatter.setSelectedCurrency(currency);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency.code);
  }

  /// Get the detected locale-based currency (for display purposes)
  Currency getLocaleBasedCurrency() {
    return _detectCurrencyFromLocale();
  }
}

/// Helper extension for formatting amounts with the selected currency
extension CurrencyFormat on double {
  String formatWithCurrency(Currency currency) {
    return currency.format(this);
  }
}

/// Provider for the default currency based on transaction
/// This allows each transaction to have its own currency
final defaultTransactionCurrencyProvider = Provider<Currency>((ref) {
  return ref.watch(currencyProvider);
});

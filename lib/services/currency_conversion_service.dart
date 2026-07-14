import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Currency conversion service using free ExchangeRate-API
/// Rates are cached for 24 hours to minimize API calls
class CurrencyConversionService {
  static final CurrencyConversionService _instance = CurrencyConversionService._internal();
  factory CurrencyConversionService() => _instance;
  CurrencyConversionService._internal();

  static CurrencyConversionService get instance => _instance;

  // Free API endpoint (no API key required for basic usage)
  // Using exchangerate.host which is free and doesn't require registration
  static const String _baseUrl = 'https://api.exchangerate.host';

  // Alternative free APIs if needed:
  // - https://open.er-api.com/v6/latest/{base}
  // - https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/{base}.json

  // Cache keys
  static const String _ratesCacheKey = 'currency_rates_cache';
  static const String _ratesCacheTimeKey = 'currency_rates_cache_time';
  static const String _baseCurrencyKey = 'currency_rates_base';

  // Cache duration: 24 hours
  static const Duration _cacheDuration = Duration(hours: 24);

  // In-memory cache
  Map<String, double>? _cachedRates;
  String? _cachedBaseCurrency;
  DateTime? _cacheTime;

  /// Convert amount from one currency to another
  /// Returns null if conversion fails
  Future<double?> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return amount;

    try {
      final rates = await getExchangeRates(fromCurrency);
      if (rates == null) return null;

      final rate = rates[toCurrency];
      if (rate == null) return null;

      return amount * rate;
    } catch (e) {
      debugPrint('Currency conversion error: $e');
      return null;
    }
  }

  /// Get exchange rates for a base currency
  /// Returns a map of currency code -> rate
  Future<Map<String, double>?> getExchangeRates(String baseCurrency) async {
    // Check in-memory cache first
    if (_cachedRates != null &&
        _cachedBaseCurrency == baseCurrency &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedRates;
    }

    // Check persistent cache
    final cachedData = await _loadFromCache(baseCurrency);
    if (cachedData != null) {
      _cachedRates = cachedData;
      _cachedBaseCurrency = baseCurrency;
      return cachedData;
    }

    // Fetch from API
    return await _fetchRatesFromApi(baseCurrency);
  }

  /// Fetch rates from API
  Future<Map<String, double>?> _fetchRatesFromApi(String baseCurrency) async {
    try {
      // Try primary API (exchangerate.host)
      var rates = await _tryExchangeRateHost(baseCurrency);

      // Fallback to alternative API if primary fails
      if (rates == null) {
        rates = await _tryOpenExchangeRateApi(baseCurrency);
      }

      // Another fallback
      if (rates == null) {
        rates = await _tryFawazAhmedApi(baseCurrency);
      }

      if (rates != null) {
        await _saveToCache(baseCurrency, rates);
        _cachedRates = rates;
        _cachedBaseCurrency = baseCurrency;
        _cacheTime = DateTime.now();
      }

      return rates;
    } catch (e) {
      debugPrint('Error fetching exchange rates: $e');
      return null;
    }
  }

  /// Try exchangerate.host API
  Future<Map<String, double>?> _tryExchangeRateHost(String baseCurrency) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/latest?base=$baseCurrency'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['rates'] != null) {
          final rates = <String, double>{};
          (data['rates'] as Map<String, dynamic>).forEach((key, value) {
            rates[key] = (value as num).toDouble();
          });
          return rates;
        }
      }
    } catch (e) {
      debugPrint('exchangerate.host API error: $e');
    }
    return null;
  }

  /// Try open.er-api.com (free, no key required)
  Future<Map<String, double>?> _tryOpenExchangeRateApi(String baseCurrency) async {
    try {
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/$baseCurrency'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success' && data['rates'] != null) {
          final rates = <String, double>{};
          (data['rates'] as Map<String, dynamic>).forEach((key, value) {
            rates[key] = (value as num).toDouble();
          });
          return rates;
        }
      }
    } catch (e) {
      debugPrint('open.er-api.com API error: $e');
    }
    return null;
  }

  /// Try fawazahmed0 currency API (GitHub-hosted, very reliable)
  Future<Map<String, double>?> _tryFawazAhmedApi(String baseCurrency) async {
    try {
      final base = baseCurrency.toLowerCase();
      final response = await http.get(
        Uri.parse('https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/$base.json'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[base] != null) {
          final rates = <String, double>{};
          (data[base] as Map<String, dynamic>).forEach((key, value) {
            rates[key.toUpperCase()] = (value as num).toDouble();
          });
          return rates;
        }
      }
    } catch (e) {
      debugPrint('fawazahmed0 API error: $e');
    }
    return null;
  }

  /// Load rates from persistent cache
  Future<Map<String, double>?> _loadFromCache(String baseCurrency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedBase = prefs.getString(_baseCurrencyKey);

      if (cachedBase != baseCurrency) return null;

      final cacheTimeMs = prefs.getInt(_ratesCacheTimeKey);
      if (cacheTimeMs == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimeMs);
      if (DateTime.now().difference(cacheTime) > _cacheDuration) return null;

      final cachedJson = prefs.getString(_ratesCacheKey);
      if (cachedJson == null) return null;

      final data = json.decode(cachedJson) as Map<String, dynamic>;
      final rates = <String, double>{};
      data.forEach((key, value) {
        rates[key] = (value as num).toDouble();
      });

      _cacheTime = cacheTime;
      return rates;
    } catch (e) {
      debugPrint('Error loading rates from cache: $e');
      return null;
    }
  }

  /// Save rates to persistent cache
  Future<void> _saveToCache(String baseCurrency, Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_baseCurrencyKey, baseCurrency);
      await prefs.setString(_ratesCacheKey, json.encode(rates));
      await prefs.setInt(_ratesCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving rates to cache: $e');
    }
  }

  /// Clear the cache (useful for forcing a refresh)
  Future<void> clearCache() async {
    _cachedRates = null;
    _cachedBaseCurrency = null;
    _cacheTime = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ratesCacheKey);
      await prefs.remove(_ratesCacheTimeKey);
      await prefs.remove(_baseCurrencyKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get the last update time of cached rates
  DateTime? get lastUpdateTime => _cacheTime;

  /// Check if rates are cached and valid
  bool get hasValidCache {
    return _cachedRates != null &&
           _cacheTime != null &&
           DateTime.now().difference(_cacheTime!) < _cacheDuration;
  }
}

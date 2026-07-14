import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/currency_conversion_service.dart';
import 'currency_provider.dart';

/// Key for storing conversion enabled preference
const String _conversionEnabledKey = 'currency_conversion_enabled';
const String _showOriginalKey = 'currency_show_original';

/// State for currency conversion
class CurrencyConversionState {
  final bool isEnabled;
  final bool showOriginal; // Whether to show original amount in brackets when converting
  final bool isLoading;
  final Map<String, double>? rates;
  final DateTime? lastUpdated;
  final String? error;

  const CurrencyConversionState({
    this.isEnabled = false,
    this.showOriginal = true, // Default to showing original
    this.isLoading = false,
    this.rates,
    this.lastUpdated,
    this.error,
  });

  CurrencyConversionState copyWith({
    bool? isEnabled,
    bool? showOriginal,
    bool? isLoading,
    Map<String, double>? rates,
    DateTime? lastUpdated,
    String? error,
  }) {
    return CurrencyConversionState(
      isEnabled: isEnabled ?? this.isEnabled,
      showOriginal: showOriginal ?? this.showOriginal,
      isLoading: isLoading ?? this.isLoading,
      rates: rates ?? this.rates,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error,
    );
  }

  /// Check if rates are available and valid
  bool get hasValidRates => rates != null && rates!.isNotEmpty;
}

/// Notifier for managing currency conversion state
class CurrencyConversionNotifier extends StateNotifier<CurrencyConversionState> {
  final Ref _ref;
  final CurrencyConversionService _service = CurrencyConversionService.instance;

  CurrencyConversionNotifier(this._ref) : super(const CurrencyConversionState()) {
    _loadPreferences();
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_conversionEnabledKey) ?? false;
      final showOriginal = prefs.getBool(_showOriginalKey) ?? true;
      state = state.copyWith(isEnabled: isEnabled, showOriginal: showOriginal);

      if (isEnabled) {
        await refreshRates();
      }
    } catch (e) {
      // Ignore errors loading preferences
    }
  }

  /// Toggle currency conversion on/off
  Future<void> toggleConversion(bool enabled) async {
    state = state.copyWith(isEnabled: enabled, error: null);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_conversionEnabledKey, enabled);

      if (enabled) {
        await refreshRates();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to save preference');
    }
  }

  /// Toggle showing original amount in brackets
  Future<void> toggleShowOriginal(bool showOriginal) async {
    state = state.copyWith(showOriginal: showOriginal);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showOriginalKey, showOriginal);
    } catch (e) {
      // Ignore errors saving preference
    }
  }

  /// Refresh exchange rates from API
  Future<void> refreshRates() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final targetCurrency = _ref.read(currencyProvider).code;
      final rates = await _service.getExchangeRates(targetCurrency);

      if (rates != null) {
        state = state.copyWith(
          isLoading: false,
          rates: rates,
          lastUpdated: DateTime.now(),
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch exchange rates. Using cached rates if available.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error: $e',
      );
    }
  }

  /// Convert an amount from one currency to the target currency
  /// Returns the original amount if conversion is disabled or fails
  double convertAmount(double amount, String fromCurrency) {
    if (!state.isEnabled || !state.hasValidRates) {
      return amount;
    }

    final targetCurrency = _ref.read(currencyProvider).code;
    if (fromCurrency == targetCurrency) {
      return amount;
    }

    // If we have rates with target as base, we need the inverse rate
    // Since we fetched rates with target as base, the rate for fromCurrency
    // tells us how many units of fromCurrency = 1 unit of target
    // So to convert fromCurrency to target: amount / rate
    final rate = state.rates?[fromCurrency];
    if (rate == null || rate == 0) {
      return amount;
    }

    // amount in fromCurrency / rate = amount in targetCurrency
    return amount / rate;
  }

  /// Convert multiple amounts and sum them
  double convertAndSum(List<({double amount, String currencyCode})> items) {
    if (!state.isEnabled) {
      // If conversion is off, just sum all (will mix currencies - not recommended)
      return items.fold(0.0, (sum, item) => sum + item.amount);
    }

    double total = 0.0;
    for (final item in items) {
      total += convertAmount(item.amount, item.currencyCode);
    }
    return total;
  }

  /// Clear cached rates
  Future<void> clearCache() async {
    await _service.clearCache();
    state = state.copyWith(rates: null, lastUpdated: null);
    if (state.isEnabled) {
      await refreshRates();
    }
  }
}

/// Provider for currency conversion state
final currencyConversionProvider =
    StateNotifierProvider<CurrencyConversionNotifier, CurrencyConversionState>(
  (ref) => CurrencyConversionNotifier(ref),
);

/// Helper provider to check if conversion is enabled
final isConversionEnabledProvider = Provider<bool>((ref) {
  return ref.watch(currencyConversionProvider).isEnabled;
});

/// Helper provider to get the convert function
final convertAmountProvider = Provider<double Function(double, String)>((ref) {
  final notifier = ref.watch(currencyConversionProvider.notifier);
  return notifier.convertAmount;
});

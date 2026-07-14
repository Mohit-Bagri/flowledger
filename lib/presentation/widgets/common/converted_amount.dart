import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/currency.dart';
import '../../providers/currency_provider.dart';
import '../../providers/currency_conversion_provider.dart';

/// A widget that displays an amount with automatic currency conversion
/// when the conversion toggle is enabled.
///
/// If conversion is enabled:
/// - Shows the converted amount in the target currency
/// - Optionally shows the original amount in a smaller subtitle
///
/// If conversion is disabled:
/// - Shows the original amount with its currency symbol
class ConvertedAmount extends ConsumerWidget {
  /// The original amount to display
  final double amount;

  /// The currency code of the original amount (e.g., 'USD', 'INR')
  final String currencyCode;

  /// Text style for the main amount
  final TextStyle? style;

  /// Whether to show the original amount as a subtitle when converted
  final bool showOriginal;

  /// Text style for the original amount subtitle
  final TextStyle? originalStyle;

  /// Custom formatter for the amount (defaults to 2 decimal places)
  final String Function(double)? formatter;

  /// Whether to always show the currency symbol/code
  final bool showCurrency;

  /// Use compact format for large numbers (e.g., 1.2K, 1.5L)
  final bool compact;

  const ConvertedAmount({
    super.key,
    required this.amount,
    required this.currencyCode,
    this.style,
    this.showOriginal = false,
    this.originalStyle,
    this.formatter,
    this.showCurrency = true,
    this.compact = false,
  });

  String _formatAmount(double value, String symbol) {
    if (formatter != null) {
      return formatter!(value);
    }

    String formatted;
    if (compact) {
      if (value.abs() >= 10000000) {
        // Crore (Indian system)
        formatted = '${(value / 10000000).toStringAsFixed(1)}Cr';
      } else if (value.abs() >= 100000) {
        // Lakh (Indian system)
        formatted = '${(value / 100000).toStringAsFixed(1)}L';
      } else if (value.abs() >= 1000) {
        formatted = '${(value / 1000).toStringAsFixed(1)}K';
      } else {
        formatted = value.toStringAsFixed(0);
      }
    } else {
      // Regular formatting
      if (value == value.roundToDouble()) {
        formatted = value.toStringAsFixed(0);
      } else {
        formatted = value.toStringAsFixed(2);
      }
    }

    return showCurrency ? '$symbol$formatted' : formatted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversionState = ref.watch(currencyConversionProvider);
    final targetCurrency = ref.watch(currencyProvider);
    final isConversionEnabled = conversionState.isEnabled && conversionState.hasValidRates;

    // Get original currency info
    final originalCurrency = Currencies.getByCodeSafe(currencyCode) ?? targetCurrency;

    // If conversion is enabled and currencies differ, convert
    if (isConversionEnabled && currencyCode != targetCurrency.code) {
      final convertedAmount = ref
          .read(currencyConversionProvider.notifier)
          .convertAmount(amount, currencyCode);

      // Build converted display
      final mainText = _formatAmount(convertedAmount, targetCurrency.symbol);
      final originalText = _formatAmount(amount, originalCurrency.symbol);

      // Use user's preference for showing original, or the widget's showOriginal parameter
      final shouldShowOriginal = showOriginal || conversionState.showOriginal;

      if (shouldShowOriginal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mainText, style: style),
            Text(
              '($originalText)',
              style: originalStyle ??
                  (style?.copyWith(
                    fontSize: (style?.fontSize ?? 14) * 0.75,
                    color: (style?.color ?? Colors.grey).withValues(alpha: 0.7),
                  )),
            ),
          ],
        );
      }

      return Text(mainText, style: style);
    }

    // No conversion - show original currency symbol
    return Text(
      _formatAmount(amount, originalCurrency.symbol),
      style: style,
    );
  }
}

/// Extension to easily get converted amounts in code
extension CurrencyConversionExtension on WidgetRef {
  /// Convert an amount to the target currency if conversion is enabled
  double convertIfEnabled(double amount, String fromCurrency) {
    final conversionState = watch(currencyConversionProvider);
    if (!conversionState.isEnabled || !conversionState.hasValidRates) {
      return amount;
    }
    return read(currencyConversionProvider.notifier).convertAmount(amount, fromCurrency);
  }

  /// Get the display currency symbol (target if converting, original otherwise)
  String getDisplaySymbol(String originalCurrencyCode) {
    final conversionState = watch(currencyConversionProvider);
    if (conversionState.isEnabled && conversionState.hasValidRates) {
      return watch(currencyProvider).symbol;
    }
    return Currencies.getByCodeSafe(originalCurrencyCode)?.symbol ?? '₹';
  }
}

/// A function to sum amounts from different currencies with conversion
/// Use this in providers/notifiers where you need to calculate totals
double sumWithConversion({
  required List<({double amount, String currencyCode})> items,
  required bool conversionEnabled,
  required Map<String, double>? rates,
  required String targetCurrencyCode,
}) {
  if (!conversionEnabled || rates == null || rates.isEmpty) {
    // No conversion - just sum (will mix currencies)
    return items.fold(0.0, (sum, item) => sum + item.amount);
  }

  double total = 0.0;
  for (final item in items) {
    if (item.currencyCode == targetCurrencyCode) {
      total += item.amount;
    } else {
      final rate = rates[item.currencyCode];
      if (rate != null && rate != 0) {
        total += item.amount / rate;
      } else {
        // Can't convert, add as-is
        total += item.amount;
      }
    }
  }
  return total;
}

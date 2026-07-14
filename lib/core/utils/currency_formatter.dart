import '../../data/models/currency.dart';

/// Currency Formatter
/// Formats numbers with the selected currency or uses Indian numbering system for INR
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Currently selected currency - should be set from the provider
  static Currency _selectedCurrency = Currencies.inr;

  /// Set the selected currency
  static void setSelectedCurrency(Currency currency) {
    _selectedCurrency = currency;
  }

  /// Get the currently selected currency
  static Currency get selectedCurrency => _selectedCurrency;

  /// Get the current currency code (convenience getter)
  static String get currentCurrencyCode => _selectedCurrency.code;

  /// Get the current currency symbol (convenience getter)
  static String get currentSymbol => _selectedCurrency.symbol;

  /// Format amount with the selected currency
  static String format(double amount) {
    // Use Indian format for INR, standard format for others
    if (_selectedCurrency.code == 'INR') {
      return formatINR(amount);
    }
    return _selectedCurrency.format(amount);
  }

  /// Format amount with Indian number system and rupee symbol
  /// Example: ₹1,23,456
  static String formatINR(double amount, {bool showSymbol = true}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formatted = _formatIndianNumber(absAmount.round());

    if (showSymbol) {
      return isNegative ? '-₹$formatted' : '₹$formatted';
    }
    return isNegative ? '-$formatted' : formatted;
  }

  /// Format amount for PDF (uses Rs. instead of ₹ symbol for INR)
  /// Example: Rs. 1,23,456
  static String formatINRForPdf(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formatted = _formatIndianNumber(absAmount.round());
    return isNegative ? '-Rs. $formatted' : 'Rs. $formatted';
  }

  /// Format amount for PDF using selected currency
  /// Uses text-friendly symbols (Rs. instead of ₹, USD instead of $ for clarity)
  static String formatForPdf(double amount) {
    return formatForPdfWithCurrency(amount, _selectedCurrency.code);
  }

  /// Format amount for PDF using a specific currency code
  /// Used for transaction-level currency formatting
  static String formatForPdfWithCurrency(double amount, String currencyCode) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final currency = Currencies.getByCode(currencyCode);

    // Use Indian numbering for INR, standard for others
    if (currencyCode == 'INR') {
      final formatted = _formatIndianNumber(absAmount.round());
      return isNegative ? '-Rs. $formatted' : 'Rs. $formatted';
    }

    // For other currencies, use standard formatting with symbol
    final formatted = _formatStandardNumber(absAmount.round());
    final symbol = currency.symbol;
    return isNegative ? '-$symbol$formatted' : '$symbol$formatted';
  }

  /// Format number with standard comma placement (every 3 digits)
  /// Example: 1,234,567
  static String _formatStandardNumber(int number) {
    if (number < 1000) {
      return number.toString();
    }

    final str = number.toString();
    final buffer = StringBuffer();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      buffer.write(str[i]);
      final posFromEnd = length - i - 1;
      if (posFromEnd > 0 && posFromEnd % 3 == 0) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }

  /// Format number with Indian comma system (no currency symbol)
  /// Example: 1,23,456
  static String formatNumber(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formatted = _formatIndianNumber(absAmount.round());
    return isNegative ? '-$formatted' : formatted;
  }

  /// Format with decimal places
  /// Example: ₹1,23,456.78
  static String formatINRWithDecimals(double amount, {int decimals = 2, bool showSymbol = true}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final wholePart = absAmount.truncate();
    final decimalPart = ((absAmount - wholePart) * (decimals == 2 ? 100 : 10)).round();

    final formatted = _formatIndianNumber(wholePart);
    final decimalStr = decimalPart.toString().padLeft(decimals, '0');

    if (showSymbol) {
      return isNegative ? '-₹$formatted.$decimalStr' : '₹$formatted.$decimalStr';
    }
    return isNegative ? '-$formatted.$decimalStr' : '$formatted.$decimalStr';
  }

  /// Core function to format number with Indian comma placement
  /// Indian system: XX,XX,XX,XXX (after first 3 digits, commas every 2 digits)
  static String _formatIndianNumber(int number) {
    if (number < 1000) {
      return number.toString();
    }

    final str = number.toString();
    final length = str.length;

    // Last 3 digits
    final lastThree = str.substring(length - 3);

    // Remaining digits (to be grouped by 2)
    final remaining = str.substring(0, length - 3);

    if (remaining.isEmpty) {
      return lastThree;
    }

    // Add commas every 2 digits from right in the remaining part
    final buffer = StringBuffer();
    final remainingLength = remaining.length;

    for (int i = 0; i < remainingLength; i++) {
      buffer.write(remaining[i]);
      final posFromEnd = remainingLength - i - 1;
      if (posFromEnd > 0 && posFromEnd % 2 == 0) {
        buffer.write(',');
      }
    }

    return '$buffer,$lastThree';
  }

  /// Parse Indian formatted string back to double
  /// Example: "1,23,456" -> 123456.0
  static double parseINR(String formatted) {
    // Remove currency symbols and commas
    final cleaned = formatted
        .replaceAll('₹', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .replaceAll('INR', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Format for compact display (K, L, Cr) with dynamic currency symbol
  /// Example: $1.5K, ₹2.3L
  static String formatCompact(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    String result;
    final symbol = _selectedCurrency.symbol;

    if (_selectedCurrency.code == 'INR') {
      // Use Indian numbering system (L, Cr) for INR
      if (absAmount >= 10000000) {
        result = '${(absAmount / 10000000).toStringAsFixed(1)}Cr';
      } else if (absAmount >= 100000) {
        result = '${(absAmount / 100000).toStringAsFixed(1)}L';
      } else if (absAmount >= 1000) {
        result = '${(absAmount / 1000).toStringAsFixed(1)}K';
      } else {
        result = absAmount.toStringAsFixed(0);
      }
    } else {
      // Use international numbering system (K, M, B) for other currencies
      if (absAmount >= 1000000000) {
        result = '${(absAmount / 1000000000).toStringAsFixed(1)}B';
      } else if (absAmount >= 1000000) {
        result = '${(absAmount / 1000000).toStringAsFixed(1)}M';
      } else if (absAmount >= 1000) {
        result = '${(absAmount / 1000).toStringAsFixed(1)}K';
      } else {
        result = absAmount.toStringAsFixed(0);
      }
    }

    // Remove .0 if present
    result = result.replaceAll('.0', '');

    return isNegative ? '-$symbol$result' : '$symbol$result';
  }
}

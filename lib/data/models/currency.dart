/// Currency Model
/// Display-only currency (no conversion)
class Currency {
  final String code;
  final String symbol;
  final String name;
  final int decimalPlaces;
  final bool symbolBefore;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    this.decimalPlaces = 2,
    this.symbolBefore = true,
  });

  String format(double amount) {
    final formatted = amount.toStringAsFixed(decimalPlaces);
    final parts = formatted.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    final result = decimalPlaces > 0 ? '$intPart.${parts[1]}' : intPart;
    return symbolBefore ? '$symbol$result' : '$result$symbol';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// Pre-defined currencies
class Currencies {
  Currencies._();

  static const Currency inr = Currency(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    decimalPlaces: 0,
    symbolBefore: true,
  );

  static const Currency usd = Currency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
    decimalPlaces: 2,
    symbolBefore: true,
  );

  static const Currency eur = Currency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    decimalPlaces: 2,
    symbolBefore: true,
  );

  static const Currency gbp = Currency(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    decimalPlaces: 2,
    symbolBefore: true,
  );

  static const Currency jpy = Currency(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    decimalPlaces: 0,
    symbolBefore: true,
  );

  static const Currency cad = Currency(
    code: 'CAD',
    symbol: 'C\$',
    name: 'Canadian Dollar',
    decimalPlaces: 2,
    symbolBefore: true,
  );

  static const Currency aud = Currency(
    code: 'AUD',
    symbol: 'A\$',
    name: 'Australian Dollar',
    decimalPlaces: 2,
    symbolBefore: true,
  );

  static const Currency aed = Currency(
    code: 'AED',
    symbol: 'د.إ',
    name: 'UAE Dirham',
    decimalPlaces: 2,
    symbolBefore: true,
  );

  static const Currency sgd = Currency(
    code: 'SGD',
    symbol: 'S\$',
    name: 'Singapore Dollar',
    decimalPlaces: 2,
    symbolBefore: true,
  );

  static const List<Currency> all = [
    inr,
    usd,
    eur,
    gbp,
    jpy,
    cad,
    aud,
    aed,
    sgd,
  ];

  static Currency getByCode(String code) {
    return all.firstWhere(
      (c) => c.code == code,
      orElse: () => inr,
    );
  }

  /// Get currency by code, returns null if not found
  static Currency? getByCodeSafe(String code) {
    try {
      return all.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking usage metrics (receipt scans, etc.) for free tier limits
class UsageTrackingService {
  UsageTrackingService._();
  static final UsageTrackingService instance = UsageTrackingService._();

  static const String _prefReceiptScanCount = 'receipt_scan_count';
  static const String _prefReceiptScanMonth = 'receipt_scan_month';

  SharedPreferences? _prefs;

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get the current month key (YYYY-MM format)
  String _getCurrentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Get the current receipt scan count for this month
  Future<int> getReceiptScanCount() async {
    await _ensureInitialized();

    final storedMonth = _prefs!.getString(_prefReceiptScanMonth);
    final currentMonth = _getCurrentMonthKey();

    // Reset count if it's a new month
    if (storedMonth != currentMonth) {
      await _prefs!.setString(_prefReceiptScanMonth, currentMonth);
      await _prefs!.setInt(_prefReceiptScanCount, 0);
      return 0;
    }

    return _prefs!.getInt(_prefReceiptScanCount) ?? 0;
  }

  /// Increment the receipt scan count
  Future<int> incrementReceiptScanCount() async {
    await _ensureInitialized();

    final storedMonth = _prefs!.getString(_prefReceiptScanMonth);
    final currentMonth = _getCurrentMonthKey();

    int currentCount;

    // Reset count if it's a new month
    if (storedMonth != currentMonth) {
      await _prefs!.setString(_prefReceiptScanMonth, currentMonth);
      currentCount = 0;
    } else {
      currentCount = _prefs!.getInt(_prefReceiptScanCount) ?? 0;
    }

    currentCount++;
    await _prefs!.setInt(_prefReceiptScanCount, currentCount);

    return currentCount;
  }

  /// Check if user can scan (has remaining scans this month)
  Future<bool> canScanReceipt(int limit) async {
    final count = await getReceiptScanCount();
    return count < limit;
  }

  /// Get remaining scans for this month
  Future<int> getRemainingScans(int limit) async {
    final count = await getReceiptScanCount();
    return (limit - count).clamp(0, limit);
  }
}

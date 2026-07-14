import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/premium_features.dart';
import '../../services/revenue_cat_service.dart';

/// Debug mode for testing premium features without real purchases
/// Set this to true during development to unlock all premium features
/// IMPORTANT: Set to false before releasing to production!
class DebugConfig {
  static const String _debugPremiumKey = 'debug_premium_enabled';

  /// Check if debug premium mode is enabled (for development testing)
  static Future<bool> isDebugPremiumEnabled() async {
    // Only allow in debug mode
    if (!kDebugMode) return false;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_debugPremiumKey) ?? false;
  }

  /// Toggle debug premium mode
  static Future<void> setDebugPremium(bool enabled) async {
    if (!kDebugMode) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugPremiumKey, enabled);
  }
}

/// Subscription tier
enum SubscriptionTier { free, premium }

/// Subscription state
class SubscriptionState {
  final SubscriptionTier tier;
  final DateTime? expirationDate;
  final Offerings? offerings;
  final bool isLoading;
  final String? error;
  final bool isDebugPremium; // Debug mode flag

  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.expirationDate,
    this.offerings,
    this.isLoading = false,
    this.error,
    this.isDebugPremium = false,
  });

  /// Returns true if user has premium (either real or debug)
  bool get isPremium => tier == SubscriptionTier.premium || isDebugPremium;

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    DateTime? expirationDate,
    Offerings? offerings,
    bool? isLoading,
    String? error,
    bool? isDebugPremium,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      expirationDate: expirationDate ?? this.expirationDate,
      offerings: offerings ?? this.offerings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isDebugPremium: isDebugPremium ?? this.isDebugPremium,
    );
  }
}

/// Subscription provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

/// Convenience provider for checking premium status
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).isPremium;
});

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState()) {
    _loadSubscriptionStatus();
  }

  final _service = RevenueCatService.instance;

  /// Load current subscription status
  Future<void> _loadSubscriptionStatus() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check for debug premium mode first (only works in debug builds)
      final isDebugPremium = await DebugConfig.isDebugPremiumEnabled();

      // Check premium status from RevenueCat
      final isPremium = await _service.isPremium();

      // Get available offerings
      final offerings = await _service.getOfferings();

      // Get expiration date if premium
      DateTime? expirationDate;
      if (isPremium) {
        final customerInfo = await _service.getCustomerInfo();
        final entitlement = customerInfo?.entitlements.active[RevenueCatConfig.premiumEntitlementId];
        if (entitlement?.expirationDate != null) {
          expirationDate = DateTime.parse(entitlement!.expirationDate!);
        }
      }

      state = SubscriptionState(
        tier: isPremium ? SubscriptionTier.premium : SubscriptionTier.free,
        expirationDate: expirationDate,
        offerings: offerings,
        isLoading: false,
        isDebugPremium: isDebugPremium,
      );

      if (isDebugPremium) {
        debugPrint('⚠️ DEBUG MODE: Premium features unlocked for testing');
      }
    } catch (e) {
      debugPrint('Error loading subscription: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to load subscription status');
    }
  }

  /// Toggle debug premium mode (only works in debug builds)
  Future<void> toggleDebugPremium() async {
    if (!kDebugMode) return;

    final newValue = !state.isDebugPremium;
    await DebugConfig.setDebugPremium(newValue);
    state = state.copyWith(isDebugPremium: newValue);

    debugPrint(newValue
        ? '⚠️ DEBUG MODE: Premium features ENABLED'
        : '⚠️ DEBUG MODE: Premium features DISABLED');
  }

  /// Refresh subscription status
  Future<void> refresh() async {
    await _loadSubscriptionStatus();
  }

  /// Purchase a package
  Future<PurchaseResult> purchasePackage(Package package) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.purchasePackage(package);

    if (result.success) {
      await _loadSubscriptionStatus();
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
    }

    return result;
  }

  /// Restore purchases
  Future<PurchaseResult> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.restorePurchases();

    if (result.success) {
      await _loadSubscriptionStatus();
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
    }

    return result;
  }

  /// Check if user can access a premium feature
  bool canAccessFeature(PremiumFeature feature) {
    return state.isPremium;
  }

  /// Check if user can add more items (for limited features)
  bool canAddMore(PremiumFeature feature, int currentCount) {
    if (state.isPremium) return true;

    switch (feature) {
      case PremiumFeature.unlimitedBankAccounts:
        return currentCount < FreeTierLimits.bankAccounts;
      case PremiumFeature.unlimitedPaymentMethods:
        return currentCount < FreeTierLimits.paymentMethods;
      case PremiumFeature.unlimitedBudgets:
        return currentCount < FreeTierLimits.budgets;
      case PremiumFeature.unlimitedGoals:
        return currentCount < FreeTierLimits.goals;
      case PremiumFeature.unlimitedRecurring:
        return currentCount < FreeTierLimits.recurringTransactions;
      case PremiumFeature.unlimitedCategories:
        return currentCount < FreeTierLimits.customCategories;
      case PremiumFeature.unlimitedReceiptScanning:
        return currentCount < FreeTierLimits.receiptScansPerMonth;
      default:
        return false;
    }
  }

  /// Check if a locked feature is available
  bool hasFeature(PremiumFeature feature) {
    if (state.isPremium) return true;
    // Locked features are not available to free users
    return !isLockedFeature(feature);
  }

  /// Get remaining count for a limited feature
  int getRemaining(PremiumFeature feature, int currentCount) {
    if (state.isPremium) return -1; // Unlimited
    return FreeTierLimits.getRemaining(feature, currentCount);
  }

  /// Get limit for a feature
  int getLimit(PremiumFeature feature) {
    if (state.isPremium) return -1; // Unlimited
    return FreeTierLimits.getLimit(feature);
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat configuration
///
/// To set up RevenueCat:
/// 1. Create an account at https://www.revenuecat.com
/// 2. Create a new project for FlowLedger
/// 3. Add iOS app with your App Store Connect bundle ID
/// 4. Add Android app with your Google Play Console package name
/// 5. Get the API keys from Settings > API Keys
/// 6. Replace the placeholder keys below
/// 7. Create products in App Store Connect / Google Play Console:
///    - Monthly: com.flowledger.premium.monthly (₹99/month)
///    - Annual: com.flowledger.premium.annual (₹799/year)
///    - Lifetime: com.flowledger.premium.lifetime (₹1999 one-time)
/// 8. Create an entitlement called "premium" in RevenueCat
/// 9. Link your products to the premium entitlement
/// 10. Create an offering called "default" with the premium packages
class RevenueCatConfig {
  // ════════════════════════════════════════════════════════════════
  // SETUP: Replace these keys before publishing
  //
  // 1. Create account at https://app.revenuecat.com
  // 2. Add your iOS + Android app in the dashboard
  // 3. Go to Project Settings → API Keys
  // 4. Copy your PUBLIC SDK keys (not secret keys) below
  //
  // NOTE: The app skips RevenueCat initialization if these placeholder
  //       values are detected — safe to run without real keys.
  // ════════════════════════════════════════════════════════════════
  static const String appleApiKey = 'YOUR_APPLE_API_KEY';
  static const String googleApiKey = 'YOUR_GOOGLE_API_KEY';

  // Entitlement ID configured in RevenueCat
  static const String premiumEntitlementId = 'premium';

  // Product IDs (must match store configuration)
  static const String monthlyProductId = 'com.flowledger.premium.monthly';
  static const String annualProductId = 'com.flowledger.premium.annual';
  static const String lifetimeProductId = 'com.flowledger.premium.lifetime';

  // Offering ID
  static const String defaultOfferingId = 'default';
}

/// Service for handling in-app purchases via RevenueCat
class RevenueCatService {
  static RevenueCatService? _instance;
  static RevenueCatService get instance => _instance ??= RevenueCatService._();

  RevenueCatService._();

  bool _isInitialized = false;

  /// Initialize RevenueCat SDK
  static Future<void> initialize() async {
    if (_instance?._isInitialized == true) return;

    try {
      final apiKey = Platform.isIOS
          ? RevenueCatConfig.appleApiKey
          : RevenueCatConfig.googleApiKey;

      // Skip initialization if using placeholder keys
      if (apiKey == 'YOUR_APPLE_API_KEY' || apiKey == 'YOUR_GOOGLE_API_KEY') {
        debugPrint('RevenueCat: Using placeholder API key, skipping initialization');
        return;
      }

      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = null,
      );

      _instance = RevenueCatService._();
      _instance!._isInitialized = true;
      debugPrint('RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('RevenueCat initialization failed: $e');
    }
  }

  /// Check if RevenueCat is initialized
  bool get isInitialized => _isInitialized;

  /// Get current customer info
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_isInitialized) return null;

    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('Error getting customer info: $e');
      return null;
    }
  }

  /// Check if user has premium entitlement
  Future<bool> isPremium() async {
    if (!_isInitialized) return false;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(RevenueCatConfig.premiumEntitlementId);
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      return false;
    }
  }

  /// Get available offerings (products)
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) return null;

    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Error getting offerings: $e');
      return null;
    }
  }

  /// Purchase a package
  Future<PurchaseResult> purchasePackage(Package package) async {
    if (!_isInitialized) {
      return PurchaseResult.failure('Coming soon — Premium subscriptions will be available when the app launches');
    }

    try {
      final customerInfo = await Purchases.purchasePackage(package);
      final isPremium = customerInfo.entitlements.active.containsKey(RevenueCatConfig.premiumEntitlementId);

      if (isPremium) {
        return PurchaseResult.success('Welcome to Premium!');
      } else {
        return PurchaseResult.failure('Purchase completed but premium not activated');
      }
    } on PurchasesErrorCode catch (e) {
      return PurchaseResult.failure(_parsePurchaseError(e));
    } catch (e) {
      debugPrint('Purchase error: $e');
      return PurchaseResult.failure('Purchase failed. Please try again.');
    }
  }

  /// Restore purchases
  Future<PurchaseResult> restorePurchases() async {
    if (!_isInitialized) {
      return PurchaseResult.failure('Coming soon — Premium subscriptions will be available when the app launches');
    }

    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPremium = customerInfo.entitlements.active.containsKey(RevenueCatConfig.premiumEntitlementId);

      if (isPremium) {
        return PurchaseResult.success('Premium restored successfully!');
      } else {
        return PurchaseResult.failure('No previous purchases found');
      }
    } catch (e) {
      debugPrint('Restore error: $e');
      return PurchaseResult.failure('Could not restore purchases');
    }
  }

  /// Login user (for syncing purchases across devices)
  Future<void> login(String userId) async {
    if (!_isInitialized) return;

    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('RevenueCat login error: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    if (!_isInitialized) return;

    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('RevenueCat logout error: $e');
    }
  }

  /// Parse purchase error codes
  String _parsePurchaseError(PurchasesErrorCode errorCode) {
    switch (errorCode) {
      case PurchasesErrorCode.purchaseCancelledError:
        return 'Purchase cancelled';
      case PurchasesErrorCode.storeProblemError:
        return 'There was a problem with the app store. Please try again.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are not allowed on this device';
      case PurchasesErrorCode.purchaseInvalidError:
        return 'Invalid purchase. Please try again.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'This product is not available';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'You already own this product';
      case PurchasesErrorCode.networkError:
        return 'Network error. Please check your connection.';
      default:
        return 'Purchase failed. Please try again.';
    }
  }
}

/// Result class for purchase operations
class PurchaseResult {
  final bool success;
  final String message;

  PurchaseResult._({required this.success, required this.message});

  factory PurchaseResult.success(String message) {
    return PurchaseResult._(success: true, message: message);
  }

  factory PurchaseResult.failure(String message) {
    return PurchaseResult._(success: false, message: message);
  }
}

/// Premium feature definitions and limits for FlowLedger
///
/// Free Tier: Limited features to try the app
/// Pro Tier: Unlimited access to all features

enum PremiumFeature {
  // Count-based features (free users have limits)
  unlimitedBankAccounts,
  unlimitedPaymentMethods,
  unlimitedCategories,
  unlimitedRecurring,
  unlimitedBudgets,
  unlimitedGoals,
  unlimitedReceiptScanning,

  // Locked features (not available to free users)
  cloudSync,
  cloudBackup,
  pdfExport,
  fullExport, // Full date range for CSV
  advancedInsights, // Line charts, bar charts, AI insights
  adFree,

  // Future features
  familySharing,
  csvImport,
  homeWidgets,
  billReminders,
  autoTransactions,
}

/// Free tier limits
class FreeTierLimits {
  // Organization limits
  static const int bankAccounts = 2;
  static const int paymentMethods = 3;
  static const int customCategories = 3;
  static const int recurringTransactions = 3;
  static const int budgets = 3;
  static const int goals = 1;

  // Receipt scanning
  static const int receiptScansPerMonth = 5;

  // Export limits
  static const int csvExportDays = 30; // Last 30 days only for free

  // Helper to check if at limit
  static bool isAtLimit(PremiumFeature feature, int currentCount) {
    final limit = getLimit(feature);
    if (limit == -1) return false; // No limit
    return currentCount >= limit;
  }

  // Get limit for a feature
  static int getLimit(PremiumFeature feature) {
    return switch (feature) {
      PremiumFeature.unlimitedBankAccounts => bankAccounts,
      PremiumFeature.unlimitedPaymentMethods => paymentMethods,
      PremiumFeature.unlimitedCategories => customCategories,
      PremiumFeature.unlimitedRecurring => recurringTransactions,
      PremiumFeature.unlimitedBudgets => budgets,
      PremiumFeature.unlimitedGoals => goals,
      PremiumFeature.unlimitedReceiptScanning => receiptScansPerMonth,
      _ => -1, // No limit or locked feature
    };
  }

  // Get remaining slots
  static int getRemaining(PremiumFeature feature, int currentCount) {
    final limit = getLimit(feature);
    if (limit == -1) return -1; // Unlimited
    return (limit - currentCount).clamp(0, limit);
  }
}

/// Check if a feature is completely locked (not count-based)
bool isLockedFeature(PremiumFeature feature) {
  return switch (feature) {
    PremiumFeature.cloudSync => true,
    PremiumFeature.cloudBackup => true,
    PremiumFeature.pdfExport => true,
    PremiumFeature.fullExport => true,
    PremiumFeature.advancedInsights => true,
    PremiumFeature.adFree => true,
    PremiumFeature.familySharing => true,
    PremiumFeature.csvImport => true,
    PremiumFeature.homeWidgets => true,
    PremiumFeature.billReminders => true,
    PremiumFeature.autoTransactions => true,
    _ => false, // Count-based features or free features
  };
}

/// Premium feature descriptions for paywall and marketing
class PremiumFeatureInfo {
  final PremiumFeature feature;
  final String title;
  final String description;
  final String freeLimit;
  final String premiumLimit;
  final String iconName; // Lucide icon name for reference

  const PremiumFeatureInfo({
    required this.feature,
    required this.title,
    required this.description,
    required this.freeLimit,
    required this.premiumLimit,
    required this.iconName,
  });

  /// All premium features for display
  static const List<PremiumFeatureInfo> all = [
    // Count-based features (show limits)
    PremiumFeatureInfo(
      feature: PremiumFeature.unlimitedBankAccounts,
      title: 'Bank Accounts',
      description: 'Track all your bank accounts in one place',
      freeLimit: '2',
      premiumLimit: 'Unlimited',
      iconName: 'building2',
    ),
    PremiumFeatureInfo(
      feature: PremiumFeature.unlimitedPaymentMethods,
      title: 'Payment Methods',
      description: 'Add all your cards, UPI, and wallets',
      freeLimit: '3',
      premiumLimit: 'Unlimited',
      iconName: 'creditCard',
    ),
    PremiumFeatureInfo(
      feature: PremiumFeature.unlimitedGoals,
      title: 'Savings Goals',
      description: 'Set and track multiple financial goals',
      freeLimit: '1',
      premiumLimit: 'Unlimited',
      iconName: 'target',
    ),
    PremiumFeatureInfo(
      feature: PremiumFeature.unlimitedBudgets,
      title: 'Budgets',
      description: 'Create budgets for all your categories',
      freeLimit: '3',
      premiumLimit: 'Unlimited',
      iconName: 'pieChart',
    ),
    PremiumFeatureInfo(
      feature: PremiumFeature.unlimitedRecurring,
      title: 'Recurring Transactions',
      description: 'Automate regular income and expenses',
      freeLimit: '3',
      premiumLimit: 'Unlimited',
      iconName: 'repeat',
    ),
    PremiumFeatureInfo(
      feature: PremiumFeature.unlimitedCategories,
      title: 'Custom Categories',
      description: 'Create categories that fit your lifestyle',
      freeLimit: '3',
      premiumLimit: 'Unlimited',
      iconName: 'tag',
    ),
    PremiumFeatureInfo(
      feature: PremiumFeature.unlimitedReceiptScanning,
      title: 'Receipt Scanning',
      description: 'Scan and extract data from receipts',
      freeLimit: '5/month',
      premiumLimit: 'Unlimited',
      iconName: 'scan',
    ),

    // Locked features (Pro only)
    PremiumFeatureInfo(
      feature: PremiumFeature.cloudSync,
      title: 'Cloud Sync',
      description: 'Sync data across all your devices',
      freeLimit: 'Not available',
      premiumLimit: 'Full access',
      iconName: 'cloud',
    ),
    PremiumFeatureInfo(
      feature: PremiumFeature.pdfExport,
      title: 'PDF Reports',
      description: 'Export beautiful PDF reports',
      freeLimit: 'Not available',
      premiumLimit: 'Full access',
      iconName: 'fileText',
    ),
    PremiumFeatureInfo(
      feature: PremiumFeature.fullExport,
      title: 'Full Data Export',
      description: 'Export your complete financial history',
      freeLimit: 'Last 30 days',
      premiumLimit: 'All time',
      iconName: 'download',
    ),
    PremiumFeatureInfo(
      feature: PremiumFeature.advancedInsights,
      title: 'Advanced Insights',
      description: 'Charts, trends, and AI-powered analysis',
      freeLimit: 'Basic only',
      premiumLimit: 'Full access',
      iconName: 'barChart2',
    ),
    PremiumFeatureInfo(
      feature: PremiumFeature.adFree,
      title: 'Ad-Free Experience',
      description: 'Enjoy FlowLedger without any ads',
      freeLimit: 'Contains ads',
      premiumLimit: 'No ads',
      iconName: 'eyeOff',
    ),
  ];

  /// Features to show on paywall (most compelling first)
  static List<PremiumFeatureInfo> get paywallFeatures {
    return [
      all.firstWhere((f) => f.feature == PremiumFeature.cloudSync),
      all.firstWhere((f) => f.feature == PremiumFeature.unlimitedGoals),
      all.firstWhere((f) => f.feature == PremiumFeature.advancedInsights),
      all.firstWhere((f) => f.feature == PremiumFeature.pdfExport),
      all.firstWhere((f) => f.feature == PremiumFeature.unlimitedReceiptScanning),
      all.firstWhere((f) => f.feature == PremiumFeature.adFree),
    ];
  }

  /// Get feature info by feature type
  static PremiumFeatureInfo? getByFeature(PremiumFeature feature) {
    try {
      return all.firstWhere((f) => f.feature == feature);
    } catch (_) {
      return null;
    }
  }
}

/// Pricing information (for display purposes)
class PremiumPricing {
  // India pricing (primary market) - discounted prices
  static const String monthlyINR = '149';
  static const String yearlyINR = '999';
  static const String lifetimeINR = '2,499';

  // India original prices (for strikethrough display)
  static const String monthlyINROriginal = '299';
  static const String yearlyINROriginal = '1,799';
  static const String lifetimeINROriginal = '4,999';

  // USD pricing (international) - discounted prices
  static const String monthlyUSD = '1.99';
  static const String yearlyUSD = '9.99';
  static const String lifetimeUSD = '29.99';

  // USD original prices (for strikethrough display)
  static const String monthlyUSDOriginal = '3.99';
  static const String yearlyUSDOriginal = '17.99';
  static const String lifetimeUSDOriginal = '49.99';

  // Savings percentage for yearly
  static const int yearlySavingsPercent = 44;

  // Product IDs for stores
  static const String monthlyProductId = 'flowledger_pro_monthly';
  static const String yearlyProductId = 'flowledger_pro_yearly';
  static const String lifetimeProductId = 'flowledger_pro_lifetime';
}

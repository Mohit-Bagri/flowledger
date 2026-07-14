import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/subscription_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedPlanIndex = 1; // Default to annual (best value)
  bool _isPurchasing = false;

  // Determine if user is from India based on locale, timezone, and currency setting
  bool get _isIndianUser {
    // Check if user has selected INR as their currency in app settings
    if (CurrencyFormatter.currentCurrencyCode == 'INR') {
      return true;
    }

    final locale = Platform.localeName;
    // Check for Indian locale codes (en_IN, hi_IN, etc.)
    if (locale.contains('_IN') || locale.contains('IN') || locale.startsWith('hi')) {
      return true;
    }
    // Also check timezone for India (IST = Asia/Kolkata)
    try {
      final timeZone = DateTime.now().timeZoneName;
      final timeZoneOffset = DateTime.now().timeZoneOffset;
      // IST is UTC+5:30
      if (timeZone == 'IST' || timeZoneOffset == const Duration(hours: 5, minutes: 30)) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Pricing data - INR for India, USD for rest of the world
  List<_PlanData> get _plans {
    if (_isIndianUser) {
      return [
        _PlanData(
          name: 'Monthly',
          price: '₹149',
          originalPrice: '₹299',
          period: '/month',
          savings: 'Save 50%',
          packageType: PackageType.monthly,
        ),
        _PlanData(
          name: 'Annual',
          price: '₹999',
          originalPrice: '₹1,799',
          period: '/year',
          savings: 'Save 44%',
          packageType: PackageType.annual,
          isBestValue: true,
        ),
        _PlanData(
          name: 'Lifetime',
          price: '₹2,499',
          originalPrice: '₹4,999',
          period: 'one-time',
          savings: 'Save 50%',
          packageType: PackageType.lifetime,
        ),
      ];
    } else {
      // USD pricing for non-India users
      return [
        _PlanData(
          name: 'Monthly',
          price: '\$1.99',
          originalPrice: '\$3.99',
          period: '/month',
          savings: 'Save 50%',
          packageType: PackageType.monthly,
        ),
        _PlanData(
          name: 'Annual',
          price: '\$9.99',
          originalPrice: '\$17.99',
          period: '/year',
          savings: 'Save 44%',
          packageType: PackageType.annual,
          isBestValue: true,
        ),
        _PlanData(
          name: 'Lifetime',
          price: '\$29.99',
          originalPrice: '\$49.99',
          period: 'one-time',
          savings: 'Save 40%',
          packageType: PackageType.lifetime,
        ),
      ];
    }
  }

  Future<void> _handlePurchase() async {
    final l10n = AppLocalizations.of(context);
    final subscription = ref.read(subscriptionProvider);
    final packages = subscription.offerings?.current?.availablePackages ?? [];

    if (packages.isEmpty) {
      // Show info message when packages aren't configured
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.inAppPurchasesSoon ?? 'In-app purchases will be available soon!'),
            backgroundColor: AppColors.info,
          ),
        );
      }
      return;
    }

    // Find matching package
    final selectedPlan = _plans[_selectedPlanIndex];
    final package = packages.firstWhere(
      (p) => p.packageType == selectedPlan.packageType,
      orElse: () => packages.first,
    );

    setState(() => _isPurchasing = true);

    final result = await ref.read(subscriptionProvider.notifier).purchasePackage(package);

    if (mounted) {
      setState(() => _isPurchasing = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    // Watch subscription to rebuild when status changes
    ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  Text(
                    l10n?.flowLedgerPro ?? 'FlowLedger PRO',
                    style: AppTypography.h4.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      LucideIcons.x,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Premium badge
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.crown,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      l10n?.unlockFinancialPotential ?? 'Unlock Your Financial Potential',
                      textAlign: TextAlign.center,
                      style: AppTypography.h3.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      l10n?.getUnlimitedAccess ?? 'Get unlimited access to all premium features',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Feature comparison table
                    _FeatureComparisonTable(isDark: isDark, l10n: l10n),

                    const SizedBox(height: 28),

                    // Plan selection cards
                    Text(
                      l10n?.chooseYourPlan ?? 'Choose Your Plan',
                      style: AppTypography.h4.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Plan cards in a row
                    Row(
                      children: List.generate(_plans.length, (index) {
                        final plan = _plans[index];
                        final isSelected = _selectedPlanIndex == index;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : 6,
                              right: index == _plans.length - 1 ? 0 : 6,
                            ),
                            child: _PlanCard(
                              plan: plan,
                              isSelected: isSelected,
                              isDark: isDark,
                              onTap: () => setState(() => _selectedPlanIndex = index),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // What you'll get section
                    _WhatYouGetSection(isDark: isDark, l10n: l10n),

                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),

            // Bottom purchase section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selected plan summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _plans[_selectedPlanIndex].name,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_plans[_selectedPlanIndex].originalPrice != null) ...[
                          Text(
                            _plans[_selectedPlanIndex].originalPrice!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${_plans[_selectedPlanIndex].price} ${_plans[_selectedPlanIndex].period}',
                          style: AppTypography.h4.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Purchase button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isPurchasing ? null : _handlePurchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isPurchasing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.sparkles, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n?.upgradeToPro ?? 'Upgrade to PRO',
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Restore purchases link
                    TextButton(
                      onPressed: () async {
                        final result = await ref.read(subscriptionProvider.notifier).restorePurchases();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message),
                              backgroundColor: result.success ? AppColors.success : AppColors.error,
                            ),
                          );
                          if (result.success) {
                            context.pop();
                          }
                        }
                      },
                      child: Text(
                        l10n?.restorePurchases ?? 'Restore Purchases',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    // Terms text
                    Text(
                      l10n?.cancelAnytime ?? 'Cancel anytime. Terms & Privacy Policy apply.',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanData {
  final String name;
  final String price;
  final String? originalPrice; // Original price for strikethrough display
  final String period;
  final String? savings;
  final PackageType packageType;
  final bool isBestValue;

  _PlanData({
    required this.name,
    required this.price,
    this.originalPrice,
    required this.period,
    this.savings,
    required this.packageType,
    this.isBestValue = false,
  });
}

class _PlanCard extends StatelessWidget {
  final _PlanData plan;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Best value badge
            if (plan.isBestValue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'BEST VALUE',
                  style: AppTypography.caption.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            else
              const SizedBox(height: 22),

            // Plan name
            Text(
              plan.name,
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),

            const SizedBox(height: 6),

            // Original price with strikethrough (if available)
            if (plan.originalPrice != null) ...[
              Text(
                plan.originalPrice!,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
            ],

            // Price
            Text(
              plan.price,
              style: AppTypography.h3.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                fontWeight: FontWeight.bold,
              ),
            ),

            // Period
            Text(
              plan.period,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 8),

            // Savings badge
            if (plan.savings != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.savings!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              )
            else
              const SizedBox(height: 20),

            const SizedBox(height: 8),

            // Selection indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(LucideIcons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureComparisonTable extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;

  const _FeatureComparisonTable({required this.isDark, this.l10n});

  @override
  Widget build(BuildContext context) {
    final unlimited = l10n?.unlimited ?? 'Unlimited';
    final last30Days = l10n?.last30Days ?? 'Last 30 days';
    final allTime = l10n?.allTime ?? 'All time';
    final features = [
      // Ads - most important differentiator first
      _ComparisonFeature(l10n?.containsAds ?? 'Contains Ads', '✓', '✗', isAdRow: true),
      // Premium-only features (most valuable)
      _ComparisonFeature(l10n?.cloudSync ?? 'Cloud Sync & Backup', '✗', '✓'),
      _ComparisonFeature(l10n?.pdfReports ?? 'PDF Reports', '✗', '✓'),
      _ComparisonFeature(l10n?.csvExport ?? 'CSV Export', last30Days, allTime),
      _ComparisonFeature(l10n?.advancedInsights ?? 'Advanced Insights', '✗', '✓'),
      _ComparisonFeature(l10n?.weeklySummaries ?? 'Weekly Summaries', '✓', '✓'),
      // Count-based features
      _ComparisonFeature(l10n?.featureReceiptScanning ?? 'Receipt Scans', '5/mo', unlimited),
      _ComparisonFeature(l10n?.bankAccounts ?? 'Bank Accounts', '2', unlimited),
      _ComparisonFeature(l10n?.paymentMethods ?? 'Payment Methods', '3', unlimited),
      _ComparisonFeature(l10n?.budgets ?? 'Budgets', '3', unlimited),
      _ComparisonFeature(l10n?.savingsGoals ?? 'Savings Goals', '1', unlimited),
      _ComparisonFeature(l10n?.recurringTransactions ?? 'Recurring Transactions', '3', unlimited),
      _ComparisonFeature(l10n?.featureCustomCategories ?? 'Custom Categories', '3', unlimited),
      _ComparisonFeature(l10n?.prioritySupport ?? 'Priority Support', '✗', '✓'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n?.feature ?? 'Feature',
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n?.free ?? 'Free',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PRO',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Feature rows
          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            final isLast = index == features.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder.withValues(alpha: 0.5)
                              : AppColors.lightBorder.withValues(alpha: 0.5),
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      feature.name,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildValueCell(feature.freeValue, false, isDark, isAdRow: feature.isAdRow),
                  ),
                  Expanded(
                    child: _buildValueCell(feature.proValue, true, isDark, isAdRow: feature.isAdRow),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildValueCell(String value, bool isPro, bool isDark, {bool isAdRow = false}) {
    if (value == '✓') {
      // For ad row: check mark for FREE means ads exist (bad), show in warning color
      // For regular rows: check mark for PRO means feature exists (good)
      return Icon(
        LucideIcons.check,
        size: 18,
        color: isAdRow
            ? AppColors.warning // Ads exist = warning/orange
            : (isPro ? AppColors.success : AppColors.primary),
      );
    } else if (value == '✗') {
      // For ad row: X mark for PRO means no ads (good), show in success color
      // For regular rows: X mark means feature missing
      return Icon(
        LucideIcons.x,
        size: 18,
        color: isAdRow && isPro
            ? AppColors.success // No ads = good (green)
            : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
      );
    } else {
      return Text(
        value,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(
          color: isPro
              ? AppColors.success
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          fontWeight: isPro ? FontWeight.w600 : FontWeight.normal,
        ),
      );
    }
  }
}

class _ComparisonFeature {
  final String name;
  final String freeValue;
  final String proValue;
  final bool isAdRow;

  _ComparisonFeature(this.name, this.freeValue, this.proValue, {this.isAdRow = false});
}

class _WhatYouGetSection extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;

  const _WhatYouGetSection({required this.isDark, this.l10n});

  @override
  Widget build(BuildContext context) {
    final benefits = [
      _Benefit(LucideIcons.shield, l10n?.noAdsEver ?? 'No Ads, Ever', l10n?.noAdsDesc ?? 'Enjoy a completely ad-free experience'),
      _Benefit(LucideIcons.cloud, l10n?.cloudSync ?? 'Cloud Sync', l10n?.featureCloudSyncDesc ?? 'Access your data from any device'),
      _Benefit(LucideIcons.barChart3, l10n?.advancedAnalytics ?? 'Advanced Analytics', l10n?.featureAdvancedInsightsDesc ?? 'Deep insights into your spending'),
      _Benefit(LucideIcons.headphones, l10n?.prioritySupport ?? 'Priority Support', l10n?.prioritySupportDesc ?? 'Get help when you need it'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.whatYoullGet ?? 'What You\'ll Get',
          style: AppTypography.h4.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),

        const SizedBox(height: 16),

        ...benefits.map((benefit) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  benefit.icon,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      benefit.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _Benefit {
  final IconData icon;
  final String title;
  final String description;

  _Benefit(this.icon, this.title, this.description);
}

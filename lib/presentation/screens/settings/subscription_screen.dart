import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/app_router.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subscription = ref.watch(subscriptionProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n?.subscription ?? 'Subscription',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: subscription.isLoading
          ? const Center(child: CircularProgressIndicator())
          : subscription.isPremium
              ? _PremiumUserView(
                  subscription: subscription,
                  isDark: isDark,
                  l10n: l10n,
                  ref: ref,
                  context: context,
                )
              : _FreeUserView(
                  isDark: isDark,
                  l10n: l10n,
                  ref: ref,
                  context: context,
                ),
    );
  }
}

/// View shown to Premium users
class _PremiumUserView extends StatelessWidget {
  final SubscriptionState subscription;
  final bool isDark;
  final AppLocalizations? l10n;
  final WidgetRef ref;
  final BuildContext context;

  const _PremiumUserView({
    required this.subscription,
    required this.isDark,
    required this.l10n,
    required this.ref,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
      children: [
        // Premium status card with gradient
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                LucideIcons.crown,
                size: 56,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.premium ?? 'Premium',
                style: AppTypography.h2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subscription.expirationDate != null
                    ? l10n?.renewsOn(_formatDate(subscription.expirationDate!)) ??
                        'Renews on ${_formatDate(subscription.expirationDate!)}'
                    : l10n?.lifetimeAccessLabel ?? 'Lifetime access',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Feature comparison table
        Text(
          l10n?.whatsIncluded ?? "What's included",
          style: AppTypography.h4.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),

        const SizedBox(height: 16),

        _FeatureComparisonTable(isDark: isDark, isPremium: true, l10n: l10n),

        const SizedBox(height: 24),

        // Restore purchases
        Center(
          child: TextButton(
            onPressed: () async {
              final result = await ref.read(subscriptionProvider.notifier).restorePurchases();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: Text(
              l10n?.restorePurchases ?? 'Restore Purchases',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// View shown to Free users - matches premium paywall style
class _FreeUserView extends StatelessWidget {
  final bool isDark;
  final AppLocalizations? l10n;
  final WidgetRef ref;
  final BuildContext context;

  const _FreeUserView({
    required this.isDark,
    required this.l10n,
    required this.ref,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
      children: [
        // Free plan status card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  LucideIcons.user,
                  size: 36,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.freePlan ?? 'Free Plan',
                style: AppTypography.h2.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n?.limitedFeatures ?? 'Limited features',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Upgrade to Premium button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.push(AppRoutes.paywall),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.crown, size: 22),
                const SizedBox(width: 10),
                Text(
                  l10n?.upgradeToPremium ?? 'Upgrade to Premium',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Feature comparison table
        Text(
          l10n?.whatsIncluded ?? "What's included",
          style: AppTypography.h4.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),

        const SizedBox(height: 16),

        _FeatureComparisonTable(isDark: isDark, isPremium: false, l10n: l10n),

        const SizedBox(height: 24),

        // Restore purchases
        Center(
          child: TextButton(
            onPressed: () async {
              final result = await ref.read(subscriptionProvider.notifier).restorePurchases();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: Text(
              l10n?.restorePurchases ?? 'Restore Purchases',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

/// Feature comparison table matching paywall style
class _FeatureComparisonTable extends StatelessWidget {
  final bool isDark;
  final bool isPremium;
  final AppLocalizations? l10n;

  const _FeatureComparisonTable({
    required this.isDark,
    required this.isPremium,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    // Feature list - ordered by priority (premium-only first, then count-based)
    final features = [
      // Ads row - highlighted differently
      _ComparisonFeature(
        l10n?.containsAds ?? 'Contains Ads',
        l10n?.yes ?? 'Yes',
        l10n?.no ?? 'No',
        includedInFree: false,
        isAdRow: true,
      ),
      // Premium-only features (most valuable)
      _ComparisonFeature(
        l10n?.featureCloudSync ?? 'Cloud Sync & Backup',
        '✗',
        '✓',
        includedInFree: false,
      ),
      _ComparisonFeature(
        l10n?.pdfReports ?? 'PDF Reports',
        '✗',
        '✓',
        includedInFree: false,
      ),
      _ComparisonFeature(
        l10n?.csvExport ?? 'CSV Export',
        l10n?.last30Days ?? 'Last 30 days',
        l10n?.allTime ?? 'All time',
        includedInFree: true,
      ),
      _ComparisonFeature(
        l10n?.featureAdvancedInsights ?? 'Advanced Insights',
        '✗',
        '✓',
        includedInFree: false,
      ),
      _ComparisonFeature(
        l10n?.weeklySummaries ?? 'Weekly Summaries',
        '✓',
        '✓',
        includedInFree: true,
      ),
      // Count-based features
      _ComparisonFeature(
        l10n?.featureReceiptScanning ?? 'Receipt Scans',
        '5/month',
        l10n?.unlimited ?? 'Unlimited',
        includedInFree: true,
      ),
      _ComparisonFeature(
        l10n?.featureBankAccounts ?? 'Bank Accounts',
        '2',
        l10n?.unlimited ?? 'Unlimited',
        includedInFree: true,
      ),
      _ComparisonFeature(
        l10n?.featurePaymentMethods ?? 'Payment Methods',
        '3',
        l10n?.unlimited ?? 'Unlimited',
        includedInFree: true,
      ),
      _ComparisonFeature(
        l10n?.featureBudgets ?? 'Budgets',
        '3',
        l10n?.unlimited ?? 'Unlimited',
        includedInFree: true,
      ),
      _ComparisonFeature(
        l10n?.featureSavingsGoals ?? 'Savings Goals',
        '1',
        l10n?.unlimited ?? 'Unlimited',
        includedInFree: true,
      ),
      _ComparisonFeature(
        l10n?.featureRecurring ?? 'Recurring Transactions',
        '3',
        l10n?.unlimited ?? 'Unlimited',
        includedInFree: true,
      ),
      _ComparisonFeature(
        l10n?.featureCustomCategories ?? 'Custom Categories',
        '3',
        l10n?.unlimited ?? 'Unlimited',
        includedInFree: true,
      ),
      _ComparisonFeature(
        l10n?.prioritySupport ?? 'Priority Support',
        '✗',
        '✓',
        includedInFree: false,
      ),
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
          // Header row
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
                      l10n?.pro ?? 'PRO',
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
                color: feature.isAdRow
                    ? (isDark
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.05))
                    : null,
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
                        fontWeight: feature.isAdRow ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildValueCell(feature.freeValue, false, isDark, feature.includedInFree, feature.isAdRow),
                  ),
                  Expanded(
                    child: _buildValueCell(feature.proValue, true, isDark, true, feature.isAdRow),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildValueCell(String value, bool isPro, bool isDark, bool isIncluded, [bool isAdRow = false]) {
    if (value == '✓') {
      return Icon(
        LucideIcons.check,
        size: 18,
        color: AppColors.success,
      );
    } else if (value == '✗') {
      return Icon(
        LucideIcons.x,
        size: 18,
        color: AppColors.error.withValues(alpha: 0.7),
      );
    } else {
      // Special handling for ad row - "Yes" is bad (red), "No" is good (green)
      Color color;
      if (isAdRow) {
        // For ads: Yes = red (bad), No = green (good)
        color = isPro ? AppColors.success : AppColors.error;
      } else {
        color = isPro
            ? AppColors.success
            : isIncluded
                ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                : AppColors.error;
      }

      return Text(
        value,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: (isPro || isAdRow) ? FontWeight.w600 : FontWeight.normal,
        ),
      );
    }
  }
}

class _ComparisonFeature {
  final String name;
  final String freeValue;
  final String proValue;
  final bool includedInFree;
  final bool isAdRow;

  _ComparisonFeature(this.name, this.freeValue, this.proValue, {required this.includedInFree, this.isAdRow = false});
}

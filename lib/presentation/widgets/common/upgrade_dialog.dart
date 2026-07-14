import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/premium_features.dart';
import '../../../l10n/generated/app_localizations.dart';

/// A dialog that prompts users to upgrade to premium when they hit a limit
class UpgradeDialog extends StatelessWidget {
  final PremiumFeature feature;
  final int? currentCount;
  final int? limit;

  const UpgradeDialog({
    super.key,
    required this.feature,
    this.currentCount,
    this.limit,
  });

  /// Show the upgrade dialog as a modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    required PremiumFeature feature,
    int? currentCount,
    int? limit,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UpgradeDialog(
        feature: feature,
        currentCount: currentCount,
        limit: limit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final featureInfo = PremiumFeatureInfo.getByFeature(feature);
    final isLocked = _isLockedFeature(feature);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusLarge),
          topRight: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 24),

              // Lock icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isLocked ? LucideIcons.lock : LucideIcons.crown,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                isLocked
                    ? (l10n?.premiumFeature ?? 'Premium Feature')
                    : (l10n?.limitReached ?? 'Limit Reached'),
                style: AppTypography.h3.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Message
              Text(
                _getMessage(context, featureInfo, isLocked),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),

              if (!isLocked && currentCount != null && limit != null) ...[
                const SizedBox(height: 16),

                // Progress indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground
                        : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$currentCount',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                      Text(
                        ' / $limit',
                        style: AppTypography.h4.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        featureInfo?.title ?? (l10n?.items ?? 'items'),
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Premium benefits
              _BenefitRow(
                icon: LucideIcons.infinity,
                text: l10n?.unlimitedAccess(featureInfo?.title ?? 'access') ?? 'Unlimited ${featureInfo?.title ?? 'access'}',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _BenefitRow(
                icon: LucideIcons.cloud,
                text: l10n?.cloudSyncAcrossDevices ?? 'Cloud sync across devices',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _BenefitRow(
                icon: LucideIcons.barChart2,
                text: l10n?.advancedInsightsReports ?? 'Advanced insights & reports',
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // Upgrade button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/paywall');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n?.upgradeToPremium ?? 'Upgrade to Premium',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Maybe later button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n?.maybeLater ?? 'Maybe Later',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _getMessage(BuildContext context, PremiumFeatureInfo? featureInfo, bool isLocked) {
    final l10n = AppLocalizations.of(context);
    if (isLocked) {
      final featureTitle = featureInfo?.title ?? (l10n?.feature ?? 'This feature');
      return l10n?.premiumFeatureExclusiveMessage(featureTitle) ?? '$featureTitle is available exclusively for Premium members. Upgrade to unlock all features!';
    } else {
      final title = featureInfo?.title.toLowerCase() ?? (l10n?.items ?? 'items');
      return l10n?.freeLimitReachedMessage(limit ?? 0, title) ?? 'You\'ve reached the free limit of $limit $title. Upgrade to Premium for unlimited access!';
    }
  }

  // Shadow the top-level function to use locally
  bool _isLockedFeature(PremiumFeature feature) {
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
      _ => false,
    };
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _BenefitRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.success, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

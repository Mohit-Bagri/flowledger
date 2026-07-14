import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/app_router.dart';
import '../../providers/subscription_provider.dart';

/// A widget that shows a blurred overlay with lock icon for premium features
class PremiumBlurOverlay extends ConsumerWidget {
  final Widget child;
  final String featureName;
  final String description;
  final bool showPreview;

  const PremiumBlurOverlay({
    super.key,
    required this.child,
    required this.featureName,
    this.description = 'Upgrade to Premium to unlock this feature',
    this.showPreview = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isPremium = ref.watch(isPremiumProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If premium, just show the child
    if (isPremium) {
      return child;
    }

    // Show blurred preview with overlay
    return Stack(
      children: [
        // The actual content (blurred for free users)
        if (showPreview)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: IgnorePointer(child: child),
          )
        else
          child,

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? AppColors.darkBackground : AppColors.lightBackground).withValues(alpha: 0.3),
                  (isDark ? AppColors.darkBackground : AppColors.lightBackground).withValues(alpha: 0.85),
                  (isDark ? AppColors.darkBackground : AppColors.lightBackground).withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Lock icon and upgrade button
        Positioned.fill(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withValues(alpha: 0.95)
                    : AppColors.lightCard.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lock icon with gradient background
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
                    child: const Icon(
                      LucideIcons.lock,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Feature name
                  Text(
                    featureName,
                    textAlign: TextAlign.center,
                    style: AppTypography.h4.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    description == 'Upgrade to Premium to unlock this feature'
                        ? (l10n?.unlockThisFeature ?? description)
                        : description,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Upgrade button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push(AppRoutes.subscription),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.crown, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.upgradeToPremium ?? 'Upgrade to Premium',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Benefits list
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground.withValues(alpha: 0.5)
                          : AppColors.lightBackground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _BenefitRow(
                          icon: LucideIcons.barChart3,
                          text: l10n?.deepSpendingAnalytics ?? 'Deep spending analytics',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _BenefitRow(
                          icon: LucideIcons.pieChart,
                          text: l10n?.categoryBreakdowns ?? 'Category breakdowns',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _BenefitRow(
                          icon: LucideIcons.trendingUp,
                          text: l10n?.trendComparisons ?? 'Trend comparisons',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
        Icon(
          icon,
          size: 16,
          color: AppColors.success,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

/// A simpler version just for small sections
class PremiumFeatureLock extends ConsumerWidget {
  final Widget child;
  final String featureName;

  const PremiumFeatureLock({
    super.key,
    required this.child,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isPremium = ref.watch(isPremiumProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isPremium) {
      return child;
    }

    return GestureDetector(
      onTap: () => context.push(AppRoutes.subscription),
      child: Stack(
        children: [
          // Blurred content
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: IgnorePointer(child: child),
          ),

          // Lock overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkCard : AppColors.lightCard).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.lock,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.pro ?? 'PRO',
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

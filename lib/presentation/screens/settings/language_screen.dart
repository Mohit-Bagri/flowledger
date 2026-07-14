import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/common/banner_ad_widget.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedLocale = ref.watch(localeProvider);
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
          l10n?.language ?? 'Language',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        children: [
          // System Default option
          _LanguageItem(
            name: l10n?.systemDefault ?? 'System Default',
            nativeName: '',
            isSelected: selectedLocale == null,
            isDark: isDark,
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(null);
              context.pop();
            },
          ),

          const SizedBox(height: AppDimensions.spacing8),

          // Divider
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          const SizedBox(height: AppDimensions.spacing8),

          // All supported languages
          ...SupportedLanguages.all.map((language) {
            final isSelected = selectedLocale?.languageCode == language.code;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
              child: _LanguageItem(
                name: language.name,
                nativeName: language.nativeName,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(language.locale);
                  context.pop();
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LanguageItem extends StatelessWidget {
  final String name;
  final String nativeName;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageItem({
    required this.name,
    required this.nativeName,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Row(
            children: [
              // Language icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : (isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.globe,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),

              // Language details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (nativeName.isNotEmpty && nativeName != name) ...[
                      const SizedBox(height: 2),
                      Text(
                        nativeName,
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Checkmark if selected
              if (isSelected)
                Icon(
                  LucideIcons.check,
                  color: AppColors.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

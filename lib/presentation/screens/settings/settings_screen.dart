import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/app_lock_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/storage_providers.dart';
import '../../../navigation/app_router.dart';
import '../../../services/supabase_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showAppearanceDialog(BuildContext context, WidgetRef ref, bool isDark) {
    final currentMode = ref.read(appThemeModeProvider);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(
              l10n?.appearance ?? 'Appearance',
              style: AppTypography.h4.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            );
          },
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            final isSelected = mode == currentMode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  ref.read(appThemeModeProvider.notifier).setTheme(mode);
                  Navigator.pop(dialogContext);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        mode == AppThemeMode.light
                            ? LucideIcons.sun
                            : mode == AppThemeMode.dark
                                ? LucideIcons.moon
                                : LucideIcons.smartphone,
                        size: 22,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mode.label,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            if (mode == AppThemeMode.system)
                              Builder(
                                builder: (context) {
                                  final l10n = AppLocalizations.of(context);
                                  return Text(
                                    l10n?.followsDeviceSettings ?? 'Follows device settings',
                                    style: AppTypography.caption.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextTertiary
                                          : AppColors.lightTextTertiary,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          LucideIcons.check,
                          size: 20,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appThemeMode = ref.watch(appThemeModeProvider);
    final currency = ref.watch(currencyProvider);
    final locale = ref.watch(localeProvider);
    final appLockEnabled = ref.watch(appLockEnabledProvider);
    final subscription = ref.watch(subscriptionProvider);
    final isPremium = subscription.isPremium;
    final profile = ref.watch(profileProvider);
    final isAuthenticated = SupabaseService.instance.isAuthenticated;
    final l10n = AppLocalizations.of(context);

    // Get language name
    final languageName = locale == null
        ? (l10n?.systemDefault ?? 'System Default')
        : SupportedLanguages.getByCode(locale.languageCode)?.name ?? locale.languageCode;

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
          l10n?.settings ?? 'Settings',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        children: [
          // Account Section
          _SectionHeader(title: l10n?.account ?? 'ACCOUNT', isDark: isDark),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SettingsItem(
                icon: LucideIcons.user,
                title: l10n?.profile ?? 'Profile',
                subtitle: isAuthenticated
                    ? (profile.displayName ?? profile.email ?? (l10n?.notSignedIn ?? 'Not signed in'))
                    : (l10n?.notSignedIn ?? 'Not signed in'),
                onTap: () => context.push(AppRoutes.profile),
                isDark: isDark,
                leading: isAuthenticated && profile.avatarUrl != null
                    ? CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(profile.avatarUrl!),
                        onBackgroundImageError: (_, __) {},
                        child: profile.avatarUrl == null
                            ? Text(
                                (profile.displayName ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                      )
                    : null,
              ),
              _SettingsItem(
                icon: LucideIcons.lock,
                title: l10n?.appLock ?? 'App Lock',
                trailing: Switch(
                  value: appLockEnabled,
                  onChanged: (value) async {
                    final success = await ref.read(appLockEnabledProvider.notifier).setEnabled(value);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n?.couldNotEnableAppLock ?? 'Could not enable App Lock. Please check your device settings.'),
                        ),
                      );
                    }
                  },
                  activeColor: AppColors.primary,
                ),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: LucideIcons.gem,
                title: l10n?.subscription ?? 'Subscription',
                subtitle: subscription.isPremium ? (l10n?.premium ?? 'Premium') : (l10n?.freePlan ?? 'Free Plan'),
                onTap: () => context.push(AppRoutes.subscription),
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // Preferences Section
          _SectionHeader(title: l10n?.preferences ?? 'PREFERENCES', isDark: isDark),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SettingsItem(
                icon: LucideIcons.banknote,
                title: l10n?.currency ?? 'Currency',
                subtitle: '${currency.symbol} ${currency.code}',
                onTap: () => context.push(AppRoutes.currency),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: LucideIcons.globe,
                title: l10n?.language ?? 'Language',
                subtitle: languageName,
                onTap: () => context.push(AppRoutes.language),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: appThemeMode == AppThemeMode.light
                    ? LucideIcons.sun
                    : appThemeMode == AppThemeMode.dark
                        ? LucideIcons.moon
                        : LucideIcons.smartphone,
                title: l10n?.appearance ?? 'Appearance',
                subtitle: appThemeMode.label,
                onTap: () => _showAppearanceDialog(context, ref, isDark),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: LucideIcons.bell,
                title: l10n?.notifications ?? 'Notifications',
                onTap: () => context.push(AppRoutes.notifications),
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // Data Management Section
          _SectionHeader(title: l10n?.dataManagement ?? 'DATA MANAGEMENT', isDark: isDark),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SettingsItem(
                icon: LucideIcons.landmark,
                title: l10n?.bankAccounts ?? 'Bank Accounts',
                onTap: () => context.push(AppRoutes.bankAccounts),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: LucideIcons.creditCard,
                title: l10n?.paymentMethods ?? 'Payment Methods',
                onTap: () => context.push(AppRoutes.paymentMethods),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: LucideIcons.target,
                title: l10n?.budgets ?? 'Budgets',
                onTap: () => context.push(AppRoutes.budgets),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: LucideIcons.piggyBank,
                title: l10n?.savingsGoals ?? 'Savings Goals',
                onTap: () => context.push(AppRoutes.goals),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: LucideIcons.repeat,
                title: l10n?.recurringTransactions ?? 'Recurring Transactions',
                onTap: () => context.push(AppRoutes.recurring),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: LucideIcons.folder,
                title: l10n?.categories ?? 'Categories',
                onTap: () => context.push(AppRoutes.categories),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: LucideIcons.store,
                title: l10n?.merchants ?? 'Merchants',
                onTap: () => context.push(AppRoutes.merchants),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: LucideIcons.download,
                title: l10n?.exportData ?? 'Export Data',
                onTap: () => context.push(AppRoutes.export),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: LucideIcons.upload,
                title: l10n?.importCSV ?? 'Import CSV',
                onTap: () => context.push(AppRoutes.csvImport),
                isDark: isDark,
                isPremium: true,
              ),
              _SettingsItem(
                icon: LucideIcons.cloud,
                title: l10n?.cloudSync ?? 'Cloud Sync',
                onTap: () => context.push(AppRoutes.cloudSync),
                isDark: isDark,
              ),
              _SettingsItem(
                icon: LucideIcons.trash2,
                title: l10n?.clearAllData ?? 'Clear All Data',
                titleColor: AppColors.error,
                onTap: () => _showClearDataDialog(context, ref, isDark),
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // About Section
          _SectionHeader(title: l10n?.about ?? 'ABOUT', isDark: isDark),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SettingsItem(
                icon: LucideIcons.info,
                title: l10n?.aboutFlowLedger ?? 'About FlowLedger',
                onTap: () => context.push(AppRoutes.about),
                isDark: isDark,
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // Debug Section (only in debug builds)
          if (kDebugMode) ...[
            _SectionHeader(title: l10n?.developerOptions ?? 'DEVELOPER OPTIONS', isDark: isDark),
            _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsItem(
                  icon: LucideIcons.bug,
                  title: l10n?.debugPremiumMode ?? 'Debug Premium Mode',
                  subtitle: subscription.isDebugPremium ? (l10n?.enabled ?? 'Enabled') : (l10n?.disabled ?? 'Disabled'),
                  trailing: Switch(
                    value: subscription.isDebugPremium,
                    onChanged: (value) {
                      ref.read(subscriptionProvider.notifier).toggleDebugPremium();
                    },
                    activeColor: AppColors.primary,
                  ),
                  isDark: isDark,
                  showDivider: false,
                ),
              ],
            ),
            if (subscription.isDebugPremium)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Debug mode: Premium features unlocked without real purchase',
                          style: AppTypography.caption.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppDimensions.spacing24),
          ],

          // Version
          Center(
            child: Text(
              '${l10n?.version ?? 'Version'} 1.0.0${kDebugMode ? ' (Debug)' : ''}',
              style: AppTypography.caption.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref, bool isDark) {
    final isAuthenticated = SupabaseService.instance.isAuthenticated;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.alertTriangle,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Clear All Data?',
              style: AppTypography.h4.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action will permanently delete all your local data including:',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildDeleteItem('All transactions', isDark),
            _buildDeleteItem('Bank accounts & payment methods', isDark),
            _buildDeleteItem('Budgets & savings goals', isDark),
            _buildDeleteItem('Custom categories', isDark),
            _buildDeleteItem('Recurring transactions', isDark),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAuthenticated
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAuthenticated
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAuthenticated ? LucideIcons.cloud : LucideIcons.cloudOff,
                    size: 18,
                    color: isAuthenticated ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAuthenticated
                          ? (l10n?.clearDataCloudNote ??
                              'Your cloud data will remain safe. You can restore by syncing again.')
                          : (l10n?.clearDataWarning ??
                              'This will permanently delete all your local data. Cloud sync is not enabled.'),
                      style: AppTypography.caption.copyWith(
                        color: isAuthenticated ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertCircle, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _clearAllData(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            LucideIcons.trash2,
            size: 14,
            color: AppColors.error.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Clearing data...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Clear all data from storage
      final storage = ref.read(storageServiceProvider);
      await storage.clearAllData();

      // Refresh all providers
      ref.invalidate(expensesProvider);
      ref.invalidate(incomeSourcesProvider);
      ref.invalidate(recurringTransactionsProvider);
      ref.invalidate(bankAccountsProvider);
      ref.invalidate(paymentMethodsProvider);
      ref.invalidate(budgetsProvider);
      ref.invalidate(goalsProvider);
      ref.invalidate(customExpenseCategoriesProvider);
      ref.invalidate(customIncomeCategoriesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text('All local data has been cleared'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: AppDimensions.spacing8,
      ),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool isDark;
  final bool showDivider;
  final bool isPremium;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.leading,
    this.onTap,
    required this.isDark,
    this.showDivider = true,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppDimensions.spacing12),
                ] else ...[
                  Icon(
                    icon,
                    size: 22,
                    color: titleColor ??
                        (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                  const SizedBox(width: AppDimensions.spacing12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: titleColor ??
                          (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: AppDimensions.spacing8),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (isPremium) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PRO',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (trailing != null) trailing!,
                if (trailing == null && onTap != null)
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppDimensions.spacing16 + 22 + AppDimensions.spacing12,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
      ],
    );
  }
}

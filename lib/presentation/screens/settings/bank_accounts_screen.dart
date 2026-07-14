import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/premium_features.dart';
import '../../../core/services/biometric_service.dart';
import '../../../data/models/bank_account.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/storage_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/upgrade_dialog.dart';
import 'add_bank_account_sheet.dart';
import '../../widgets/common/banner_ad_widget.dart';

class BankAccountsScreen extends ConsumerWidget {
  const BankAccountsScreen({super.key});

  void _addAccount(BuildContext context, WidgetRef ref) async {
    // Check premium limit
    final accounts = ref.read(bankAccountsProvider);
    final canAdd = ref.read(subscriptionProvider.notifier).canAddMore(
      PremiumFeature.unlimitedBankAccounts,
      accounts.length,
    );

    if (!canAdd) {
      UpgradeDialog.show(
        context,
        feature: PremiumFeature.unlimitedBankAccounts,
        currentCount: accounts.length,
        limit: FreeTierLimits.bankAccounts,
      );
      return;
    }

    final result = await AddBankAccountSheet.show(context);
    if (result != null) {
      ref.read(bankAccountsProvider.notifier).addAccount(result);
    }
  }

  void _editAccount(BuildContext context, WidgetRef ref, BankAccount account) async {
    // Authenticate before editing
    final authenticated = await BiometricService.instance.authenticateForEdit();
    if (!authenticated) return;

    final result = await AddBankAccountSheet.show(context, account: account);
    if (result != null) {
      ref.read(bankAccountsProvider.notifier).updateAccount(result);
    }
  }

  void _deleteAccount(BuildContext context, WidgetRef ref, BankAccount account, AppLocalizations? l10n) async {
    // Authenticate before deleting
    final authenticated = await BiometricService.instance.authenticateForDelete();
    if (!authenticated) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          title: Text(
            l10n?.deleteAccount ?? 'Delete Account',
            style: AppTypography.h4.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${account.accountName}"? This action cannot be undone.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                l10n?.cancel ?? 'Cancel',
                style: AppTypography.labelLarge.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(bankAccountsProvider.notifier).deleteAccount(account.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n?.accountDeleted ?? 'Account deleted')),
                );
              },
              child: Text(
                l10n?.delete ?? 'Delete',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accounts = ref.watch(bankAccountsProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final limit = FreeTierLimits.bankAccounts;

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
          l10n?.bankAccounts ?? 'Bank Accounts',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        actions: [
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accounts.length >= limit
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${accounts.length}/$limit',
                    style: AppTypography.labelSmall.copyWith(
                      color: accounts.length >= limit
                          ? AppColors.warning
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: accounts.isEmpty
          ? _EmptyState(isDark: isDark, onAdd: () => _addAccount(context, ref), l10n: l10n)
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return _BankAccountCard(
                  account: account,
                  isDark: isDark,
                  onEdit: () => _editAccount(context, ref, account),
                  onDelete: () => _deleteAccount(context, ref, account, l10n),
                  l10n: l10n,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAccount(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          l10n?.addAccount ?? 'Add Account',
          style: AppTypography.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;
  final AppLocalizations? l10n;

  const _EmptyState({
    required this.isDark,
    required this.onAdd,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.landmark,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            Text(
              l10n?.noBankAccountsConfigured ?? 'No Bank Accounts Yet',
              style: AppTypography.h4.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              l10n?.tapToAddBankAccount ?? 'Add your bank accounts to track\nincome and expenses by account.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n?.addBankAccount ?? 'Add Bank Account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  final BankAccount account;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final AppLocalizations? l10n;

  const _BankAccountCard({
    required this.account,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacing16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: account.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Icon(
                    LucideIcons.landmark,
                    color: account.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.accountName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            account.bankName,
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          if (account.accountNumber != null) ...[
                            Text(
                              ' • ',
                              style: AppTypography.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                            Text(
                              account.displayAccountNumber,
                              style: AppTypography.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: account.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          account.accountType.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: account.color,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.moreVertical,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.pencil,
                            size: 18,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.fingerprint,
                            size: 14,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(l10n?.edit ?? 'Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.fingerprint,
                            size: 14,
                            color: AppColors.error.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.delete ?? 'Delete',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

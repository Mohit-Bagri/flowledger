import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/premium_features.dart';
import '../../../core/services/biometric_service.dart';
import '../../../data/models/payment_method.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/storage_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/upgrade_dialog.dart';
import 'add_payment_method_sheet.dart';
import '../../widgets/common/banner_ad_widget.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  void _addMethod(BuildContext context, WidgetRef ref) async {
    // Check premium limit
    final methods = ref.read(paymentMethodsProvider);
    final canAdd = ref.read(subscriptionProvider.notifier).canAddMore(
      PremiumFeature.unlimitedPaymentMethods,
      methods.length,
    );

    if (!canAdd) {
      UpgradeDialog.show(
        context,
        feature: PremiumFeature.unlimitedPaymentMethods,
        currentCount: methods.length,
        limit: FreeTierLimits.paymentMethods,
      );
      return;
    }

    final result = await AddPaymentMethodSheet.show(context);
    if (result != null) {
      ref.read(paymentMethodsProvider.notifier).addMethod(result);
    }
  }

  void _editMethod(BuildContext context, WidgetRef ref, PaymentMethod method) async {
    // Authenticate before editing
    final authenticated = await BiometricService.instance.authenticateForEdit();
    if (!authenticated) return;

    final result = await AddPaymentMethodSheet.show(context, method: method);
    if (result != null) {
      ref.read(paymentMethodsProvider.notifier).updateMethod(result);
    }
  }

  void _deleteMethod(BuildContext context, WidgetRef ref, PaymentMethod method, AppLocalizations? l10n) async {
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
            l10n?.deletePaymentMethod ?? 'Delete Payment Method',
            style: AppTypography.h4.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Text(
            l10n?.deletePaymentMethodConfirm(method.name) ?? 'Are you sure you want to delete "${method.name}"? This action cannot be undone.',
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
                ref.read(paymentMethodsProvider.notifier).deleteMethod(method.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n?.paymentMethodDeleted ?? 'Payment method deleted')),
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

  void _addMethodWithType(BuildContext context, WidgetRef ref, PaymentMethodType type) async {
    // Check premium limit
    final methods = ref.read(paymentMethodsProvider);
    final canAdd = ref.read(subscriptionProvider.notifier).canAddMore(
      PremiumFeature.unlimitedPaymentMethods,
      methods.length,
    );

    if (!canAdd) {
      UpgradeDialog.show(
        context,
        feature: PremiumFeature.unlimitedPaymentMethods,
        currentCount: methods.length,
        limit: FreeTierLimits.paymentMethods,
      );
      return;
    }

    final result = await AddPaymentMethodSheet.show(context, initialType: type);
    if (result != null) {
      ref.read(paymentMethodsProvider.notifier).addMethod(result);
    }
  }

  void _addCashIfNotExists(BuildContext context, WidgetRef ref, List<PaymentMethod> methods, AppLocalizations? l10n) {
    // Check premium limit
    final canAdd = ref.read(subscriptionProvider.notifier).canAddMore(
      PremiumFeature.unlimitedPaymentMethods,
      methods.length,
    );

    if (!canAdd) {
      UpgradeDialog.show(
        context,
        feature: PremiumFeature.unlimitedPaymentMethods,
        currentCount: methods.length,
        limit: FreeTierLimits.paymentMethods,
      );
      return;
    }

    final hasCash = methods.any((m) => m.type == PaymentMethodType.cash);
    if (hasCash) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.cashAlreadyAdded ?? 'Cash is already added')),
      );
    } else {
      ref.read(paymentMethodsProvider.notifier).addMethod(PaymentMethod.cash);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.cashAdded ?? 'Cash added')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final methods = ref.watch(paymentMethodsProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final limit = FreeTierLimits.paymentMethods;

    // Group methods by type
    final groupedMethods = <PaymentMethodType, List<PaymentMethod>>{};
    for (final method in methods) {
      groupedMethods.putIfAbsent(method.type, () => []).add(method);
    }

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
          l10n?.paymentMethods ?? 'Payment Methods',
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
                    color: methods.length >= limit
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${methods.length}/$limit',
                    style: AppTypography.labelSmall.copyWith(
                      color: methods.length >= limit
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
      body: methods.isEmpty
          ? _EmptyState(isDark: isDark, onAdd: () => _addMethod(context, ref), l10n: l10n)
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
              children: [
                // Quick Add Presets
                _QuickAddSection(
                  isDark: isDark,
                  onAddUpi: () => _addMethodWithType(context, ref, PaymentMethodType.upi),
                  onAddCard: () => _addMethodWithType(context, ref, PaymentMethodType.creditCard),
                  onAddCash: () => _addCashIfNotExists(context, ref, methods, l10n),
                  l10n: l10n,
                ),
                const SizedBox(height: AppDimensions.spacing24),

                // Methods list
                ...groupedMethods.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          bottom: AppDimensions.spacing8,
                        ),
                        child: Text(
                          entry.key.label.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...entry.value.map((method) => _PaymentMethodCard(
                            method: method,
                            isDark: isDark,
                            onEdit: () => _editMethod(context, ref, method),
                            onDelete: () => _deleteMethod(context, ref, method, l10n),
                            l10n: l10n,
                          )),
                      const SizedBox(height: AppDimensions.spacing16),
                    ],
                  );
                }),

                const SizedBox(height: 60), // Space for FAB
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMethod(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          l10n?.addMethod ?? 'Add Method',
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
                LucideIcons.creditCard,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            Text(
              l10n?.noPaymentMethodsYet ?? 'No Payment Methods Yet',
              style: AppTypography.h4.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              l10n?.addPaymentMethodsDesc ?? 'Add your payment methods to track\nexpenses more accurately.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n?.addPaymentMethod ?? 'Add Payment Method'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddSection extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAddUpi;
  final VoidCallback onAddCard;
  final VoidCallback onAddCash;
  final AppLocalizations? l10n;

  const _QuickAddSection({
    required this.isDark,
    required this.onAddUpi,
    required this.onAddCard,
    required this.onAddCash,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppDimensions.spacing8),
          child: Text(
            (l10n?.quickSet ?? 'Quick Add').toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _QuickAddButton(
                icon: LucideIcons.smartphone,
                label: 'UPI',
                color: AppColors.primary,
                onTap: onAddUpi,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: _QuickAddButton(
                icon: LucideIcons.creditCard,
                label: l10n?.card ?? 'Card',
                color: AppColors.warning,
                onTap: onAddCard,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: _QuickAddButton(
                icon: LucideIcons.banknote,
                label: l10n?.cash ?? 'Cash',
                color: AppColors.success,
                onTap: onAddCash,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickAddButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final AppLocalizations? l10n;

  const _PaymentMethodCard({
    required this.method,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing8),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Icon(
                    method.icon,
                    color: method.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (method.lastFourDigits != null || method.upiId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          method.lastFourDigits != null
                              ? '****${method.lastFourDigits}'
                              : method.upiId ?? '',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontFamily: method.lastFourDigits != null ? 'monospace' : null,
                          ),
                        ),
                      ],
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
                            style: const TextStyle(color: AppColors.error),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/premium_features.dart';
import '../../../core/services/biometric_service.dart';
import '../../../data/models/expense.dart';
import '../../../data/models/income.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/storage_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/upgrade_dialog.dart';
import '../../widgets/common/banner_ad_widget.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customExpenseCategories = ref.watch(customExpenseCategoriesProvider);
    final customIncomeCategories = ref.watch(customIncomeCategoriesProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final totalCustomCategories = customExpenseCategories.length + customIncomeCategories.length;
    final limit = FreeTierLimits.customCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.categories ?? 'Categories'),
        actions: [
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: totalCustomCategories >= limit
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalCustomCategories/$limit',
                    style: AppTypography.labelSmall.copyWith(
                      color: totalCustomCategories >= limit
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
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        children: [
          // ========== INCOME CATEGORIES ==========
          _SectionTitle(
            title: (l10n?.incomeCategories ?? 'Income Categories').toUpperCase(),
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // System Income Categories
          _SubSectionHeader(
            title: l10n?.systemCategory ?? 'System',
            count: IncomeCategories.all.length,
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          _CategoryCard(
            isDark: isDark,
            children: IncomeCategories.all.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              final isLast = index == IncomeCategories.all.length - 1;
              return _CategoryTile(
                icon: category.icon,
                color: category.color,
                name: category.name,
                isSystem: true,
                showDivider: !isLast,
                isDark: isDark,
                l10n: l10n,
              );
            }).toList(),
          ),

          const SizedBox(height: AppDimensions.spacing16),

          // Custom Income Categories
          _SubSectionHeader(
            title: l10n?.customCategory ?? 'Custom',
            count: customIncomeCategories.length,
            isDark: isDark,
            onAdd: () => _showAddCategorySheet(context, ref, isIncome: true, l10n: l10n),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          if (customIncomeCategories.isEmpty)
            _EmptyCategoryCard(
              message: l10n?.noCustomIncomeCategoriesYet ?? 'No custom income categories yet',
              hint: 'Add one by tapping the + button above or select "Other" when adding income',
              isDark: isDark,
            )
          else
            _CategoryCard(
              isDark: isDark,
              children: customIncomeCategories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final isLast = index == customIncomeCategories.length - 1;
                return _CategoryTile(
                  icon: category.icon,
                  color: category.color,
                  name: category.name,
                  isSystem: false,
                  showDivider: !isLast,
                  isDark: isDark,
                  onEdit: () => _editIncomeCategory(context, ref, category, l10n),
                  onDelete: () => _deleteIncomeCategory(context, ref, category, l10n),
                  l10n: l10n,
                );
              }).toList(),
            ),

          const SizedBox(height: AppDimensions.spacing32),

          // ========== EXPENSE CATEGORIES ==========
          _SectionTitle(
            title: (l10n?.expenseCategories ?? 'Expense Categories').toUpperCase(),
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.spacing12),

          // System Expense Categories
          _SubSectionHeader(
            title: l10n?.systemCategory ?? 'System',
            count: ExpenseCategories.all.length,
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          _CategoryCard(
            isDark: isDark,
            children: ExpenseCategories.all.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              final isLast = index == ExpenseCategories.all.length - 1;
              return _CategoryTile(
                icon: category.icon,
                color: category.color,
                name: category.name,
                isSystem: true,
                showDivider: !isLast,
                isDark: isDark,
                l10n: l10n,
              );
            }).toList(),
          ),

          const SizedBox(height: AppDimensions.spacing16),

          // Custom Expense Categories
          _SubSectionHeader(
            title: l10n?.customCategory ?? 'Custom',
            count: customExpenseCategories.length,
            isDark: isDark,
            onAdd: () => _showAddCategorySheet(context, ref, isIncome: false, l10n: l10n),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          if (customExpenseCategories.isEmpty)
            _EmptyCategoryCard(
              message: l10n?.noCustomExpenseCategoriesYet ?? 'No custom expense categories yet',
              hint: 'Add one by tapping the + button above or select "Other" when adding expense',
              isDark: isDark,
            )
          else
            _CategoryCard(
              isDark: isDark,
              children: customExpenseCategories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final isLast = index == customExpenseCategories.length - 1;
                return _CategoryTile(
                  icon: category.icon,
                  color: category.color,
                  name: category.name,
                  isSystem: false,
                  showDivider: !isLast,
                  isDark: isDark,
                  onEdit: () => _editExpenseCategory(context, ref, category, l10n),
                  onDelete: () => _deleteExpenseCategory(context, ref, category, l10n),
                  l10n: l10n,
                );
              }).toList(),
            ),

          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context, WidgetRef ref, {required bool isIncome, AppLocalizations? l10n}) {
    // Check premium limit - count total custom categories (income + expense)
    final customExpense = ref.read(customExpenseCategoriesProvider);
    final customIncome = ref.read(customIncomeCategoriesProvider);
    final totalCustomCategories = customExpense.length + customIncome.length;
    final canAdd = ref.read(subscriptionProvider.notifier).canAddMore(
      PremiumFeature.unlimitedCategories,
      totalCustomCategories,
    );

    if (!canAdd) {
      UpgradeDialog.show(
        context,
        feature: PremiumFeature.unlimitedCategories,
        currentCount: totalCustomCategories,
        limit: FreeTierLimits.customCategories,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddCategorySheet(
        isIncome: isIncome,
        l10n: l10n,
        onSave: (name, icon, color) async {
          if (isIncome) {
            final category = IncomeCategoryModel(
              id: 'custom_income_${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              icon: icon,
              color: color,
              isSystem: false,
              sortOrder: 100,
              createdAt: DateTime.now(),
            );
            await ref.read(customIncomeCategoriesProvider.notifier).addCategory(category);
          } else {
            final category = ExpenseCategory(
              id: 'custom_expense_${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              icon: icon,
              color: color,
              isSystem: false,
              sortOrder: 100,
              createdAt: DateTime.now(),
            );
            await ref.read(customExpenseCategoriesProvider.notifier).addCategory(category);
          }
        },
      ),
    );
  }

  void _editIncomeCategory(BuildContext context, WidgetRef ref, IncomeCategoryModel category, AppLocalizations? l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditCategorySheet(
        isIncome: true,
        currentName: category.name,
        currentIcon: category.icon,
        currentColor: category.color,
        l10n: l10n,
        onSave: (name, icon, color) async {
          // Step 1: Show warning about affecting data
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n?.updateCategory ?? 'Update Category'),
              content: Text(l10n?.updateCategoryForAllIncome ?? 'This will update the category for all existing income entries. Continue?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n?.update ?? 'Update'),
                ),
              ],
            ),
          );

          if (confirm != true) return;

          // Step 2: Authenticate
          final authenticated = await BiometricService.instance.authenticateForEdit();
          if (!authenticated) return;

          // Step 3: Update
          final updatedCategory = category.copyWith(
            name: name,
            icon: icon,
            color: color,
          );
          await ref.read(customIncomeCategoriesProvider.notifier).updateCategory(updatedCategory);
        },
      ),
    );
  }

  void _editExpenseCategory(BuildContext context, WidgetRef ref, ExpenseCategory category, AppLocalizations? l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditCategorySheet(
        isIncome: false,
        currentName: category.name,
        currentIcon: category.icon,
        currentColor: category.color,
        l10n: l10n,
        onSave: (name, icon, color) async {
          // Step 1: Show warning about affecting data
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n?.updateCategory ?? 'Update Category'),
              content: Text(l10n?.updateCategoryForAllExpense ?? 'This will update the category for all existing expense entries. Continue?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n?.update ?? 'Update'),
                ),
              ],
            ),
          );

          if (confirm != true) return;

          // Step 2: Authenticate
          final authenticated = await BiometricService.instance.authenticateForEdit();
          if (!authenticated) return;

          // Step 3: Update
          final updatedCategory = category.copyWith(
            name: name,
            icon: icon,
            color: color,
          );
          await ref.read(customExpenseCategoriesProvider.notifier).updateCategory(updatedCategory);
        },
      ),
    );
  }

  void _deleteIncomeCategory(BuildContext context, WidgetRef ref, IncomeCategoryModel category, AppLocalizations? l10n) async {
    // Step 1: Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteCategory ?? 'Delete Category'),
        content: Text(l10n?.deleteCategoryConfirmIncome ?? 'Are you sure you want to delete "${category.name}"? This will affect all income entries using this category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n?.delete ?? 'Delete', style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Step 2: Authenticate after confirmation
    final authenticated = await BiometricService.instance.authenticateForDelete();
    if (!authenticated) return;

    // Step 3: Delete
    await ref.read(customIncomeCategoriesProvider.notifier).deleteCategory(category.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.categoryDeleted ?? 'Category deleted')),
      );
    }
  }

  void _deleteExpenseCategory(BuildContext context, WidgetRef ref, ExpenseCategory category, AppLocalizations? l10n) async {
    // Step 1: Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteCategory ?? 'Delete Category'),
        content: Text(l10n?.deleteCategoryConfirmExpense ?? 'Are you sure you want to delete "${category.name}"? This will affect all expense entries using this category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n?.delete ?? 'Delete', style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Step 2: Authenticate after confirmation
    final authenticated = await BiometricService.instance.authenticateForDelete();
    if (!authenticated) return;

    // Step 3: Delete
    await ref.read(customExpenseCategoriesProvider.notifier).deleteCategory(category.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.categoryDeleted ?? 'Category deleted')),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SubSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool isDark;
  final VoidCallback? onAdd;

  const _SubSectionHeader({
    required this.title,
    required this.count,
    required this.isDark,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        const Spacer(),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                LucideIcons.plus,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _CategoryCard({
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

class _EmptyCategoryCard extends StatelessWidget {
  final String message;
  final String hint;
  final bool isDark;

  const _EmptyCategoryCard({
    required this.message,
    required this.hint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.folder,
            size: 32,
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing4),
          Text(
            hint,
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final bool isSystem;
  final bool showDivider;
  final bool isDark;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final AppLocalizations? l10n;

  const _CategoryTile({
    required this.icon,
    required this.color,
    required this.name,
    required this.isSystem,
    required this.showDivider,
    required this.isDark,
    this.onEdit,
    this.onDelete,
    this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          title: Text(
            name,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          trailing: isSystem
              ? Text(
                  l10n?.systemCategory ?? 'System',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                )
              : PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.moreVertical,
                    size: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(LucideIcons.pencil, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(l10n?.edit ?? 'Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text(l10n?.delete ?? 'Delete', style: const TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppDimensions.spacing16,
            endIndent: AppDimensions.spacing16,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
      ],
    );
  }
}

/// Available icons for custom categories with their colors
const List<({IconData icon, Color color})> _availableCategoryOptions = [
  (icon: LucideIcons.star, color: Color(0xFFF5A524)),
  (icon: LucideIcons.tag, color: Color(0xFF3CCF91)),
  (icon: LucideIcons.folder, color: Color(0xFF5B7CFA)),
  (icon: LucideIcons.box, color: Color(0xFFEC4899)),
  (icon: LucideIcons.briefcase, color: Color(0xFF8B5CF6)),
  (icon: LucideIcons.coins, color: Color(0xFF14B8A6)),
];

class _AddCategorySheet extends StatefulWidget {
  final bool isIncome;
  final Future<void> Function(String name, IconData icon, Color color) onSave;
  final AppLocalizations? l10n;

  const _AddCategorySheet({
    required this.isIncome,
    required this.onSave,
    this.l10n,
  });

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _controller = TextEditingController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedOption = _availableCategoryOptions[_selectedIndex];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.bottomSheetRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            Text(
              widget.isIncome
                  ? (widget.l10n?.addIncomeCategory ?? 'Add Income Category')
                  : (widget.l10n?.addExpenseCategory ?? 'Add Expense Category'),
              style: AppTypography.h4.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing20),

            // Icon Selector
            Text(
              widget.l10n?.chooseIconLabel ?? 'Choose Icon',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _availableCategoryOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? option.color.withValues(alpha: 0.2)
                          : (isDark ? AppColors.darkCard : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: isSelected
                            ? option.color
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      option.icon,
                      color: option.color,
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppDimensions.spacing20),

            // Category Name
            Text(
              widget.l10n?.categoryName ?? 'Category Name',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.l10n?.enterCategoryName ?? 'Enter category name...',
              ),
            ),

            const SizedBox(height: AppDimensions.spacing24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_controller.text.trim().isNotEmpty) {
                    await widget.onSave(
                      _controller.text.trim(),
                      selectedOption.icon,
                      selectedOption.color,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(widget.l10n?.addCategory ?? 'Add Category'),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing16),
          ],
        ),
      ),
    );
  }
}

class _EditCategorySheet extends StatefulWidget {
  final bool isIncome;
  final String currentName;
  final IconData currentIcon;
  final Color currentColor;
  final Future<void> Function(String name, IconData icon, Color color) onSave;
  final AppLocalizations? l10n;

  const _EditCategorySheet({
    required this.isIncome,
    required this.currentName,
    required this.currentIcon,
    required this.currentColor,
    required this.onSave,
    this.l10n,
  });

  @override
  State<_EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<_EditCategorySheet> {
  late final TextEditingController _controller;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);

    // Find the index of the current icon
    _selectedIndex = _availableCategoryOptions.indexWhere(
      (opt) => opt.icon.codePoint == widget.currentIcon.codePoint,
    );
    if (_selectedIndex == -1) _selectedIndex = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedOption = _availableCategoryOptions[_selectedIndex];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.bottomSheetRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            Text(
              widget.isIncome
                  ? (widget.l10n?.editIncomeCategory ?? 'Edit Income Category')
                  : (widget.l10n?.editExpenseCategory ?? 'Edit Expense Category'),
              style: AppTypography.h4.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              widget.l10n?.changesWillAffectExisting ?? 'Changes will affect all existing entries with this category',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing20),

            // Icon Selector
            Text(
              widget.l10n?.chooseIconLabel ?? 'Choose Icon',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _availableCategoryOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? option.color.withValues(alpha: 0.2)
                          : (isDark ? AppColors.darkCard : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: isSelected
                            ? option.color
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      option.icon,
                      color: option.color,
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppDimensions.spacing20),

            // Category Name
            Text(
              widget.l10n?.categoryName ?? 'Category Name',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            TextField(
              controller: _controller,
              autofocus: false,
              decoration: InputDecoration(
                hintText: widget.l10n?.enterCategoryName ?? 'Enter category name...',
              ),
            ),

            const SizedBox(height: AppDimensions.spacing24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_controller.text.trim().isNotEmpty) {
                    await widget.onSave(
                      _controller.text.trim(),
                      selectedOption.icon,
                      selectedOption.color,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(widget.l10n?.categoryUpdated ?? 'Category updated')),
                      );
                    }
                  }
                },
                child: Text(widget.l10n?.updateCategory ?? 'Update Category'),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing16),
          ],
        ),
      ),
    );
  }
}

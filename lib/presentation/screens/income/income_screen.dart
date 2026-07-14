import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/biometric_service.dart';
import '../../../data/models/income.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../providers/storage_providers.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/common/date_range_selector.dart';
import '../../widgets/common/banner_ad_widget.dart';
import '../../../services/ad_service.dart';
import 'add_income_sheet.dart';
import '../../../core/utils/currency_formatter.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  IncomeCategoryModel? _selectedFilter;

  void _showAllIncomeHistory(BuildContext parentContext, List<IncomeSource> incomeTransactions) {
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(parentContext);
    final sortedTransactions = List<IncomeSource>.from(incomeTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final bankAccounts = ref.read(bankAccountsProvider);
    final customCategories = ref.read(customIncomeCategoriesProvider);

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.bottomSheetRadius),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.income ?? 'Income',
                      style: AppTypography.h4.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '${sortedTransactions.length} ${l10n?.incomeTransactions ?? 'transactions'}',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List
              Expanded(
                child: sortedTransactions.isEmpty
                    ? Center(
                        child: Text(
                          l10n?.noIncomeYet ?? 'No income yet',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: sortedTransactions.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          indent: AppDimensions.screenPaddingHorizontal,
                          endIndent: AppDimensions.screenPaddingHorizontal,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        itemBuilder: (context, index) {
                          final transaction = sortedTransactions[index];
                          final category = IncomeCategories.getByIdWithCustom(transaction.categoryId, customCategories);
                          final bankAccount = transaction.bankAccountId != null
                              ? bankAccounts.where((b) => b.id == transaction.bankAccountId).firstOrNull
                              : null;

                          // Build subtitle with details
                          final details = <String>[
                            DateFormat('dd MMM yyyy').format(transaction.date),
                          ];
                          if (bankAccount != null) {
                            details.add(bankAccount.bankName);
                          }
                          if (transaction.isRecurring) {
                            details.add(l10n?.recurring ?? 'Recurring');
                          }

                          return ListTile(
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _showIncomeOptions(parentContext, transaction);
                            },
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              ),
                              child: Icon(
                                category.icon,
                                color: category.color,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              transaction.sourceName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            subtitle: Text(
                              details.join(' • '),
                              style: AppTypography.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '+${CurrencyFormatter.format(transaction.amount)}',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIncomeOptions(BuildContext parentContext, IncomeSource transaction) {
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(parentContext);

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.bottomSheetRadius),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                transaction.sourceName,
                style: AppTypography.h4.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ListTile(
                leading: Icon(
                  LucideIcons.eye,
                  color: AppColors.info,
                ),
                title: Text(
                  l10n?.viewDetails ?? 'View Details',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showIncomeDetails(parentContext, transaction);
                },
              ),
              ListTile(
                leading: Icon(
                  LucideIcons.pencil,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                title: Text(
                  l10n?.edit ?? 'Edit',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n?.authenticateToContinue ?? 'Requires authentication',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                trailing: Icon(
                  LucideIcons.fingerprint,
                  size: 18,
                  color: AppColors.primary,
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final authenticated = await BiometricService.instance.authenticateForEdit();
                  if (authenticated && mounted) {
                    AddIncomeSheet.show(parentContext, existingSource: transaction);
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  LucideIcons.trash2,
                  color: AppColors.error,
                ),
                title: Text(
                  l10n?.delete ?? 'Delete',
                  style: const TextStyle(color: AppColors.error),
                ),
                subtitle: Text(
                  l10n?.authenticateToContinue ?? 'Requires authentication',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                trailing: Icon(
                  LucideIcons.fingerprint,
                  size: 18,
                  color: AppColors.primary,
                ),
              onTap: () async {
                // Step 1: Show confirmation dialog first
                final confirm = await showDialog<bool>(
                  context: sheetContext,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l10n?.deleteIncome ?? 'Delete Income'),
                    content: Text('${l10n?.deleteIncomeConfirm ?? 'Are you sure you want to delete "${transaction.sourceName}"? This action cannot be undone.'}'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(l10n?.cancel ?? 'Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(l10n?.delete ?? 'Delete', style: const TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                // Step 2: Authenticate after confirmation
                final authenticated = await BiometricService.instance.authenticateForDelete();
                if (!authenticated) return;

                // Step 3: Delete and close sheet
                if (mounted) {
                  Navigator.pop(sheetContext);
                  ref.read(incomeSourcesProvider.notifier).deleteSource(transaction.id);
                  AdService.instance.showInterstitialIfDue();
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text(l10n?.incomeDeleted ?? 'Income deleted')),
                  );
                }
              },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showIncomeDetails(BuildContext parentContext, IncomeSource transaction) {
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(parentContext);
    final bankAccounts = ref.read(bankAccountsProvider);
    final customCategories = ref.read(customIncomeCategoriesProvider);
    final category = IncomeCategories.getByIdWithCustom(transaction.categoryId, customCategories);
    final bankAccount = transaction.bankAccountId != null
        ? bankAccounts.where((b) => b.id == transaction.bankAccountId).firstOrNull
        : null;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(parentContext).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.bottomSheetRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.transactionDetails ?? 'Income Details',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          transaction.sourceName,
                          style: AppTypography.h4.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: Icon(
                      LucideIcons.x,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Details
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
                child: Column(
                  children: [
                    // Amount Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.spacing20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.success.withValues(alpha: 0.15),
                            AppColors.success.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            l10n?.amount ?? 'Amount',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '+${CurrencyFormatter.format(transaction.amount)}',
                            style: AppTypography.h1.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing20),

                    // Details Grid
                    _DetailRow(
                      icon: LucideIcons.tag,
                      label: l10n?.category ?? 'Category',
                      value: category.name,
                      color: category.color,
                      isDark: isDark,
                    ),
                    _DetailRow(
                      icon: LucideIcons.calendar,
                      label: l10n?.date ?? 'Date',
                      value: DateFormat('dd MMMM yyyy').format(transaction.date),
                      isDark: isDark,
                    ),
                    if (bankAccount != null)
                      _DetailRow(
                        icon: LucideIcons.landmark,
                        label: l10n?.bankAccount ?? 'Bank Account',
                        value: '${bankAccount.bankName} - ${bankAccount.displayAccountNumber}',
                        isDark: isDark,
                      ),
                    if (transaction.isRecurring)
                      _DetailRow(
                        icon: LucideIcons.repeat,
                        label: l10n?.type ?? 'Type',
                        value: l10n?.recurringIncome ?? 'Recurring Income',
                        color: AppColors.info,
                        isDark: isDark,
                      ),
                    if (transaction.notes != null && transaction.notes!.isNotEmpty)
                      _DetailRow(
                        icon: LucideIcons.fileText,
                        label: l10n?.notes ?? 'Notes',
                        value: transaction.notes!,
                        isDark: isDark,
                        isMultiLine: true,
                      ),

                    const SizedBox(height: AppDimensions.spacing24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              final authenticated = await BiometricService.instance.authenticateForEdit();
                              if (authenticated && mounted) {
                                AddIncomeSheet.show(parentContext, existingSource: transaction);
                              }
                            },
                            icon: const Icon(LucideIcons.pencil, size: 18),
                            label: Text(l10n?.edit ?? 'Edit'),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacing12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: sheetContext,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n?.deleteIncome ?? 'Delete Income?'),
                                  content: Text(l10n?.deleteIncomeConfirm ?? 'Are you sure you want to delete "${transaction.sourceName}"?'),
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
                              final authenticated = await BiometricService.instance.authenticateForDelete();
                              if (!authenticated) return;
                              if (mounted) {
                                Navigator.pop(sheetContext);
                                ref.read(incomeSourcesProvider.notifier).deleteSource(transaction.id);
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  SnackBar(content: Text(l10n?.incomeDeleted ?? 'Income deleted')),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                            icon: const Icon(LucideIcons.trash2, size: 18),
                            label: Text(l10n?.delete ?? 'Delete'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    // Use date-filtered income transactions
    final incomeTransactions = ref.watch(filteredIncomeByDateProvider);
    final dateRange = ref.watch(dateRangeProvider);
    final customCategories = ref.watch(customIncomeCategoriesProvider);

    // Get default currency for display
    final defaultCurrency = ref.watch(currencyProvider);

    // Filter by category if filter is selected, and sort by date (newest first)
    final filteredList = _selectedFilter == null
        ? [...incomeTransactions]
        : incomeTransactions.where((t) => t.categoryId == _selectedFilter!.id).toList();
    final filteredTransactions = filteredList..sort((a, b) => b.date.compareTo(a.date));

    // Calculate total income - sum all amounts and display with current currency symbol
    // Currency is just for UI display, all amounts are summed regardless of stored currency code
    final totalIncome = incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final displayCurrencySymbol = defaultCurrency.symbol;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.income ?? 'Income',
                          style: AppTypography.h2.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        DateRangeSelector(isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing24),

                    // Total Income Card
                    _TotalIncomeCard(
                      isDark: isDark,
                      totalIncome: totalIncome,
                      currencySymbol: displayCurrencySymbol,
                      periodLabel: dateRange.periodLabel,
                      dateRange: dateRange.shortDateRangeLabel,
                    ),
                  ],
                ),
              ),
            ),

            // Category Filter
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingHorizontal,
                  ),
                  children: [
                    _FilterChip(
                      label: l10n?.all ?? 'All',
                      isSelected: _selectedFilter == null,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedFilter = null),
                    ),
                    ...IncomeCategories.all.where((c) => c.id != 'other').map((category) {
                      return _FilterChip(
                        label: category.name,
                        isSelected: _selectedFilter?.id == category.id,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedFilter = category),
                      );
                    }),
                    // Custom categories
                    ...ref.watch(customIncomeCategoriesProvider).map((category) {
                      return _FilterChip(
                        label: category.name,
                        isSelected: _selectedFilter?.id == category.id,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedFilter = category),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacing24),
            ),

            // Income Transactions Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingHorizontal,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n?.incomeTransactions ?? 'Income Transactions'} (${filteredTransactions.length})',
                      style: AppTypography.h4.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (filteredTransactions.length > 4)
                      GestureDetector(
                        onTap: () => _showAllIncomeHistory(context, ref.read(filteredIncomeByDateProvider)),
                        child: Text(
                          l10n?.seeAll ?? 'See All',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.spacing12),
            ),

            // Income Items
            if (filteredTransactions.isEmpty && _selectedFilter == null)
              // No income at all
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingHorizontal,
                  ),
                  padding: const EdgeInsets.all(AppDimensions.spacing32),
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
                        LucideIcons.wallet,
                        size: 48,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                      const SizedBox(height: AppDimensions.spacing16),
                      Text(
                        l10n?.noIncomeYet ?? 'No income yet',
                        style: AppTypography.h4.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      Text(
                        l10n?.tapPlusToAddIncome ?? 'Tap the + button to add your first income',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (filteredTransactions.isEmpty && _selectedFilter != null)
              // No income for selected category
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingHorizontal,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spacing24),
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
                          LucideIcons.folderSearch,
                          size: 48,
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppDimensions.spacing12),
                        Text(
                          l10n?.noCategoriesForFilter ?? 'No income in "${_selectedFilter!.name}" category',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.spacing8),
                        Text(
                          l10n?.tapAddIncomeToStart ?? 'Add income with this category to see it here',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final transaction = filteredTransactions[index];
                    final bankAccounts = ref.watch(bankAccountsProvider);

                    final bankAccount = transaction.bankAccountId != null
                        ? bankAccounts.where((b) => b.id == transaction.bankAccountId).firstOrNull
                        : null;
                    // Look up category including custom categories
                    final category = IncomeCategories.getByIdWithCustom(
                      transaction.categoryId,
                      customCategories,
                    );

                    return _IncomeSourceCard(
                      isDark: isDark,
                      transaction: transaction,
                      category: category,
                      bankAccountName: bankAccount != null
                          ? '${bankAccount.bankName} - ${bankAccount.displayAccountNumber}'
                          : null,
                      onDelete: () {
                        ref.read(incomeSourcesProvider.notifier).deleteSource(transaction.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n?.incomeDeleted ?? 'Income deleted')),
                        );
                      },
                      onViewDetails: () => _showIncomeDetails(context, transaction),
                    );
                  },
                  childCount: filteredTransactions.length > 10 ? 10 : filteredTransactions.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddIncomeSheet.show(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          l10n?.addIncome ?? 'Add Income',
          style: AppTypography.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _TotalIncomeCard extends StatelessWidget {
  final bool isDark;
  final double totalIncome;
  final String currencySymbol;
  final String periodLabel;
  final String dateRange;

  const _TotalIncomeCard({
    required this.isDark,
    required this.totalIncome,
    required this.currencySymbol,
    required this.periodLabel,
    required this.dateRange,
  });

  String _formatAmount(double amount, String symbol) {
    // Format number with proper separators
    final formatted = amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
    // Add thousand separators
    final parts = formatted.split('.');
    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$symbol${parts.join('.')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacing20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withValues(alpha: 0.15),
            AppColors.success.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.totalIncome ?? 'Total Income',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateRange,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Text(
            _formatAmount(totalIncome, currencySymbol),
            style: AppTypography.h1.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 36,
            ),
          ),
          if (totalIncome > 0) ...[
            const SizedBox(height: AppDimensions.spacing8),
            Row(
              children: [
                Icon(
                  LucideIcons.trendingUp,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n?.incomeReceived ?? 'Income received',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppDimensions.spacing8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        ),
      ),
    );
  }
}

class _IncomeSourceCard extends StatelessWidget {
  final bool isDark;
  final IncomeSource transaction;
  final IncomeCategoryModel category;
  final String? bankAccountName;
  final VoidCallback onDelete;
  final VoidCallback? onViewDetails;

  const _IncomeSourceCard({
    required this.isDark,
    required this.transaction,
    required this.category,
    this.bankAccountName,
    required this.onDelete,
    this.onViewDetails,
  });

  void _showOptionsSheet(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _IncomeOptionsSheet(
        isDark: isDark,
        transaction: transaction,
        onDelete: onDelete,
        onViewDetails: onViewDetails,
        parentContext: parentContext,
      ),
    );
  }

  String _formatAmount(double amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    final icon = category.icon;

    return GestureDetector(
      onTap: () => _showOptionsSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPaddingHorizontal,
          vertical: AppDimensions.spacing8,
        ),
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.sourceName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${_formatAmount(transaction.amount)}',
                    style: AppTypography.amountSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 12,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(transaction.date),
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      if (transaction.isRecurring) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.repeat,
                                    size: 10,
                                    color: AppColors.info,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    l10n?.recurring ?? 'Recurring',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.info,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Bank Account row
                  if (bankAccountName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.landmark,
                          size: 12,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            bankAccountName!,
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showOptionsSheet(context),
              child: Icon(
                LucideIcons.moreVertical,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Options sheet for income item with biometric authentication
class _IncomeOptionsSheet extends StatelessWidget {
  final bool isDark;
  final IncomeSource transaction;
  final VoidCallback onDelete;
  final VoidCallback? onViewDetails;
  final BuildContext parentContext;

  const _IncomeOptionsSheet({
    required this.isDark,
    required this.transaction,
    required this.onDelete,
    this.onViewDetails,
    required this.parentContext,
  });

  Future<void> _handleEdit(BuildContext sheetContext) async {
    Navigator.pop(sheetContext);
    // Authenticate before editing
    final authenticated = await BiometricService.instance.authenticateForEdit();
    if (authenticated && parentContext.mounted) {
      AddIncomeSheet.show(parentContext, existingSource: transaction);
    }
  }

  Future<void> _handleDelete(BuildContext sheetContext) async {
    final l10n = AppLocalizations.of(sheetContext);
    // Step 1: Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: sheetContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(
          l10n?.deleteIncome ?? 'Delete Income?',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          l10n?.deleteIncomeConfirm ?? 'Are you sure you want to delete "${transaction.sourceName}"? This action cannot be undone.',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n?.cancel ?? 'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n?.delete ?? 'Delete',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Step 2: Authenticate after confirmation
    final authenticated = await BiometricService.instance.authenticateForDelete();
    if (!authenticated) return;

    // Step 3: Delete and close sheet
    if (sheetContext.mounted) {
      Navigator.pop(sheetContext);
      onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.bottomSheetRadius),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              transaction.sourceName,
              style: AppTypography.h4.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ListTile(
              leading: Icon(
                LucideIcons.eye,
                color: AppColors.info,
              ),
              title: Text(
                l10n?.viewDetails ?? 'View Details',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onViewDetails?.call();
              },
            ),
            ListTile(
              leading: Icon(
                LucideIcons.pencil,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              title: Text(
                l10n?.edit ?? 'Edit',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              subtitle: Text(
                l10n?.authenticateToContinue ?? 'Requires authentication',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
              trailing: Icon(
                LucideIcons.fingerprint,
                size: 18,
                color: AppColors.primary,
              ),
              onTap: () => _handleEdit(context),
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.trash2,
                color: AppColors.error,
              ),
              title: Text(
                l10n?.delete ?? 'Delete',
                style: const TextStyle(color: AppColors.error),
              ),
              subtitle: Text(
                l10n?.authenticateToContinue ?? 'Requires authentication',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
              trailing: Icon(
                LucideIcons.fingerprint,
                size: 18,
                color: AppColors.primary,
              ),
              onTap: () => _handleDelete(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Detail row widget for view transaction sheet
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool isDark;
  final bool isMultiLine;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    required this.isDark,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color ?? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

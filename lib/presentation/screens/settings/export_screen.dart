import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/premium_features.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/export_service.dart';
import '../../providers/storage_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/upgrade_dialog.dart';
import '../../widgets/common/banner_ad_widget.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  String _dateRangeOption = 'this_month';
  bool _includeIncome = true;
  bool _includeExpenses = true;
  bool _isGenerating = false;

  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          l10n?.exportReports ?? 'Export Reports',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
        children: [
          // Date Range Section
          _buildSectionHeader(l10n?.dateRange ?? 'DATE RANGE', isDark),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                _buildDateRangeOption(l10n?.thisMonth ?? 'This Month', 'this_month', isDark),
                _buildDivider(isDark),
                _buildDateRangeOption(l10n?.lastMonth ?? 'Last Month', 'last_month', isDark),
                _buildDivider(isDark),
                _buildDateRangeOption(l10n?.last3Months ?? 'Last 3 Months', 'last_3_months', isDark),
                _buildDivider(isDark),
                _buildDateRangeOption(l10n?.thisYear ?? 'This Year', 'this_year', isDark),
                _buildDivider(isDark),
                _buildDateRangeOption(l10n?.custom ?? 'Custom', 'custom', isDark),
              ],
            ),
          ),

          if (_dateRangeOption == 'custom') ...[
            const SizedBox(height: AppDimensions.spacing16),
            _buildCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacing16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        label: l10n?.from ?? 'From',
                        date: _startDate,
                        onTap: () => _selectDate(true),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacing16),
                    Expanded(
                      child: _buildDatePicker(
                        label: l10n?.to ?? 'To',
                        date: _endDate,
                        onTap: () => _selectDate(false),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: AppDimensions.spacing24),

          // Include Options
          _buildSectionHeader(l10n?.include ?? 'INCLUDE', isDark),
          _buildCard(
            isDark: isDark,
            child: Column(
              children: [
                _buildToggleOption(
                  l10n?.incomeTransactions ?? 'Income Transactions',
                  LucideIcons.trendingUp,
                  _includeIncome,
                  (v) => setState(() => _includeIncome = v),
                  isDark,
                ),
                _buildDivider(isDark),
                _buildToggleOption(
                  l10n?.expenseTransactions ?? 'Expense Transactions',
                  LucideIcons.trendingDown,
                  _includeExpenses,
                  (v) => setState(() => _includeExpenses = v),
                  isDark,
                  showDivider: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // Selected Range Display
          _buildCard(
            isDark: isDark,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacing16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimensions.spacing12),
                  Expanded(
                    child: Text(
                      '${_dateFormat.format(_startDate)} - ${_dateFormat.format(_endDate)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.spacing32),

          // Export Buttons
          _buildSectionHeader(l10n?.exportAs ?? 'EXPORT AS', isDark),
          Builder(
            builder: (context) {
              final isPremium = ref.watch(isPremiumProvider);
              return Row(
                children: [
                  Expanded(
                    child: _buildExportButton(
                      icon: LucideIcons.fileText,
                      label: l10n?.pdfReport ?? 'PDF Report',
                      subtitle: l10n?.formattedReport ?? 'Formatted report',
                      onTap: _generatePdf,
                      isDark: isDark,
                      showProBadge: !isPremium,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing16),
                  Expanded(
                    child: _buildExportButton(
                      icon: LucideIcons.table,
                      label: l10n?.csvExport ?? 'CSV Export',
                      subtitle: isPremium ? (l10n?.spreadsheet ?? 'Spreadsheet') : (l10n?.last30Days ?? 'Last 30 days'),
                      onTap: _generateCsv,
                      isDark: isDark,
                      showProBadge: !isPremium,
                    ),
                  ),
                ],
              );
            },
          ),

          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spacing24),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),

          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: AppDimensions.spacing8,
      ),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: child,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: AppDimensions.spacing16 + 22 + AppDimensions.spacing12,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }

  Widget _buildDateRangeOption(String label, String value, bool isDark) {
    final isSelected = _dateRangeOption == value;
    return InkWell(
      onTap: () {
        setState(() {
          _dateRangeOption = value;
          _updateDateRange(value);
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        child: Row(
          children: [
            Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _dateFormat.format(date),
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark, {
    bool showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing16,
        vertical: AppDimensions.spacing12,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool showProBadge = false,
  }) {
    return InkWell(
      onTap: _isGenerating ? null : onTap,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: Container(
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                if (showProBadge)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PRO',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing12),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDateRange(String option) {
    final now = DateTime.now();
    switch (option) {
      case 'this_month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'last_month':
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
        break;
      case 'last_3_months':
        _startDate = DateTime(now.year, now.month - 2, 1);
        _endDate = now;
        break;
      case 'this_year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
      case 'custom':
        // Keep current dates
        break;
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _generatePdf() async {
    final l10n = AppLocalizations.of(context);

    // Check premium access for PDF export
    final hasFeature = ref.read(subscriptionProvider.notifier).hasFeature(
      PremiumFeature.pdfExport,
    );

    if (!hasFeature) {
      UpgradeDialog.show(
        context,
        feature: PremiumFeature.pdfExport,
      );
      return;
    }

    if (!_includeIncome && !_includeExpenses) {
      _showError(l10n?.selectAtLeastOneTransactionType ?? 'Please select at least one transaction type');
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Get data from providers
      final allIncome = ref.read(incomeSourcesProvider);
      final allExpenses = ref.read(expensesProvider);
      final customExpenseCategories = ref.read(customExpenseCategoriesProvider);

      final file = await ExportService.instance.generatePdfReport(
        startDate: _startDate,
        endDate: _endDate,
        includeIncome: _includeIncome,
        includeExpenses: _includeExpenses,
        allIncome: allIncome,
        allExpenses: allExpenses,
        customExpenseCategories: customExpenseCategories,
      );

      setState(() => _isGenerating = false);
      _showExportOptions(file);
    } catch (e) {
      setState(() => _isGenerating = false);
      _showError(l10n?.failedToGeneratePdf(e.toString()) ?? 'Failed to generate PDF: $e');
    }
  }

  Future<void> _generateCsv() async {
    final l10n = AppLocalizations.of(context);

    // Check if date range exceeds free tier limit (30 days)
    final isPremium = ref.read(isPremiumProvider);
    final daysDifference = _endDate.difference(_startDate).inDays;

    if (!isPremium && daysDifference > FreeTierLimits.csvExportDays) {
      UpgradeDialog.show(
        context,
        feature: PremiumFeature.fullExport,
        currentCount: daysDifference,
        limit: FreeTierLimits.csvExportDays,
      );
      return;
    }

    if (!_includeIncome && !_includeExpenses) {
      _showError(l10n?.selectAtLeastOneTransactionType ?? 'Please select at least one transaction type');
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Get data from providers
      final allIncome = ref.read(incomeSourcesProvider);
      final allExpenses = ref.read(expensesProvider);
      final customExpenseCategories = ref.read(customExpenseCategoriesProvider);
      final paymentMethods = ref.read(paymentMethodsProvider);
      final bankAccounts = ref.read(bankAccountsProvider);

      final file = await ExportService.instance.generateCsvExport(
        startDate: _startDate,
        endDate: _endDate,
        includeIncome: _includeIncome,
        includeExpenses: _includeExpenses,
        allIncome: allIncome,
        allExpenses: allExpenses,
        customExpenseCategories: customExpenseCategories,
        paymentMethods: paymentMethods,
        bankAccounts: bankAccounts,
      );

      setState(() => _isGenerating = false);
      _showExportOptions(file);
    } catch (e) {
      setState(() => _isGenerating = false);
      _showError(l10n?.failedToGenerateCsv(e.toString()) ?? 'Failed to generate CSV: $e');
    }
  }

  void _showExportOptions(File file) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            Icon(
              LucideIcons.checkCircle,
              size: 48,
              color: AppColors.success,
            ),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              l10n?.exportReady ?? 'Export Ready',
              style: AppTypography.h3.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              l10n?.reportGeneratedSuccessfully ?? 'Your report has been generated successfully',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                icon: LucideIcons.share2,
                label: l10n?.shareReport ?? 'Share Report',
                onTap: () {
                  Navigator.pop(context);
                  ExportService.instance.shareFile(file);
                },
                isDark: isDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: AppDimensions.spacing8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/premium_features.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/csv_import_service.dart';
import '../../../services/sync_service.dart';
import '../../providers/storage_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/animated_snackbar.dart';
import '../../widgets/common/upgrade_dialog.dart';

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  File? _selectedFile;
  CsvPreview? _preview;
  bool _isLoading = false;
  bool _isImporting = false;
  CsvImportResult? _importResult;

  // Column mapping for custom import
  final Map<String, int?> _columnMapping = {
    'date': null,
    'type': null,
    'name': null,
    'amount': null,
    'category': null,
    'merchant': null,
    'description': null,
  };

  // Import type
  String _importType = 'auto'; // 'auto', 'flowledger', 'bank', 'custom'

  // Bank import settings
  int? _bankDateColumn;
  int? _bankAmountColumn;
  int? _bankDescriptionColumn;
  int? _bankCreditColumn;
  int? _bankDebitColumn;
  bool _creditIsPositive = true;
  bool _hasSeparateCreditDebit = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = ref.watch(isPremiumProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n?.importTransactions ?? 'Import Transactions',
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium badge or info
                  if (!isPremium)
                    _buildPremiumBanner(isDark, l10n),

                  const SizedBox(height: 16),

                  // Template download section
                  _buildTemplateCard(isDark, l10n),

                  const SizedBox(height: 16),

                  // File selection
                  _buildFileSelectionCard(isDark, isPremium, l10n),

                  if (_preview != null) ...[
                    const SizedBox(height: 24),

                    // Import type selection
                    _buildImportTypeCard(isDark, l10n),

                    const SizedBox(height: 24),

                    // Column mapping (for custom import)
                    if (_importType == 'custom')
                      _buildColumnMappingCard(isDark, l10n),

                    // Bank import settings
                    if (_importType == 'bank')
                      _buildBankSettingsCard(isDark, l10n),

                    const SizedBox(height: 24),

                    // Preview table
                    _buildPreviewCard(isDark, l10n),

                    const SizedBox(height: 24),

                    // Import button
                    _buildImportButton(isDark, isPremium, l10n),
                  ],

                  // Import results
                  if (_importResult != null) ...[
                    const SizedBox(height: 24),
                    _buildResultsCard(isDark, l10n),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPremiumBanner(bool isDark, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.crown, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.premiumFeature ?? 'Premium Feature',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n?.csvImportPremium ?? 'CSV Import is available for premium users',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/paywall'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              l10n?.upgrade ?? 'Upgrade',
              style: AppTypography.labelMedium.copyWith(
                color: const Color(0xFFFFA500),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(bool isDark, AppLocalizations? l10n) {
    final templateFields = CsvImportService.instance.getTemplateFields();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.fileSpreadsheet,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.csvTemplate ?? 'CSV Template',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n?.downloadSampleTemplate ?? 'Download a sample template with example data',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _downloadTemplate(l10n),
              icon: const Icon(LucideIcons.download, size: 16),
              label: Text(l10n?.download ?? 'Download'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Required fields info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n?.required ?? 'REQUIRED',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.fieldsRequired ?? 'Fields marked with * are mandatory',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: templateFields.map((field) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: field.isRequired
                            ? AppColors.error.withValues(alpha: 0.1)
                            : (isDark ? AppColors.darkCard : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: field.isRequired
                              ? AppColors.error.withValues(alpha: 0.3)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                      ),
                      child: Text(
                        field.isRequired ? '${field.name}*' : field.name,
                        style: AppTypography.caption.copyWith(
                          color: field.isRequired
                              ? AppColors.error
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          fontWeight: field.isRequired ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Expandable field details
          ExpansionTile(
            title: Text(
              l10n?.viewFieldDetails ?? 'View Field Details',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            children: templateFields.map((field) => _buildFieldDetail(field, isDark, l10n)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldDetail(CsvTemplateField field, bool isDark, AppLocalizations? l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.name,
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (field.isRequired) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    l10n?.required ?? 'Required',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            field.description,
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${l10n?.format ?? 'Format'}: ',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ),
              Text(
                field.format,
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n?.examples ?? 'Examples'}: ${field.examples.join(", ")}',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadTemplate(AppLocalizations? l10n) async {
    try {
      final template = CsvImportService.instance.generateCsvTemplate();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/flowledger_import_template.csv');
      await file.writeAsString(template);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'FlowLedger CSV Import Template',
      );

      if (mounted) {
        AnimatedSnackbar.showSuccess(context, l10n?.templateReady ?? 'Template ready to share!');
      }
    } catch (e) {
      if (mounted) {
        AnimatedSnackbar.showError(context, l10n?.failedCreateTemplate ?? 'Failed to create template: $e');
      }
    }
  }

  Widget _buildFileSelectionCard(bool isDark, bool isPremium, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _selectedFile != null ? LucideIcons.fileCheck : LucideIcons.fileUp,
            size: 48,
            color: _selectedFile != null
                ? AppColors.success
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFile != null
                ? _selectedFile!.path.split('/').last
                : l10n?.selectCsvFile ?? 'Select a CSV file to import',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_preview != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n?.transactionsFound(_preview!.totalRows) ?? '${_preview!.totalRows} transactions found',
                style: AppTypography.caption.copyWith(
                  color: AppColors.success,
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isPremium ? () => _pickFile(l10n) : () => _showUpgradeDialog(),
              icon: const Icon(LucideIcons.upload, size: 18),
              label: Text(_selectedFile != null ? (l10n?.changeFile ?? 'Change File') : (l10n?.selectCsvFileBtn ?? 'Select CSV File')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportTypeCard(bool isDark, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.importType ?? 'Import Type',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildImportTypeOption(
            isDark: isDark,
            value: 'auto',
            title: l10n?.autoDetect ?? 'Auto Detect',
            subtitle: l10n?.autoDetectDesc ?? 'Automatically detect CSV format',
            icon: LucideIcons.sparkles,
          ),
          _buildImportTypeOption(
            isDark: isDark,
            value: 'flowledger',
            title: l10n?.flowLedgerExport ?? 'FlowLedger Export',
            subtitle: l10n?.flowLedgerExportDesc ?? 'Import from FlowLedger exported CSV',
            icon: LucideIcons.fileJson,
          ),
          _buildImportTypeOption(
            isDark: isDark,
            value: 'bank',
            title: l10n?.bankStatement ?? 'Bank Statement',
            subtitle: l10n?.bankStatementDesc ?? 'Import from bank CSV export',
            icon: LucideIcons.building2,
          ),
          _buildImportTypeOption(
            isDark: isDark,
            value: 'custom',
            title: l10n?.customMapping ?? 'Custom Mapping',
            subtitle: l10n?.customMappingDesc ?? 'Manually map columns',
            icon: LucideIcons.settings,
          ),
        ],
      ),
    );
  }

  Widget _buildImportTypeOption({
    required bool isDark,
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _importType == value;
    return GestureDetector(
      onTap: () => setState(() => _importType = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _importType,
              onChanged: (v) => setState(() => _importType = v!),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnMappingCard(bool isDark, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.columnMapping ?? 'Column Mapping',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.mapColumnsDesc ?? 'Map your CSV columns to transaction fields',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 16),
          _buildColumnDropdown(isDark, '${l10n?.date ?? 'Date'} *', 'date', l10n),
          _buildColumnDropdown(isDark, '${l10n?.amount ?? 'Amount'} *', 'amount', l10n),
          _buildColumnDropdown(isDark, l10n?.description ?? 'Name/Description', 'name', l10n),
          _buildColumnDropdown(isDark, '${l10n?.type ?? 'Type'} (${l10n?.income ?? 'Income'}/${l10n?.expense ?? 'Expense'})', 'type', l10n),
          _buildColumnDropdown(isDark, l10n?.category ?? 'Category', 'category', l10n),
          _buildColumnDropdown(isDark, l10n?.merchant ?? 'Merchant', 'merchant', l10n),
        ],
      ),
    );
  }

  Widget _buildColumnDropdown(bool isDark, String label, String field, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: DropdownButton<int?>(
                value: _columnMapping[field],
                hint: Text(
                  l10n?.selectColumn ?? 'Select column',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      l10n?.notMapped ?? 'Not mapped',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ),
                  ...List.generate(_preview!.headers.length, (i) {
                    return DropdownMenuItem(
                      value: i,
                      child: Text(
                        _preview!.headers[i],
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => _columnMapping[field] = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSettingsCard(bool isDark, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.bankStatementSettings ?? 'Bank Statement Settings',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildBankColumnDropdown(isDark, '${l10n?.dateColumn ?? 'Date Column'} *', (v) => _bankDateColumn = v, _bankDateColumn, l10n),
          _buildBankColumnDropdown(isDark, l10n?.descriptionColumn ?? 'Description Column', (v) => _bankDescriptionColumn = v, _bankDescriptionColumn, l10n),

          // Credit/Debit toggle
          SwitchListTile(
            title: Text(
              l10n?.separateCreditDebitColumns ?? 'Separate Credit/Debit Columns',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            value: _hasSeparateCreditDebit,
            onChanged: (v) => setState(() => _hasSeparateCreditDebit = v),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),

          if (_hasSeparateCreditDebit) ...[
            _buildBankColumnDropdown(isDark, l10n?.creditColumn ?? 'Credit Column', (v) => _bankCreditColumn = v, _bankCreditColumn, l10n),
            _buildBankColumnDropdown(isDark, l10n?.debitColumn ?? 'Debit Column', (v) => _bankDebitColumn = v, _bankDebitColumn, l10n),
          ] else ...[
            _buildBankColumnDropdown(isDark, '${l10n?.amountColumn ?? 'Amount Column'} *', (v) => _bankAmountColumn = v, _bankAmountColumn, l10n),
            SwitchListTile(
              title: Text(
                l10n?.positiveCredits ?? 'Positive amounts are credits (income)',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              value: _creditIsPositive,
              onChanged: (v) => setState(() => _creditIsPositive = v),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankColumnDropdown(bool isDark, String label, Function(int?) onChanged, int? value, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: DropdownButton<int?>(
                value: value,
                hint: Text(
                  l10n?.selectColumn ?? 'Select column',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  ),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      l10n?.notMapped ?? 'Not mapped',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ),
                  ...List.generate(_preview!.headers.length, (i) {
                    return DropdownMenuItem(
                      value: i,
                      child: Text(
                        _preview!.headers[i],
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => onChanged(v)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(bool isDark, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.preview ?? 'Preview',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 80,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 36,
              columnSpacing: 16,
              columns: _preview!.headers.map((h) {
                return DataColumn(
                  label: Text(
                    h,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              rows: _preview!.sampleRows.map((row) {
                return DataRow(
                  cells: row.map((cell) {
                    return DataCell(
                      Text(
                        cell.length > 20 ? '${cell.substring(0, 20)}...' : cell,
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
              ),
            ),
          ),
          if (_preview!.totalRows > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n?.andMoreRows(_preview!.totalRows - 5) ?? '... and ${_preview!.totalRows - 5} more rows',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImportButton(bool isDark, bool isPremium, AppLocalizations? l10n) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isPremium && !_isImporting ? () => _startImport(l10n) : null,
        icon: _isImporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(LucideIcons.download, size: 18),
        label: Text(_isImporting ? (l10n?.importing ?? 'Importing...') : (l10n?.importTransactionsBtn ?? 'Import Transactions')),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildResultsCard(bool isDark, AppLocalizations? l10n) {
    final result = _importResult!;
    final isSuccess = !result.hasErrors && result.successCount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isSuccess ? AppColors.success : AppColors.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                color: isSuccess ? AppColors.success : AppColors.warning,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isSuccess ? (l10n?.importSuccessful ?? 'Import Successful!') : (l10n?.importWithWarnings ?? 'Import Completed with Warnings'),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResultRow(isDark, l10n?.totalRows ?? 'Total Rows', result.totalRows.toString()),
          _buildResultRow(isDark, l10n?.expensesImported ?? 'Expenses Imported', result.expensesImported.toString()),
          _buildResultRow(isDark, l10n?.incomeImported ?? 'Income Imported', result.incomeImported.toString()),
          if (result.skippedRows > 0)
            _buildResultRow(isDark, l10n?.skipped ?? 'Skipped', result.skippedRows.toString(), isWarning: true),

          if (result.hasWarnings || result.hasErrors) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                l10n?.details ?? 'Details',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              children: [
                ...result.errors.map((e) => _buildMessageItem(e, isError: true)),
                ...result.warnings.take(10).map((w) => _buildMessageItem(w)),
                if (result.warnings.length > 10)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '... and ${result.warnings.length - 10} more warnings',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(bool isDark, String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: isWarning
                  ? AppColors.warning
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(String message, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? LucideIcons.xCircle : LucideIcons.alertCircle,
            size: 14,
            color: isError ? AppColors.error : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(
                color: isError ? AppColors.error : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    UpgradeDialog.show(
      context,
      feature: PremiumFeature.csvImport,
    );
  }

  Future<void> _pickFile(AppLocalizations? l10n) async {
    setState(() => _isLoading = true);

    try {
      final file = await CsvImportService.instance.pickCsvFile();
      if (file == null) {
        setState(() => _isLoading = false);
        return;
      }

      final preview = await CsvImportService.instance.previewCsv(file);
      if (preview == null) {
        if (mounted) {
          AnimatedSnackbar.showError(context, l10n?.couldNotReadCsv ?? 'Could not read CSV file');
        }
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _selectedFile = file;
        _preview = preview;
        _importResult = null;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AnimatedSnackbar.showError(context, l10n?.errorLoadingFile ?? 'Error loading file: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startImport(AppLocalizations? l10n) async {
    if (_selectedFile == null) return;

    setState(() => _isImporting = true);

    try {
      CsvImportResult result;

      switch (_importType) {
        case 'flowledger':
          result = await CsvImportService.instance.importFromFlowLedgerCsv(_selectedFile!);
          break;
        case 'bank':
          if (_bankDateColumn == null) {
            AnimatedSnackbar.showError(context, l10n?.selectDateColumn ?? 'Please select the date column');
            setState(() => _isImporting = false);
            return;
          }
          if (!_hasSeparateCreditDebit && _bankAmountColumn == null) {
            AnimatedSnackbar.showError(context, l10n?.selectAmountColumn ?? 'Please select the amount column');
            setState(() => _isImporting = false);
            return;
          }
          result = await CsvImportService.instance.importFromBankCsv(
            _selectedFile!,
            dateColumn: _bankDateColumn!,
            amountColumn: _bankAmountColumn ?? 0,
            descriptionColumn: _bankDescriptionColumn,
            creditIsPositive: _creditIsPositive,
            creditColumn: _hasSeparateCreditDebit ? _bankCreditColumn : null,
            debitColumn: _hasSeparateCreditDebit ? _bankDebitColumn : null,
          );
          break;
        case 'custom':
          if (_columnMapping['date'] == null || _columnMapping['amount'] == null) {
            AnimatedSnackbar.showError(context, l10n?.mapDateAmount ?? 'Please map Date and Amount columns');
            setState(() => _isImporting = false);
            return;
          }
          final mapping = Map<String, int>.from(
            _columnMapping.map((k, v) => MapEntry(k, v ?? -1))
              ..removeWhere((k, v) => v < 0),
          );
          result = await CsvImportService.instance.importFromCsv(_selectedFile!, mapping);
          break;
        default: // auto
          result = await CsvImportService.instance.importFromFlowLedgerCsv(_selectedFile!);
      }

      setState(() {
        _importResult = result;
        _isImporting = false;
      });

      if (result.successCount > 0) {
        // Invalidate providers so income/expense screens reload with new data
        ref.invalidate(incomeSourcesProvider);
        ref.invalidate(expensesProvider);

        // Trigger sync
        SyncService.instance.triggerAutoSync();

        if (mounted) {
          AnimatedSnackbar.showSuccess(
            context,
            l10n?.importedTransactions(result.successCount) ?? 'Imported ${result.successCount} transactions',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AnimatedSnackbar.showError(context, l10n?.importFailed ?? 'Import failed: $e');
      }
      setState(() => _isImporting = false);
    }
  }
}

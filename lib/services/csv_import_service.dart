import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../data/models/expense.dart';
import '../data/models/income.dart';
import '../data/storage/storage_service.dart';

/// Result of a CSV import operation
class CsvImportResult {
  final int totalRows;
  final int expensesImported;
  final int incomeImported;
  final int skippedRows;
  final List<String> errors;
  final List<String> warnings;

  const CsvImportResult({
    required this.totalRows,
    required this.expensesImported,
    required this.incomeImported,
    required this.skippedRows,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  int get successCount => expensesImported + incomeImported;
}

/// Service for importing transactions from CSV files
class CsvImportService {
  CsvImportService._();
  static final CsvImportService instance = CsvImportService._();

  final _uuid = const Uuid();

  // Common date formats to try when parsing dates
  final List<DateFormat> _dateFormats = [
    DateFormat('dd/MM/yyyy'),
    DateFormat('MM/dd/yyyy'),
    DateFormat('yyyy-MM-dd'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('yyyy/MM/dd'),
    DateFormat('d/M/yyyy'),
    DateFormat('M/d/yyyy'),
    DateFormat('dd.MM.yyyy'),
    DateFormat('yyyy.MM.dd'),
    DateFormat('dd MMM yyyy'),
    DateFormat('MMM dd, yyyy'),
    DateFormat('MMMM dd, yyyy'),
  ];

  /// Pick a CSV file using file picker
  Future<File?> pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'CSV'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          return File(path);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error picking CSV file: $e');
      return null;
    }
  }

  /// Preview the CSV file and return column headers and sample rows
  Future<CsvPreview?> previewCsv(File file) async {
    try {
      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content, eol: '\n');

      if (rows.isEmpty) {
        return null;
      }

      // First row is headers
      final headers = rows.first.map((e) => e.toString().trim()).toList();

      // Get up to 5 sample rows
      final sampleRows = <List<String>>[];
      for (int i = 1; i < rows.length && i <= 5; i++) {
        sampleRows.add(rows[i].map((e) => e.toString().trim()).toList());
      }

      return CsvPreview(
        headers: headers,
        sampleRows: sampleRows,
        totalRows: rows.length - 1, // Exclude header row
      );
    } catch (e) {
      debugPrint('Error previewing CSV: $e');
      return null;
    }
  }

  /// Import transactions from a CSV file
  ///
  /// [columnMapping] maps our fields to column indices in the CSV:
  /// - 'date': index of date column
  /// - 'type': index of type column (Income/Expense) - optional
  /// - 'name': index of name/description column
  /// - 'amount': index of amount column
  /// - 'category': index of category column - optional
  /// - 'merchant': index of merchant column - optional
  /// - 'description': index of description column - optional
  /// - 'notes': index of notes column - optional
  Future<CsvImportResult> importFromCsv(
    File file,
    Map<String, int> columnMapping, {
    String defaultType = 'expense', // 'expense' or 'income'
    bool skipHeader = true,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    int expensesImported = 0;
    int incomeImported = 0;
    int skippedRows = 0;

    try {
      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content, eol: '\n');

      if (rows.isEmpty) {
        return CsvImportResult(
          totalRows: 0,
          expensesImported: 0,
          incomeImported: 0,
          skippedRows: 0,
          errors: ['CSV file is empty'],
          warnings: [],
        );
      }

      final storage = StorageService.instance;
      final now = DateTime.now();

      // Process each row (skip header if needed)
      final startIndex = skipHeader ? 1 : 0;
      for (int i = startIndex; i < rows.length; i++) {
        final row = rows[i];
        final rowNum = i + 1;

        try {
          // Get values from mapped columns
          final dateStr = _getCellValue(row, columnMapping['date']);
          final amountStr = _getCellValue(row, columnMapping['amount']);
          final name = _getCellValue(row, columnMapping['name']) ?? 'Imported Transaction';
          final typeStr = _getCellValue(row, columnMapping['type'])?.toLowerCase() ?? defaultType;
          final categoryStr = _getCellValue(row, columnMapping['category']);
          final merchantStr = _getCellValue(row, columnMapping['merchant']);
          final descriptionStr = _getCellValue(row, columnMapping['description']);
          final notesStr = _getCellValue(row, columnMapping['notes']);

          // Validate required fields
          if (dateStr == null || dateStr.isEmpty) {
            warnings.add('Row $rowNum: Missing date, skipped');
            skippedRows++;
            continue;
          }

          if (amountStr == null || amountStr.isEmpty) {
            warnings.add('Row $rowNum: Missing amount, skipped');
            skippedRows++;
            continue;
          }

          // Parse date
          final date = _parseDate(dateStr);
          if (date == null) {
            warnings.add('Row $rowNum: Could not parse date "$dateStr", skipped');
            skippedRows++;
            continue;
          }

          // Reject future dates
          if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
            warnings.add('Row $rowNum: Date "$dateStr" is in the future, skipped');
            skippedRows++;
            continue;
          }

          // Parse amount
          final amount = _parseAmount(amountStr);
          if (amount == null || amount <= 0) {
            warnings.add('Row $rowNum: Invalid amount "$amountStr", skipped');
            skippedRows++;
            continue;
          }

          // Determine transaction type
          final isIncome = typeStr.contains('income') ||
              typeStr.contains('credit') ||
              typeStr.contains('deposit') ||
              typeStr.contains('received');

          // Warn if type column value is unrecognized (likely a typo)
          final isKnownType = typeStr.isEmpty ||
              isIncome ||
              typeStr.contains('expense') ||
              typeStr.contains('debit') ||
              typeStr.contains('payment');
          if (!isKnownType) {
            warnings.add('Row $rowNum: Unrecognized type "$typeStr" — treated as expense');
          }

          if (isIncome) {
            // Create income entry
            final categoryId = _matchIncomeCategoryId(categoryStr);
            final income = IncomeSource(
              id: _uuid.v4(),
              sourceName: name,
              amount: amount,
              categoryId: categoryId,
              date: date,
              notes: _combineNotes(descriptionStr, notesStr),
              isRecurring: false,
              createdAt: now,
              updatedAt: now,
            );

            await storage.saveIncomeSource(income);
            incomeImported++;
          } else {
            // Create expense entry
            final categoryId = _matchExpenseCategoryId(categoryStr);
            final expense = Expense(
              id: _uuid.v4(),
              name: name,
              amount: amount,
              categoryId: categoryId,
              date: date,
              paymentMethodId: 'cash', // Default to cash for imported transactions
              merchantName: merchantStr,
              description: _combineNotes(descriptionStr, notesStr),
              isRecurring: false,
              createdAt: now,
              updatedAt: now,
            );

            await storage.saveExpense(expense);
            expensesImported++;
          }
        } catch (e) {
          errors.add('Row $rowNum: Error processing - $e');
          skippedRows++;
        }
      }

      return CsvImportResult(
        totalRows: rows.length - (skipHeader ? 1 : 0),
        expensesImported: expensesImported,
        incomeImported: incomeImported,
        skippedRows: skippedRows,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      return CsvImportResult(
        totalRows: 0,
        expensesImported: 0,
        incomeImported: 0,
        skippedRows: 0,
        errors: ['Failed to read CSV file: $e'],
        warnings: [],
      );
    }
  }

  /// Import from a FlowLedger exported CSV (auto-detect columns)
  Future<CsvImportResult> importFromFlowLedgerCsv(File file) async {
    final preview = await previewCsv(file);
    if (preview == null) {
      return const CsvImportResult(
        totalRows: 0,
        expensesImported: 0,
        incomeImported: 0,
        skippedRows: 0,
        errors: ['Could not read CSV file'],
        warnings: [],
      );
    }

    // Auto-detect FlowLedger CSV columns
    // Strip asterisks (*) used for required-field markers in the template
    final mapping = <String, int>{};
    for (int i = 0; i < preview.headers.length; i++) {
      final header = preview.headers[i].toLowerCase().replaceAll('*', '').trim();
      if (header.contains('date')) {
        mapping['date'] = i;
      } else if (header.contains('type')) {
        mapping['type'] = i;
      } else if (header.contains('name') || header == 'source') {
        // Matches: "name", "name/description", "source"
        mapping['name'] = i;
      } else if (header.contains('amount')) {
        mapping['amount'] = i;
      } else if (header.contains('category')) {
        mapping['category'] = i;
      } else if (header.contains('merchant')) {
        mapping['merchant'] = i;
      } else if (header.contains('description') || header.contains('notes')) {
        mapping['description'] = i;
      }
    }

    // Check if we have required columns
    if (!mapping.containsKey('date') || !mapping.containsKey('amount')) {
      return const CsvImportResult(
        totalRows: 0,
        expensesImported: 0,
        incomeImported: 0,
        skippedRows: 0,
        errors: ['CSV file must have Date and Amount columns'],
        warnings: [],
      );
    }

    return importFromCsv(file, mapping);
  }

  /// Import from a common bank CSV format
  Future<CsvImportResult> importFromBankCsv(
    File file, {
    required int dateColumn,
    required int amountColumn,
    int? descriptionColumn,
    required bool creditIsPositive,
    int? creditColumn,
    int? debitColumn,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    int expensesImported = 0;
    int incomeImported = 0;
    int skippedRows = 0;

    try {
      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content, eol: '\n');

      if (rows.length <= 1) {
        return CsvImportResult(
          totalRows: 0,
          expensesImported: 0,
          incomeImported: 0,
          skippedRows: 0,
          errors: ['CSV file is empty or has no data rows'],
          warnings: [],
        );
      }

      final storage = StorageService.instance;
      final now = DateTime.now();

      // Skip header row
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final rowNum = i + 1;

        try {
          // Get date
          final dateStr = _getCellValue(row, dateColumn);
          if (dateStr == null || dateStr.isEmpty) {
            skippedRows++;
            continue;
          }

          final date = _parseDate(dateStr);
          if (date == null) {
            warnings.add('Row $rowNum: Could not parse date "$dateStr"');
            skippedRows++;
            continue;
          }

          // Reject future dates
          if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
            warnings.add('Row $rowNum: Date "$dateStr" is in the future, skipped');
            skippedRows++;
            continue;
          }

          // Get amount
          double? amount;
          bool isCredit = false;

          if (creditColumn != null && debitColumn != null) {
            // Separate credit/debit columns
            final creditStr = _getCellValue(row, creditColumn);
            final debitStr = _getCellValue(row, debitColumn);

            final credit = _parseAmount(creditStr);
            final debit = _parseAmount(debitStr);

            if (credit != null && credit > 0) {
              amount = credit;
              isCredit = true;
            } else if (debit != null && debit > 0) {
              amount = debit;
              isCredit = false;
            }
          } else {
            // Single amount column (positive/negative)
            final amountStr = _getCellValue(row, amountColumn);
            amount = _parseAmount(amountStr);

            if (amount != null) {
              if (creditIsPositive) {
                isCredit = amount > 0;
              } else {
                isCredit = amount < 0;
              }
              amount = amount.abs();
            }
          }

          if (amount == null || amount <= 0) {
            skippedRows++;
            continue;
          }

          // Get description
          final description = _getCellValue(row, descriptionColumn) ?? 'Bank Transaction';

          if (isCredit) {
            // Create income entry
            final income = IncomeSource(
              id: _uuid.v4(),
              sourceName: description,
              amount: amount,
              categoryId: 'other',
              date: date,
              notes: 'Imported from bank statement',
              isRecurring: false,
              createdAt: now,
              updatedAt: now,
            );

            await storage.saveIncomeSource(income);
            incomeImported++;
          } else {
            // Create expense entry
            final expense = Expense(
              id: _uuid.v4(),
              name: description,
              amount: amount,
              categoryId: 'other',
              date: date,
              paymentMethodId: 'bank_transfer', // Default for bank imports
              description: 'Imported from bank statement',
              isRecurring: false,
              createdAt: now,
              updatedAt: now,
            );

            await storage.saveExpense(expense);
            expensesImported++;
          }
        } catch (e) {
          errors.add('Row $rowNum: Error processing - $e');
          skippedRows++;
        }
      }

      return CsvImportResult(
        totalRows: rows.length - 1,
        expensesImported: expensesImported,
        incomeImported: incomeImported,
        skippedRows: skippedRows,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      return CsvImportResult(
        totalRows: 0,
        expensesImported: 0,
        incomeImported: 0,
        skippedRows: 0,
        errors: ['Failed to read CSV file: $e'],
        warnings: [],
      );
    }
  }

  // Helper methods

  String? _getCellValue(List<dynamic> row, int? index) {
    if (index == null || index < 0 || index >= row.length) {
      return null;
    }
    final value = row[index]?.toString().trim();
    return (value?.isEmpty ?? true) ? null : value;
  }

  DateTime? _parseDate(String dateStr) {
    // Clean up the date string
    dateStr = dateStr.trim().replaceAll('"', '');

    for (final format in _dateFormats) {
      try {
        return format.parse(dateStr);
      } catch (_) {
        // Try next format
      }
    }

    // Try parsing as ISO 8601
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  double? _parseAmount(String? amountStr) {
    if (amountStr == null || amountStr.isEmpty) {
      return null;
    }

    // Clean up the amount string
    amountStr = amountStr.trim()
        .replaceAll('"', '')
        .replaceAll(',', '') // Remove thousands separator
        .replaceAll(' ', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .replaceAll('\$', '')
        .replaceAll('USD', '')
        .replaceAll('INR', '');

    try {
      return double.parse(amountStr);
    } catch (_) {
      return null;
    }
  }

  String _matchExpenseCategoryId(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty) {
      return 'other';
    }

    final lowerCategory = categoryName.toLowerCase().trim();

    // Match against known expense categories
    for (final category in ExpenseCategories.all) {
      if (category.name.toLowerCase() == lowerCategory) {
        return category.id;
      }
    }

    // Try partial matches
    if (lowerCategory.contains('food') || lowerCategory.contains('restaurant') || lowerCategory.contains('dining')) {
      return 'food';
    }
    if (lowerCategory.contains('transport') || lowerCategory.contains('uber') || lowerCategory.contains('ola') || lowerCategory.contains('fuel')) {
      return 'transport';
    }
    if (lowerCategory.contains('shopping') || lowerCategory.contains('retail')) {
      return 'shopping';
    }
    if (lowerCategory.contains('entertainment') || lowerCategory.contains('movie') || lowerCategory.contains('netflix')) {
      return 'entertainment';
    }
    if (lowerCategory.contains('health') || lowerCategory.contains('medical') || lowerCategory.contains('doctor')) {
      return 'health';
    }
    if (lowerCategory.contains('utility') || lowerCategory.contains('bill') || lowerCategory.contains('electric') || lowerCategory.contains('water')) {
      return 'utilities';
    }
    if (lowerCategory.contains('groceries') || lowerCategory.contains('supermarket')) {
      return 'groceries';
    }
    if (lowerCategory.contains('education') || lowerCategory.contains('course') || lowerCategory.contains('school')) {
      return 'education';
    }
    if (lowerCategory.contains('travel') || lowerCategory.contains('flight') || lowerCategory.contains('hotel')) {
      return 'travel';
    }
    if (lowerCategory.contains('rent') || lowerCategory.contains('house') || lowerCategory.contains('home')) {
      return 'rent';
    }

    return 'other';
  }

  String _matchIncomeCategoryId(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty) {
      return 'other';
    }

    final lowerCategory = categoryName.toLowerCase().trim();

    // Match against known income categories
    for (final category in IncomeCategories.all) {
      if (category.name.toLowerCase() == lowerCategory) {
        return category.id;
      }
    }

    // Try partial matches
    if (lowerCategory.contains('salary') || lowerCategory.contains('wage') || lowerCategory.contains('pay')) {
      return 'salary';
    }
    if (lowerCategory.contains('freelance') || lowerCategory.contains('contract') || lowerCategory.contains('gig')) {
      return 'freelance';
    }
    if (lowerCategory.contains('business') || lowerCategory.contains('revenue')) {
      return 'business';
    }
    if (lowerCategory.contains('invest') || lowerCategory.contains('dividend') || lowerCategory.contains('interest')) {
      return 'investment';
    }
    if (lowerCategory.contains('rent') || lowerCategory.contains('rental')) {
      return 'rental';
    }
    if (lowerCategory.contains('gift') || lowerCategory.contains('received')) {
      return 'gift';
    }
    if (lowerCategory.contains('refund') || lowerCategory.contains('return')) {
      return 'refund';
    }

    return 'other';
  }

  String? _combineNotes(String? description, String? notes) {
    if (description == null && notes == null) return null;
    if (description == null) return notes;
    if (notes == null) return description;
    return '$description\n$notes';
  }

  /// Generate a CSV template string for users to download
  /// This template shows the expected format with example data
  String generateCsvTemplate() {
    const csvTemplate = '''Date,Type,Name,Amount,Category,Merchant,Payment Method,Bank Account,Notes
2024-01-15,expense,Groceries from BigBasket,1500,food,BigBasket,UPI,HDFC Savings,Weekly groceries
2024-01-14,expense,Uber ride to office,350,transport,Uber,Credit Card,ICICI Credit,Morning commute
2024-01-13,expense,Netflix subscription,199,entertainment,Netflix,UPI,HDFC Savings,Monthly subscription
2024-01-12,expense,Electricity bill,2500,utilities,,Bank Transfer,HDFC Savings,January bill
2024-01-10,income,Monthly Salary,85000,salary,TechCorp,Bank Transfer,HDFC Savings,January salary
2024-01-08,income,Freelance project,15000,freelance,Client XYZ,UPI,ICICI Savings,Website design
2024-01-05,expense,Amazon shopping,3200,shopping,Amazon,Credit Card,ICICI Credit,Household items
2024-01-03,income,Investment returns,5000,investment,,Bank Transfer,HDFC Savings,Mutual fund dividend''';

    return csvTemplate;
  }

  /// Get the template field information for display
  List<CsvTemplateField> getTemplateFields() {
    return [
      CsvTemplateField(
        name: 'Date',
        isRequired: true,
        description: 'Transaction date',
        format: 'YYYY-MM-DD or DD/MM/YYYY',
        examples: ['2024-01-15', '15/01/2024'],
      ),
      CsvTemplateField(
        name: 'Type',
        isRequired: true,
        description: 'Transaction type',
        format: 'expense or income',
        examples: ['expense', 'income'],
      ),
      CsvTemplateField(
        name: 'Name',
        isRequired: true,
        description: 'Transaction name or description',
        format: 'Text',
        examples: ['Groceries', 'Monthly Salary'],
      ),
      CsvTemplateField(
        name: 'Amount',
        isRequired: true,
        description: 'Transaction amount (positive number)',
        format: 'Number',
        examples: ['1500', '85000'],
      ),
      CsvTemplateField(
        name: 'Category',
        isRequired: false,
        description: 'Transaction category',
        format: 'Category name',
        examples: ['food', 'transport', 'salary', 'freelance'],
      ),
      CsvTemplateField(
        name: 'Merchant',
        isRequired: false,
        description: 'Merchant or payee name',
        format: 'Text',
        examples: ['Amazon', 'Uber', 'BigBasket'],
      ),
      CsvTemplateField(
        name: 'Payment Method',
        isRequired: false,
        description: 'How payment was made',
        format: 'Text',
        examples: ['UPI', 'Credit Card', 'Cash', 'Bank Transfer'],
      ),
      CsvTemplateField(
        name: 'Bank Account',
        isRequired: false,
        description: 'Bank account used',
        format: 'Text',
        examples: ['HDFC Savings', 'ICICI Credit'],
      ),
      CsvTemplateField(
        name: 'Notes',
        isRequired: false,
        description: 'Additional notes',
        format: 'Text',
        examples: ['Monthly subscription', 'Office expense'],
      ),
    ];
  }
}

/// Represents a field in the CSV template
class CsvTemplateField {
  final String name;
  final bool isRequired;
  final String description;
  final String format;
  final List<String> examples;

  const CsvTemplateField({
    required this.name,
    required this.isRequired,
    required this.description,
    required this.format,
    required this.examples,
  });
}

/// Preview of a CSV file before import
class CsvPreview {
  final List<String> headers;
  final List<List<String>> sampleRows;
  final int totalRows;

  const CsvPreview({
    required this.headers,
    required this.sampleRows,
    required this.totalRows,
  });
}

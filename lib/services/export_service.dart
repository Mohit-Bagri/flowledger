import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../data/models/expense.dart';
import '../data/models/income.dart';
import '../data/models/payment_method.dart';
import '../data/models/bank_account.dart';
import '../data/models/currency.dart';
import '../core/utils/currency_formatter.dart';

/// Export service for generating PDF and CSV reports
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Format amount for PDF using user's selected currency (for summaries)
  String _formatAmountForPdf(double amount) {
    return CurrencyFormatter.formatForPdf(amount);
  }

  /// Format amount for PDF using the transaction's stored currency code
  String _formatAmountWithCurrency(double amount, String currencyCode) {
    final currency = Currencies.getByCode(currencyCode);
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    // Use Indian numbering for INR, standard for others
    if (currencyCode == 'INR') {
      final formatted = _formatIndianNumber(absAmount.round());
      return isNegative ? '-Rs. $formatted' : 'Rs. $formatted';
    }

    // For other currencies, use standard formatting
    final formatted = _formatStandardNumber(absAmount.round());
    return isNegative ? '-${currency.symbol}$formatted' : '${currency.symbol}$formatted';
  }

  /// Format number with Indian comma system (XX,XX,XXX)
  String _formatIndianNumber(int number) {
    if (number < 1000) return number.toString();

    final str = number.toString();
    final length = str.length;
    final lastThree = str.substring(length - 3);
    final remaining = str.substring(0, length - 3);

    if (remaining.isEmpty) return lastThree;

    final buffer = StringBuffer();
    final remainingLength = remaining.length;

    for (int i = 0; i < remainingLength; i++) {
      buffer.write(remaining[i]);
      final posFromEnd = remainingLength - i - 1;
      if (posFromEnd > 0 && posFromEnd % 2 == 0) {
        buffer.write(',');
      }
    }

    return '$buffer,$lastThree';
  }

  /// Format number with standard comma placement (every 3 digits)
  String _formatStandardNumber(int number) {
    if (number < 1000) return number.toString();

    final str = number.toString();
    final buffer = StringBuffer();
    final length = str.length;

    for (int i = 0; i < length; i++) {
      buffer.write(str[i]);
      final posFromEnd = length - i - 1;
      if (posFromEnd > 0 && posFromEnd % 3 == 0) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }

  /// Generate PDF report with data passed from screen
  Future<File> generatePdfReport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? categoryIds,
    bool includeIncome = true,
    bool includeExpenses = true,
    required List<IncomeSource> allIncome,
    required List<Expense> allExpenses,
    required List<ExpenseCategory> customExpenseCategories,
  }) async {
    final categories = [...ExpenseCategories.all, ...customExpenseCategories];

    // Filter by date (inclusive of both start and end dates)
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final incomeInRange = allIncome.where((i) =>
        !i.createdAt.isBefore(startOfDay) && !i.createdAt.isAfter(endOfDay)).toList();

    final expensesInRange = allExpenses.where((e) =>
        !e.date.isBefore(startOfDay) && !e.date.isAfter(endOfDay)).toList();

    // Filter by category if specified
    final filteredExpenses = categoryIds != null && categoryIds.isNotEmpty
        ? expensesInRange.where((e) => categoryIds.contains(e.categoryId)).toList()
        : expensesInRange;

    // Calculate totals
    final totalIncome = incomeInRange.fold(0.0, (sum, i) => sum + i.amount);
    final totalExpenses = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final netSavings = totalIncome - totalExpenses;

    // Group expenses by category
    final expensesByCategory = <String, double>{};
    for (final expense in filteredExpenses) {
      expensesByCategory[expense.categoryId] =
          (expensesByCategory[expense.categoryId] ?? 0) + expense.amount;
    }

    // Sort by amount descending
    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Create PDF
    final pdf = pw.Document();

    // Colors
    final primaryColor = PdfColor.fromHex('#5B7CFA');
    final successColor = PdfColor.fromHex('#10B981');
    final errorColor = PdfColor.fromHex('#EF4444');
    final grayColor = PdfColor.fromHex('#6B7280');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPdfHeader(startDate, endDate, primaryColor),
        footer: (context) => _buildPdfFooter(context, grayColor),
        build: (context) => [
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FINANCIAL SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: grayColor,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total Income', totalIncome, successColor),
                    _buildSummaryItem('Total Expenses', totalExpenses, errorColor),
                    _buildSummaryItem(
                      'Net Savings',
                      netSavings,
                      netSavings >= 0 ? successColor : errorColor,
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Category Breakdown
          if (sortedCategories.isNotEmpty && includeExpenses) ...[
            pw.Text(
              'EXPENSE BREAKDOWN BY CATEGORY',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: grayColor,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  // Header
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(8),
                        topRight: pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text('%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                  ),
                  // Rows
                  ...sortedCategories.map((entry) {
                    final category = categories.firstWhere(
                      (c) => c.id == entry.key,
                      orElse: () => ExpenseCategory(id: entry.key, name: 'Other', icon: Icons.help, color: Colors.grey),
                    );
                    final percentage = totalExpenses > 0
                        ? (entry.value / totalExpenses * 100).toStringAsFixed(1)
                        : '0.0';
                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(category.name),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(_formatAmountForPdf(entry.value), textAlign: pw.TextAlign.right),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text('$percentage%', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: grayColor)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
          ],

          // Transactions List
          if (includeExpenses && filteredExpenses.isNotEmpty) ...[
            pw.Text(
              'EXPENSE TRANSACTIONS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: grayColor,
              ),
            ),
            pw.SizedBox(height: 12),
            _buildTransactionsTable(filteredExpenses, categories, grayColor),
          ],

          if (includeIncome && incomeInRange.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text(
              'INCOME TRANSACTIONS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: grayColor,
              ),
            ),
            pw.SizedBox(height: 12),
            _buildIncomeTable(incomeInRange, grayColor),
          ],

          // Show message if no data
          if (filteredExpenses.isEmpty && incomeInRange.isEmpty) ...[
            pw.SizedBox(height: 40),
            pw.Center(
              child: pw.Text(
                'No transactions found for the selected date range.',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: grayColor,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    // Save file
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'FlowLedger_Report_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildPdfHeader(DateTime startDate, DateTime endDate, PdfColor primaryColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FlowLedger',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.Text(
                'Financial Report',
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Generated: ${_dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context, PdfColor grayColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by FlowLedger App',
            style: pw.TextStyle(fontSize: 10, color: grayColor),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 10, color: grayColor),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _formatAmountForPdf(amount),
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTransactionsTable(List<Expense> expenses, List<ExpenseCategory> categories, PdfColor grayColor) {
    // Sort by date descending
    final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Date', isHeader: true),
            _tableCell('Name', isHeader: true),
            _tableCell('Category', isHeader: true),
            _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Data rows
        ...sorted.take(50).map((expense) {
          final category = categories.firstWhere(
            (c) => c.id == expense.categoryId,
            orElse: () => ExpenseCategory(id: '', name: 'Other', icon: Icons.help, color: Colors.grey),
          );
          return pw.TableRow(
            children: [
              _tableCell(_dateFormat.format(expense.date)),
              _tableCell(expense.name),
              _tableCell(category.name),
              _tableCell(_formatAmountWithCurrency(expense.amount, expense.currencyCode), align: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildIncomeTable(List<IncomeSource> income, PdfColor grayColor) {
    final sorted = [...income]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Date', isHeader: true),
            _tableCell('Source', isHeader: true),
            _tableCell('Category', isHeader: true),
            _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        ...sorted.take(50).map((inc) {
          return pw.TableRow(
            children: [
              _tableCell(_dateFormat.format(inc.createdAt)),
              _tableCell(inc.sourceName),
              _tableCell(inc.category.name),
              _tableCell(_formatAmountWithCurrency(inc.amount, inc.currencyCode), align: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _tableCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  /// Generate CSV export with data passed from screen
  Future<File> generateCsvExport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? categoryIds,
    bool includeIncome = true,
    bool includeExpenses = true,
    required List<IncomeSource> allIncome,
    required List<Expense> allExpenses,
    required List<ExpenseCategory> customExpenseCategories,
    required List<PaymentMethod> paymentMethods,
    required List<BankAccount> bankAccounts,
  }) async {
    final categories = [...ExpenseCategories.all, ...customExpenseCategories];
    final buffer = StringBuffer();

    // CSV Header - Detailed columns with Currency
    buffer.writeln('Date,Type,Name,Amount,Currency,Category,Merchant,Description,Receipt Attached,Payment Method,Payment Type,Card Last 4,UPI ID,Bank Name,Account Name,Account Type,Account Number,IFSC Code,Is Recurring,Recurring Frequency');

    // Filter dates (inclusive)
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // Helper to get payment method details
    PaymentMethod? getPaymentMethod(String? id) {
      if (id == null || id.isEmpty) return null;
      return paymentMethods.where((p) => p.id == id).firstOrNull;
    }

    // Helper to get bank account details
    BankAccount? getBankAccount(String? id) {
      if (id == null || id.isEmpty) return null;
      return bankAccounts.where((b) => b.id == id).firstOrNull;
    }

    // Get and filter income data
    if (includeIncome) {
      final incomeInRange = allIncome.where((i) =>
          !i.date.isBefore(startOfDay) && !i.date.isAfter(endOfDay)).toList();

      for (final inc in incomeInRange) {
        final bankAccount = getBankAccount(inc.bankAccountId);
        final paymentMethod = getPaymentMethod(inc.paymentMethodId);
        final currency = Currencies.getByCode(inc.currencyCode);
        buffer.writeln(_escapeCsvRow([
          _dateFormat.format(inc.date),
          'Income',
          inc.sourceName,
          '${currency.symbol}${inc.amount.toStringAsFixed(2)}', // Amount with currency symbol
          inc.currencyCode, // Currency code
          inc.category.name,
          '', // Merchant (N/A for income)
          inc.notes ?? '', // Description
          'No', // Receipt Attached (N/A for income)
          paymentMethod?.name ?? '', // Payment Method
          paymentMethod?.type.label ?? '', // Payment Type
          paymentMethod?.lastFourDigits ?? '', // Card Last 4
          paymentMethod?.upiId ?? '', // UPI ID
          bankAccount?.bankName ?? '', // Bank Name
          bankAccount?.accountName ?? '', // Account Name
          bankAccount?.accountTypeLabel ?? '', // Account Type
          bankAccount?.displayAccountNumber ?? '', // Account Number
          bankAccount?.ifscCode ?? '', // IFSC Code
          inc.isRecurring ? 'Yes' : 'No', // Is Recurring
          '', // Recurring Frequency (now handled by recurring_transactions table)
        ]));
      }
    }

    // Get and filter expense data
    if (includeExpenses) {
      var expensesInRange = allExpenses.where((e) =>
          !e.date.isBefore(startOfDay) && !e.date.isAfter(endOfDay)).toList();

      if (categoryIds != null && categoryIds.isNotEmpty) {
        expensesInRange = expensesInRange.where((e) => categoryIds.contains(e.categoryId)).toList();
      }

      for (final exp in expensesInRange) {
        final category = categories.firstWhere(
          (c) => c.id == exp.categoryId,
          orElse: () => ExpenseCategory(id: '', name: 'Other', icon: Icons.help, color: Colors.grey),
        );
        final paymentMethod = getPaymentMethod(exp.paymentMethodId);
        final bankAccount = getBankAccount(exp.bankAccountId);
        final currency = Currencies.getByCode(exp.currencyCode);

        buffer.writeln(_escapeCsvRow([
          _dateFormat.format(exp.date),
          'Expense',
          exp.name,
          '${currency.symbol}${exp.amount.toStringAsFixed(2)}', // Amount with currency symbol
          exp.currencyCode, // Currency code
          category.name,
          exp.merchantName ?? '', // Merchant
          exp.description ?? '', // Description
          exp.hasReceipt ? 'Yes' : 'No', // Receipt Attached
          paymentMethod?.name ?? '', // Payment Method Name
          paymentMethod?.type.label ?? '', // Payment Type (Cash, UPI, Credit Card, etc.)
          paymentMethod?.lastFourDigits ?? '', // Card Last 4
          paymentMethod?.upiId ?? '', // UPI ID
          bankAccount?.bankName ?? '', // Bank Name
          bankAccount?.accountName ?? '', // Account Name
          bankAccount?.accountTypeLabel ?? '', // Account Type
          bankAccount?.displayAccountNumber ?? '', // Account Number
          bankAccount?.ifscCode ?? '', // IFSC Code
          exp.isRecurring ? 'Yes' : 'No', // Is Recurring
          exp.isRecurring ? (exp.recurringFrequency?.label ?? '') : '', // Recurring Frequency
        ]));
      }
    }

    // Save file with UTF-8 BOM for Excel compatibility
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'FlowLedger_Export_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.csv';
    final file = File('${dir.path}/$fileName');

    // Write with UTF-8 BOM (Byte Order Mark) for Excel compatibility
    final csvContent = buffer.toString();
    await file.writeAsString(csvContent, encoding: utf8);

    return file;
  }

  String _escapeCsvRow(List<String> values) {
    return values.map((v) {
      // Always quote fields to handle special characters properly
      final escaped = v.replaceAll('"', '""');
      return '"$escaped"';
    }).join(',');
  }

  /// Share file
  Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'FlowLedger Report',
    );
  }
}

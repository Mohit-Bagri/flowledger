import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import 'expense.dart'; // For RecurringFrequency

/// Income Category Model (supports both system and custom categories)
class IncomeCategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isSystem;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;

  const IncomeCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isSystem = true,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
  });

  IncomeCategoryModel copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    bool? isSystem,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return IncomeCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCode': icon.codePoint,
      'colorValue': color.toARGB32(),
      'isSystem': isSystem,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory IncomeCategoryModel.fromJson(Map<String, dynamic> json) {
    return IncomeCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(
        json['iconCode'] as int,
        fontFamily: 'lucide',
        fontPackage: 'lucide_icons',
      ),
      color: Color(json['colorValue'] as int),
      isSystem: json['isSystem'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 100,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

/// Default System Income Categories
class IncomeCategories {
  IncomeCategories._();

  static const IncomeCategoryModel salary = IncomeCategoryModel(
    id: 'salary',
    name: 'Salary',
    icon: LucideIcons.briefcase,
    color: AppColors.incomeSalary,
    sortOrder: 1,
  );

  static const IncomeCategoryModel freelance = IncomeCategoryModel(
    id: 'freelance',
    name: 'Freelance',
    icon: LucideIcons.laptop,
    color: AppColors.incomeFreelance,
    sortOrder: 2,
  );

  static const IncomeCategoryModel business = IncomeCategoryModel(
    id: 'business',
    name: 'Business',
    icon: LucideIcons.building2,
    color: AppColors.incomeBusiness,
    sortOrder: 3,
  );

  static const IncomeCategoryModel passive = IncomeCategoryModel(
    id: 'passive',
    name: 'Passive',
    icon: LucideIcons.trendingUp,
    color: AppColors.incomePassive,
    sortOrder: 4,
  );

  static const IncomeCategoryModel rental = IncomeCategoryModel(
    id: 'rental',
    name: 'Rental',
    icon: LucideIcons.home,
    color: AppColors.incomeRental,
    sortOrder: 5,
  );

  static const IncomeCategoryModel investment = IncomeCategoryModel(
    id: 'investment',
    name: 'Investment',
    icon: LucideIcons.lineChart,
    color: AppColors.incomeInvestment,
    sortOrder: 6,
  );

  static const IncomeCategoryModel gift = IncomeCategoryModel(
    id: 'gift',
    name: 'Gift',
    icon: LucideIcons.gift,
    color: AppColors.incomeGift,
    sortOrder: 7,
  );

  static const IncomeCategoryModel refund = IncomeCategoryModel(
    id: 'refund',
    name: 'Refund',
    icon: LucideIcons.refreshCw,
    color: AppColors.incomeOther,
    sortOrder: 8,
  );

  static const IncomeCategoryModel other = IncomeCategoryModel(
    id: 'other',
    name: 'Other',
    icon: LucideIcons.moreHorizontal,
    color: AppColors.incomeOther,
    sortOrder: 9,
  );

  static const List<IncomeCategoryModel> all = [
    salary,
    freelance,
    business,
    passive,
    rental,
    investment,
    gift,
    refund,
    other,
  ];

  static IncomeCategoryModel getById(String id) {
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => other,
    );
  }

  /// Get category by ID, checking custom categories list too
  static IncomeCategoryModel getByIdWithCustom(String id, List<IncomeCategoryModel> customCategories) {
    // First check system categories
    for (final cat in all) {
      if (cat.id == id) return cat;
    }
    // Then check custom categories
    for (final cat in customCategories) {
      if (cat.id == id) return cat;
    }
    // Default to other
    return other;
  }
}

/// Legacy enum for backward compatibility (will be deprecated)
@Deprecated('Use IncomeCategoryModel instead')
enum IncomeCategory {
  salary('Salary', LucideIcons.briefcase, AppColors.incomeSalary),
  freelance('Freelance', LucideIcons.laptop, AppColors.incomeFreelance),
  business('Business', LucideIcons.building2, AppColors.incomeBusiness),
  passive('Passive', LucideIcons.trendingUp, AppColors.incomePassive),
  rental('Rental', LucideIcons.home, AppColors.incomeRental),
  investment('Investment', LucideIcons.lineChart, AppColors.incomeInvestment),
  gift('Gift', LucideIcons.gift, AppColors.incomeGift),
  refund('Refund', LucideIcons.refreshCw, AppColors.incomeOther),
  other('Other', LucideIcons.moreHorizontal, AppColors.incomeOther);

  final String label;
  final IconData icon;
  final Color color;
  const IncomeCategory(this.label, this.icon, this.color);

  /// Convert to category ID for new system
  String get categoryId => name;
}

/// Income Frequency
enum IncomeFrequency {
  oneTime('One-time'),
  daily('Daily'),
  weekly('Weekly'),
  biWeekly('Bi-weekly'),
  monthly('Monthly'),
  quarterly('Quarterly'),
  annually('Annually'),
  irregular('Irregular');

  final String label;
  const IncomeFrequency(this.label);
}

/// Income Stability
enum IncomeStability {
  stable('Stable', 'Amount is fixed/guaranteed'),
  variable('Variable', 'Amount changes each time'),
  unpredictable('Unpredictable', 'No pattern');

  final String label;
  final String description;
  const IncomeStability(this.label, this.description);
}

/// Income Source Model (income entry - works like Expense model)
/// Stores actual income transactions with optional link to recurring_transactions
/// Has full parity with Expense model for comprehensive tracking
class IncomeSource {
  final String id;
  final String sourceName; // Display name for the income (like Expense.name)
  final double amount;
  final String currencyCode; // Currency code (e.g., 'INR', 'USD')
  final String categoryId;
  final DateTime date; // When income was received
  final String? paymentMethodId; // How income is received (Cheque, Cash, UPI, etc.)
  final String? bankAccountId; // Bank account where income goes
  final String? description; // Additional description (like Expense.description)
  final String? payerName; // Who paid you (like Expense.merchantName)
  final String? notes; // Extra notes
  // Recurring transaction fields
  final bool isRecurring; // Whether this came from a recurring transaction
  final String? recurringTransactionId; // Links to recurring_transactions table
  final RecurringFrequency? recurringFrequency; // Frequency if recurring (like Expense)
  final int? recurringDayOfMonth; // Day of month for recurring (like Expense)
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const IncomeSource({
    required this.id,
    required this.sourceName,
    required this.amount,
    this.currencyCode = 'INR',
    required this.categoryId,
    required this.date,
    this.paymentMethodId,
    this.bankAccountId,
    this.description,
    this.payerName,
    this.notes,
    this.isRecurring = false,
    this.recurringTransactionId,
    this.recurringFrequency,
    this.recurringDayOfMonth,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get category (system only - use getByIdWithCustom for custom support)
  IncomeCategoryModel get category => IncomeCategories.getById(categoryId);
  IconData get icon => category.icon;
  Color get color => category.color;

  IncomeSource copyWith({
    String? id,
    String? sourceName,
    double? amount,
    String? currencyCode,
    String? categoryId,
    DateTime? date,
    String? paymentMethodId,
    String? bankAccountId,
    String? description,
    String? payerName,
    String? notes,
    bool? isRecurring,
    String? recurringTransactionId,
    RecurringFrequency? recurringFrequency,
    int? recurringDayOfMonth,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomeSource(
      id: id ?? this.id,
      sourceName: sourceName ?? this.sourceName,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      description: description ?? this.description,
      payerName: payerName ?? this.payerName,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringTransactionId: recurringTransactionId ?? this.recurringTransactionId,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      recurringDayOfMonth: recurringDayOfMonth ?? this.recurringDayOfMonth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceName': sourceName,
      'amount': amount,
      'currencyCode': currencyCode,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'paymentMethodId': paymentMethodId,
      'bankAccountId': bankAccountId,
      'description': description,
      'payerName': payerName,
      'notes': notes,
      'isRecurring': isRecurring,
      'recurringTransactionId': recurringTransactionId,
      'recurringFrequency': recurringFrequency?.index,
      'recurringDayOfMonth': recurringDayOfMonth,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory IncomeSource.fromJson(Map<String, dynamic> json) {
    // Support both old format (category index) and new format (categoryId)
    String categoryId;
    if (json.containsKey('categoryId')) {
      categoryId = json['categoryId'] as String;
    } else if (json.containsKey('category')) {
      // Legacy: convert from enum index
      final index = json['category'] as int;
      categoryId = IncomeCategory.values[index].categoryId;
    } else {
      categoryId = 'other';
    }

    // Handle date field with fallback to createdAt for old data
    DateTime date;
    if (json.containsKey('date') && json['date'] != null) {
      date = DateTime.parse(json['date'] as String);
    } else {
      // Legacy data: use createdAt as the income date
      date = DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String());
    }

    // Determine if recurring based on new field or old frequency field
    bool isRecurring = json['isRecurring'] as bool? ?? json['is_recurring'] as bool? ?? false;
    RecurringFrequency? recurringFrequency;

    // Handle recurring frequency from new field or legacy frequency field
    if (json['recurringFrequency'] != null) {
      recurringFrequency = RecurringFrequency.values[json['recurringFrequency'] as int];
    } else if (json['recurring_frequency'] != null) {
      recurringFrequency = RecurringFrequency.values[json['recurring_frequency'] as int];
    } else if (json.containsKey('frequency')) {
      // Legacy: convert old frequency to recurring frequency
      final frequencyIndex = json['frequency'] as int?;
      if (frequencyIndex != null && frequencyIndex != 0) {
        isRecurring = true;
        // Map old IncomeFrequency to RecurringFrequency
        // old: oneTime(0), daily(1), weekly(2), biWeekly(3), monthly(4), quarterly(5), annually(6), irregular(7)
        switch (frequencyIndex) {
          case 1: recurringFrequency = RecurringFrequency.daily; break;
          case 2: recurringFrequency = RecurringFrequency.weekly; break;
          case 3: recurringFrequency = RecurringFrequency.weekly; break; // bi-weekly -> weekly
          case 4: recurringFrequency = RecurringFrequency.monthly; break;
          case 5: recurringFrequency = RecurringFrequency.quarterly; break;
          case 6: recurringFrequency = RecurringFrequency.yearly; break;
          default: recurringFrequency = RecurringFrequency.monthly; break;
        }
      }
    }

    final now = DateTime.now();
    return IncomeSource(
      id: json['id'] as String,
      sourceName: json['sourceName'] as String? ?? json['source_name'] as String? ?? 'Income',
      amount: (json['amount'] as num).toDouble(),
      // Support both camelCase and snake_case for currency code
      currencyCode: json['currencyCode'] as String? ??
                    json['currency_code'] as String? ??
                    'INR',
      categoryId: categoryId,
      date: date,
      paymentMethodId: json['paymentMethodId'] as String? ?? json['payment_method_id'] as String?,
      bankAccountId: json['bankAccountId'] as String? ?? json['bank_account_id'] as String?,
      description: json['description'] as String?,
      payerName: json['payerName'] as String? ?? json['payer_name'] as String?,
      notes: json['notes'] as String?,
      isRecurring: isRecurring,
      recurringTransactionId: json['recurringTransactionId'] as String? ?? json['recurring_transaction_id'] as String?,
      recurringFrequency: recurringFrequency,
      recurringDayOfMonth: json['recurringDayOfMonth'] as int? ?? json['recurring_day_of_month'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String? ?? now.toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String? ?? now.toIso8601String()),
    );
  }
}

/// Income Transaction (actual received money)
class IncomeTransaction {
  final String id;
  final String? recurringTransactionId; // Links to recurring transaction (if from recurring)
  final String description;
  final String categoryId; // Changed from IncomeCategory enum
  final double amount;
  final DateTime date;
  final String? bankAccountId;
  final String? notes;
  final bool isRecurring; // Whether this came from a recurring transaction
  final DateTime createdAt;

  const IncomeTransaction({
    required this.id,
    this.recurringTransactionId,
    required this.description,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.bankAccountId,
    this.notes,
    this.isRecurring = false,
    required this.createdAt,
  });

  /// Get category (system only - use getByIdWithCustom for custom support)
  IncomeCategoryModel get category => IncomeCategories.getById(categoryId);
  IconData get icon => category.icon;
  Color get color => category.color;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recurringTransactionId': recurringTransactionId,
      'description': description,
      'categoryId': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'bankAccountId': bankAccountId,
      'notes': notes,
      'isRecurring': isRecurring,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory IncomeTransaction.fromJson(Map<String, dynamic> json) {
    // Support both old format (category index) and new format (categoryId)
    String categoryId;
    if (json.containsKey('categoryId')) {
      categoryId = json['categoryId'] as String;
    } else if (json.containsKey('category')) {
      // Legacy: convert from enum index
      final index = json['category'] as int;
      categoryId = IncomeCategory.values[index].categoryId;
    } else {
      categoryId = 'other';
    }

    return IncomeTransaction(
      id: json['id'] as String,
      // Support both old 'incomeSourceId' and new 'recurringTransactionId'
      recurringTransactionId: json['recurringTransactionId'] as String? ?? json['incomeSourceId'] as String?,
      description: json['description'] as String,
      categoryId: categoryId,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      bankAccountId: json['bankAccountId'] as String? ?? json['paymentMethodId'] as String?,
      notes: json['notes'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

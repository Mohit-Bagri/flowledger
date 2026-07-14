import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';

/// Expense Category
class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double? budgetLimit;
  final bool isSystem;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budgetLimit,
    this.isSystem = true,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
  });

  ExpenseCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    double? budgetLimit,
    bool? isSystem,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      budgetLimit: budgetLimit ?? this.budgetLimit,
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
      'budgetLimit': budgetLimit,
      'isSystem': isSystem,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(
        json['iconCode'] as int,
        fontFamily: 'lucide',
        fontPackage: 'lucide_icons',
      ),
      color: Color(json['colorValue'] as int),
      budgetLimit: json['budgetLimit'] as double?,
      isSystem: json['isSystem'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 100,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

/// Default System Categories
class ExpenseCategories {
  ExpenseCategories._();

  static const ExpenseCategory foodDining = ExpenseCategory(
    id: 'food_dining',
    name: 'Food & Dining',
    icon: LucideIcons.utensils,
    color: AppColors.expenseFood,
    sortOrder: 1,
  );

  static const ExpenseCategory transport = ExpenseCategory(
    id: 'transport',
    name: 'Transport',
    icon: LucideIcons.car,
    color: AppColors.expenseTransport,
    sortOrder: 2,
  );

  static const ExpenseCategory shopping = ExpenseCategory(
    id: 'shopping',
    name: 'Shopping',
    icon: LucideIcons.shoppingBag,
    color: AppColors.expenseShopping,
    sortOrder: 3,
  );

  static const ExpenseCategory entertainment = ExpenseCategory(
    id: 'entertainment',
    name: 'Entertainment',
    icon: LucideIcons.film,
    color: AppColors.expenseEntertainment,
    sortOrder: 4,
  );

  static const ExpenseCategory billsUtilities = ExpenseCategory(
    id: 'bills_utilities',
    name: 'Bills & Utilities',
    icon: LucideIcons.zap,
    color: AppColors.expenseBills,
    sortOrder: 5,
  );

  static const ExpenseCategory rentHousing = ExpenseCategory(
    id: 'rent_housing',
    name: 'Rent & Housing',
    icon: LucideIcons.home,
    color: AppColors.expenseRent,
    sortOrder: 6,
  );

  static const ExpenseCategory healthMedical = ExpenseCategory(
    id: 'health_medical',
    name: 'Health & Medical',
    icon: LucideIcons.heart,
    color: AppColors.expenseHealth,
    sortOrder: 7,
  );

  static const ExpenseCategory subscriptions = ExpenseCategory(
    id: 'subscriptions',
    name: 'Subscriptions',
    icon: LucideIcons.repeat,
    color: AppColors.expenseSubscriptions,
    sortOrder: 8,
  );

  static const ExpenseCategory travel = ExpenseCategory(
    id: 'travel',
    name: 'Travel',
    icon: LucideIcons.plane,
    color: AppColors.expenseTravel,
    sortOrder: 9,
  );

  static const ExpenseCategory education = ExpenseCategory(
    id: 'education',
    name: 'Education',
    icon: LucideIcons.bookOpen,
    color: AppColors.expenseEducation,
    sortOrder: 10,
  );

  static const ExpenseCategory personalCare = ExpenseCategory(
    id: 'personal_care',
    name: 'Personal Care',
    icon: LucideIcons.smile,
    color: AppColors.expensePersonalCare,
    sortOrder: 11,
  );

  static const ExpenseCategory giftsDonations = ExpenseCategory(
    id: 'gifts_donations',
    name: 'Gifts & Donations',
    icon: LucideIcons.gift,
    color: AppColors.expenseGifts,
    sortOrder: 12,
  );

  static const ExpenseCategory insurance = ExpenseCategory(
    id: 'insurance',
    name: 'Insurance',
    icon: LucideIcons.shield,
    color: AppColors.expenseInsurance,
    sortOrder: 13,
  );

  static const ExpenseCategory taxes = ExpenseCategory(
    id: 'taxes',
    name: 'Taxes',
    icon: LucideIcons.fileText,
    color: AppColors.expenseTaxes,
    sortOrder: 14,
  );

  static const ExpenseCategory other = ExpenseCategory(
    id: 'other',
    name: 'Other',
    icon: LucideIcons.moreHorizontal,
    color: AppColors.expenseOther,
    sortOrder: 15,
  );

  static const List<ExpenseCategory> all = [
    foodDining,
    transport,
    shopping,
    entertainment,
    billsUtilities,
    rentHousing,
    healthMedical,
    subscriptions,
    travel,
    education,
    personalCare,
    giftsDonations,
    insurance,
    taxes,
    other,
  ];

  static ExpenseCategory getById(String id) {
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => other,
    );
  }

  /// Get category by ID, checking custom categories list too
  static ExpenseCategory getByIdWithCustom(String id, List<ExpenseCategory> customCategories) {
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

/// Recurring Frequency
enum RecurringFrequency {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  quarterly('Quarterly'),
  yearly('Yearly');

  final String label;
  const RecurringFrequency(this.label);
}

/// Expense Model
class Expense {
  final String id;
  final String name; // Display name for the expense
  final double amount;
  final String currencyCode; // Currency code (e.g., 'INR', 'USD')
  final String categoryId;
  final DateTime date;
  final String paymentMethodId;
  final String? bankAccountId; // Bank account for non-cash payments
  final String? description;
  final String? merchantName;
  final String? receiptId;
  final String? receiptImagePath; // Local or Drive file path/ID
  final String? receiptItemsJson; // JSON string of receipt items
  final bool isRecurring;
  final String? recurringTransactionId; // Links to recurring transaction (if from recurring)
  final RecurringFrequency? recurringFrequency;
  final int? recurringDayOfMonth;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    required this.id,
    required this.name,
    required this.amount,
    this.currencyCode = 'INR',
    required this.categoryId,
    required this.date,
    required this.paymentMethodId,
    this.bankAccountId,
    this.description,
    this.merchantName,
    this.receiptId,
    this.receiptImagePath,
    this.receiptItemsJson,
    this.isRecurring = false,
    this.recurringTransactionId,
    this.recurringFrequency,
    this.recurringDayOfMonth,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if expense has a receipt attached
  bool get hasReceipt => receiptImagePath != null && receiptImagePath!.isNotEmpty;

  ExpenseCategory get category => ExpenseCategories.getById(categoryId);
  IconData get icon => category.icon;
  Color get color => category.color;

  Expense copyWith({
    String? id,
    String? name,
    double? amount,
    String? currencyCode,
    String? categoryId,
    DateTime? date,
    String? paymentMethodId,
    String? bankAccountId,
    String? description,
    String? merchantName,
    String? receiptId,
    String? receiptImagePath,
    String? receiptItemsJson,
    bool? isRecurring,
    String? recurringTransactionId,
    RecurringFrequency? recurringFrequency,
    int? recurringDayOfMonth,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      description: description ?? this.description,
      merchantName: merchantName ?? this.merchantName,
      receiptId: receiptId ?? this.receiptId,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      receiptItemsJson: receiptItemsJson ?? this.receiptItemsJson,
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
      'name': name,
      'amount': amount,
      'currencyCode': currencyCode,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'paymentMethodId': paymentMethodId,
      'bankAccountId': bankAccountId,
      'description': description,
      'merchantName': merchantName,
      'receiptId': receiptId,
      'receiptImagePath': receiptImagePath,
      'receiptItemsJson': receiptItemsJson,
      'isRecurring': isRecurring,
      'recurringTransactionId': recurringTransactionId,
      'recurringFrequency': recurringFrequency?.index,
      'recurringDayOfMonth': recurringDayOfMonth,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      // For backwards compatibility, use merchantName or category as name if not present
      name: json['name'] as String? ??
            json['merchantName'] as String? ??
            'Expense',
      amount: (json['amount'] as num).toDouble(),
      // Support both camelCase and snake_case for currency code
      currencyCode: json['currencyCode'] as String? ??
                    json['currency_code'] as String? ??
                    'INR',
      categoryId: json['categoryId'] as String,
      date: DateTime.parse(json['date'] as String),
      paymentMethodId: json['paymentMethodId'] as String,
      bankAccountId: json['bankAccountId'] as String?,
      description: json['description'] as String?,
      merchantName: json['merchantName'] as String?,
      receiptId: json['receiptId'] as String?,
      receiptImagePath: json['receiptImagePath'] as String?,
      receiptItemsJson: json['receiptItemsJson'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringTransactionId: json['recurringTransactionId'] as String?,
      recurringFrequency: json['recurringFrequency'] != null
          ? RecurringFrequency.values[json['recurringFrequency'] as int]
          : null,
      recurringDayOfMonth: json['recurringDayOfMonth'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

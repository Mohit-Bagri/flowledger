/// Frequency for recurring transactions
enum RecurrenceFrequency {
  daily('Daily', 1),
  weekly('Weekly', 7),
  biweekly('Bi-weekly', 14),
  monthly('Monthly', 30),
  quarterly('Quarterly', 90),
  yearly('Yearly', 365);

  final String label;
  final int approximateDays;
  const RecurrenceFrequency(this.label, this.approximateDays);

  /// Calculate next due date from current date
  DateTime getNextDueDate(DateTime from) {
    switch (this) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.biweekly:
        return from.add(const Duration(days: 14));
      case RecurrenceFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurrenceFrequency.quarterly:
        return DateTime(from.year, from.month + 3, from.day);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }
}

/// Type of recurring transaction
enum RecurringType {
  income('Income'),
  expense('Expense');

  final String label;
  const RecurringType(this.label);
}

/// Recurring Transaction Model
class RecurringTransaction {
  final String id;
  final RecurringType type;
  final String name; // Display name for the recurring transaction
  final double amount;
  final String currencyCode; // Currency for this transaction (e.g., 'INR', 'USD')
  final String categoryId;
  final String? paymentMethodId; // For expenses
  final String? bankAccountId; // For expenses (linked to payment method)
  final String? merchantName; // For expenses
  final String? description;
  final RecurrenceFrequency frequency;
  final DateTime nextDueDate;
  final DateTime? lastProcessedDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringTransaction({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    this.currencyCode = 'INR',
    required this.categoryId,
    this.paymentMethodId,
    this.bankAccountId,
    this.merchantName,
    this.description,
    required this.frequency,
    required this.nextDueDate,
    this.lastProcessedDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if this recurring transaction is due (today or overdue)
  bool get isDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return isActive && (dueDate.isBefore(today) || dueDate.isAtSameMomentAs(today));
  }

  /// Days until next due date (negative if overdue)
  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return dueDate.difference(today).inDays;
  }

  /// Check if overdue
  bool get isOverdue => daysUntilDue < 0;

  RecurringTransaction copyWith({
    String? id,
    RecurringType? type,
    String? name,
    double? amount,
    String? currencyCode,
    String? categoryId,
    String? paymentMethodId,
    String? bankAccountId,
    String? merchantName,
    String? description,
    RecurrenceFrequency? frequency,
    DateTime? nextDueDate,
    DateTime? lastProcessedDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      categoryId: categoryId ?? this.categoryId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      merchantName: merchantName ?? this.merchantName,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastProcessedDate: lastProcessedDate ?? this.lastProcessedDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'name': name,
      'amount': amount,
      'currencyCode': currencyCode,
      'categoryId': categoryId,
      'paymentMethodId': paymentMethodId,
      'bankAccountId': bankAccountId,
      'merchantName': merchantName,
      'description': description,
      'frequency': frequency.index,
      'nextDueDate': nextDueDate.toIso8601String(),
      'lastProcessedDate': lastProcessedDate?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    // Support both camelCase (local) and snake_case (Supabase) formats
    return RecurringTransaction(
      id: json['id'] as String,
      type: RecurringType.values[json['type'] as int],
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? json['currency_code'] as String? ?? 'INR',
      categoryId: json['categoryId'] as String? ?? json['category_id'] as String? ?? 'other',
      paymentMethodId: json['paymentMethodId'] as String? ?? json['payment_method_id'] as String?,
      bankAccountId: json['bankAccountId'] as String? ?? json['bank_account_id'] as String?,
      merchantName: json['merchantName'] as String? ?? json['merchant_name'] as String?,
      description: json['description'] as String?,
      frequency: RecurrenceFrequency.values[json['frequency'] as int],
      nextDueDate: DateTime.parse(json['nextDueDate'] as String? ?? json['next_due_date'] as String),
      lastProcessedDate: (json['lastProcessedDate'] ?? json['last_processed_date']) != null
          ? DateTime.parse(json['lastProcessedDate'] as String? ?? json['last_processed_date'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String),
    );
  }

  /// Create updated transaction after processing (advances next due date)
  RecurringTransaction markAsProcessed() {
    return copyWith(
      lastProcessedDate: DateTime.now(),
      nextDueDate: frequency.getNextDueDate(nextDueDate),
      updatedAt: DateTime.now(),
    );
  }
}

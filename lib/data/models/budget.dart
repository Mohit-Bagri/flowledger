/// Category Budget Model
class CategoryBudget {
  final String id;
  final String categoryId;
  final double amount;
  final String currencyCode; // Currency for this budget (e.g., 'INR', 'USD')
  final int month; // 1-12
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryBudget({
    required this.id,
    required this.categoryId,
    required this.amount,
    this.currencyCode = 'INR',
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  CategoryBudget copyWith({
    String? id,
    String? categoryId,
    double? amount,
    String? currencyCode,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'currencyCode': currencyCode,
      'month': month,
      'year': year,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CategoryBudget.fromJson(Map<String, dynamic> json) {
    return CategoryBudget(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String? ?? json['category_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? json['currency_code'] as String? ?? 'INR',
      month: json['month'] as int,
      year: json['year'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String),
    );
  }

  /// Get unique key for this budget (category + month + year)
  String get budgetKey => '${categoryId}_${month}_$year';

  /// Check if this budget is for a specific month/year
  bool isForPeriod(int checkMonth, int checkYear) {
    return month == checkMonth && year == checkYear;
  }
}

/// Budget Summary for displaying progress
class BudgetProgress {
  final String categoryId;
  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final int month;
  final int year;

  const BudgetProgress({
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.month,
    required this.year,
  });

  /// Amount remaining in budget
  double get remainingAmount => budgetAmount - spentAmount;

  /// Percentage of budget used (0-100+)
  double get percentUsed => budgetAmount > 0 ? (spentAmount / budgetAmount) * 100 : 0;

  /// Whether budget is exceeded
  bool get isOverBudget => spentAmount > budgetAmount;

  /// Whether budget is close to limit (>80%)
  bool get isNearLimit => percentUsed >= 80 && !isOverBudget;

  /// Whether budget is healthy (<50%)
  bool get isHealthy => percentUsed < 50;
}

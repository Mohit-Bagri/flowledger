import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';

/// Savings Goal Model
class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String currencyCode; // Currency for this goal (e.g., 'INR', 'USD')
  final DateTime? targetDate;
  final IconData icon;
  final Color color;
  final List<int> milestonesReached; // [25, 50, 75, 100]
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.currencyCode = 'INR',
    this.targetDate,
    required this.icon,
    required this.color,
    this.milestonesReached = const [],
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Progress percentage (0-100)
  double get progressPercent {
    if (targetAmount <= 0) return 0;
    return ((currentAmount / targetAmount) * 100).clamp(0, 100);
  }

  /// Amount remaining to reach goal
  double get remainingAmount => (targetAmount - currentAmount).clamp(0, double.infinity);

  /// Whether goal is overdue (past target date and not completed)
  bool get isOverdue {
    if (targetDate == null || isCompleted) return false;
    return DateTime.now().isAfter(targetDate!);
  }

  /// Days remaining until target date
  int? get daysRemaining {
    if (targetDate == null) return null;
    final now = DateTime.now();
    return targetDate!.difference(now).inDays;
  }

  /// Check if a milestone was just reached (for notifications)
  int? getNewMilestone(double previousAmount) {
    final previousPercent = targetAmount > 0 ? (previousAmount / targetAmount) * 100 : 0;
    final currentPercent = progressPercent;

    for (final milestone in [25, 50, 75, 100]) {
      if (previousPercent < milestone && currentPercent >= milestone) {
        if (!milestonesReached.contains(milestone)) {
          return milestone;
        }
      }
    }
    return null;
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? currencyCode,
    DateTime? targetDate,
    IconData? icon,
    Color? color,
    List<int>? milestonesReached,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      milestonesReached: milestonesReached ?? this.milestonesReached,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'currencyCode': currencyCode,
      'targetDate': targetDate?.toIso8601String(),
      'iconCode': icon.codePoint,
      'colorValue': color.toARGB32(),
      'milestonesReached': milestonesReached,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num? ?? json['target_amount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num? ?? json['current_amount'] as num?)?.toDouble() ?? 0,
      currencyCode: json['currencyCode'] as String? ?? json['currency_code'] as String? ?? 'INR',
      targetDate: (json['targetDate'] ?? json['target_date']) != null
          ? DateTime.parse(json['targetDate'] as String? ?? json['target_date'] as String)
          : null,
      icon: IconData(
        (json['iconCode'] ?? json['icon_code']) as int,
        fontFamily: 'lucide',
        fontPackage: 'lucide_icons',
      ),
      color: Color((json['colorValue'] ?? json['color_value']) as int),
      milestonesReached: (json['milestonesReached'] as List<dynamic>? ?? json['milestones_reached'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      isCompleted: json['isCompleted'] as bool? ?? json['is_completed'] as bool? ?? false,
      completedAt: (json['completedAt'] ?? json['completed_at']) != null
          ? DateTime.parse(json['completedAt'] as String? ?? json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String),
    );
  }
}

/// Preset goal icons with colors
class GoalPresets {
  GoalPresets._();

  static const List<({IconData icon, Color color, String label})> options = [
    (icon: LucideIcons.piggyBank, color: Color(0xFFEC4899), label: 'Savings'),
    (icon: LucideIcons.home, color: Color(0xFF3B82F6), label: 'Home'),
    (icon: LucideIcons.car, color: Color(0xFF10B981), label: 'Vehicle'),
    (icon: LucideIcons.plane, color: Color(0xFF8B5CF6), label: 'Travel'),
    (icon: LucideIcons.graduationCap, color: Color(0xFFF59E0B), label: 'Education'),
    (icon: LucideIcons.heart, color: Color(0xFFEF4444), label: 'Health'),
    (icon: LucideIcons.gift, color: Color(0xFF06B6D4), label: 'Gift'),
    (icon: LucideIcons.smartphone, color: Color(0xFF6366F1), label: 'Gadget'),
    (icon: LucideIcons.briefcase, color: Color(0xFF84CC16), label: 'Business'),
    (icon: LucideIcons.shield, color: Color(0xFF14B8A6), label: 'Emergency'),
    (icon: LucideIcons.sparkles, color: Color(0xFFF472B6), label: 'Luxury'),
    (icon: LucideIcons.target, color: AppColors.primary, label: 'Other'),
  ];

  static ({IconData icon, Color color, String label}) getByIndex(int index) {
    if (index < 0 || index >= options.length) {
      return options.last;
    }
    return options[index];
  }
}

import '../../data/models/expense.dart';
import '../../data/models/income.dart';
import '../../data/models/budget.dart';

/// Result of health score calculation
class HealthScoreResult {
  final int score;
  final String label;
  final List<HealthFactor> factors;

  const HealthScoreResult({
    required this.score,
    required this.label,
    required this.factors,
  });
}

/// Individual factor contributing to health score
class HealthFactor {
  final String label;
  final String points;
  final bool isPositive;
  final String detail;

  const HealthFactor(this.label, this.points, this.isPositive, this.detail);
}

/// Calculates financial health score based on income, expenses, and budgets
class HealthScoreCalculator {
  /// Calculate health score with all factors
  ///
  /// Parameters:
  /// - [incomeSources]: Current period income sources
  /// - [expenses]: Current period expenses
  /// - [allExpenses]: All historical expenses (for trend analysis)
  /// - [budgets]: Budget limits for categories
  /// - [includeFactors]: Whether to include detailed factors (default: true)
  static HealthScoreResult calculate({
    required List<IncomeSource> incomeSources,
    required List<Expense> expenses,
    List<Expense>? allExpenses,
    List<CategoryBudget>? budgets,
    bool includeFactors = true,
  }) {
    final totalIncome = incomeSources.fold<double>(0, (sum, i) => sum + i.amount);
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final netBalance = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? ((netBalance / totalIncome) * 100).round() : 0;

    int healthScore = 50;
    final factors = <HealthFactor>[];

    // Factor 1: Savings Rate (most important - up to +20 or -20)
    if (savingsRate >= 30) {
      healthScore += 20;
      if (includeFactors) {
        factors.add(HealthFactor('Excellent savings rate', '+20', true, 'Saving $savingsRate% of income'));
      }
    } else if (savingsRate >= 20) {
      healthScore += 15;
      if (includeFactors) {
        factors.add(HealthFactor('Good savings rate', '+15', true, 'Saving $savingsRate% of income'));
      }
    } else if (savingsRate >= 10) {
      healthScore += 10;
      if (includeFactors) {
        factors.add(HealthFactor('Moderate savings', '+10', true, 'Saving $savingsRate% of income'));
      }
    } else if (savingsRate < 0) {
      healthScore -= 20;
      if (includeFactors) {
        factors.add(HealthFactor('Overspending', '-20', false, 'Spending more than earning'));
      }
    } else if (includeFactors) {
      factors.add(HealthFactor('Low savings', '+0', false, 'Try to save at least 20%'));
    }

    // Factor 2: Recurring Income (+15 if has recurring income - indicates stability)
    final recurringIncomes = incomeSources.where((i) => i.isRecurring).length;
    if (recurringIncomes > 0) {
      healthScore += 15;
      if (includeFactors) {
        factors.add(HealthFactor('Recurring income', '+15', true, '$recurringIncomes recurring source(s)'));
      }
    }

    // Factor 3: Income Diversification (+10 if multiple income entries)
    if (incomeSources.length >= 2) {
      healthScore += 10;
      if (includeFactors) {
        factors.add(HealthFactor('Multiple income entries', '+10', true, '${incomeSources.length} entries'));
      }
    }

    // Factor 4: Budget Adherence (up to +15 or -15)
    if (budgets != null && budgets.isNotEmpty) {
      int budgetsWithinLimit = 0;
      int budgetsExceeded = 0;

      for (final budget in budgets) {
        final categoryExpenses = expenses
            .where((e) => e.category.id == budget.categoryId)
            .fold<double>(0, (sum, e) => sum + e.amount);

        if (categoryExpenses <= budget.amount) {
          budgetsWithinLimit++;
        } else {
          budgetsExceeded++;
        }
      }

      if (budgetsExceeded == 0 && budgetsWithinLimit > 0) {
        healthScore += 15;
        if (includeFactors) {
          factors.add(HealthFactor('Budget discipline', '+15', true, 'All $budgetsWithinLimit budget(s) on track'));
        }
      } else if (budgetsExceeded > 0) {
        final penalty = (budgetsExceeded * 5).clamp(0, 15);
        healthScore -= penalty;
        if (includeFactors) {
          factors.add(HealthFactor('Budget overruns', '-$penalty', false, '$budgetsExceeded budget(s) exceeded'));
        }
      }
    }

    // Factor 5: Micro-transaction warning (-10 if too many)
    final smallExpenses = expenses.where((e) => e.amount < 200).length;
    if (smallExpenses > 15) {
      healthScore -= 10;
      if (includeFactors) {
        factors.add(HealthFactor('Many micro-transactions', '-10', false, '$smallExpenses purchases under ₹200'));
      }
    }

    // Factor 6: Spending Consistency (+5 if no unusual spikes)
    if (expenses.isNotEmpty) {
      final avgExpense = totalExpenses / expenses.length;
      final highExpenses = expenses.where((e) => e.amount > avgExpense * 3).length;
      if (highExpenses == 0) {
        healthScore += 5;
        if (includeFactors) {
          factors.add(HealthFactor('Consistent spending', '+5', true, 'No unusual spikes'));
        }
      }
    }

    // Factor 7: Spending Trend (compare to all-time history)
    if (allExpenses != null && allExpenses.length > expenses.length && expenses.isNotEmpty) {
      final previousExpenses = allExpenses.where((e) => !expenses.contains(e)).toList();
      if (previousExpenses.isNotEmpty) {
        final previousTotal = previousExpenses.fold<double>(0, (sum, e) => sum + e.amount);
        final previousMonths = (previousExpenses.length / expenses.length).ceil().clamp(1, 12);
        final avgPreviousMonthly = previousTotal / previousMonths;

        if (avgPreviousMonthly > 0) {
          final changePercent = ((totalExpenses - avgPreviousMonthly) / avgPreviousMonthly * 100).round();
          if (changePercent < -10) {
            healthScore += 5;
            if (includeFactors) {
              factors.add(HealthFactor('Spending improved', '+5', true, '${changePercent.abs()}% less than average'));
            }
          } else if (changePercent > 20) {
            healthScore -= 5;
            if (includeFactors) {
              factors.add(HealthFactor('Spending increased', '-5', false, '$changePercent% more than average'));
            }
          }
        }
      }
    }

    healthScore = healthScore.clamp(0, 100);

    // Determine label
    String healthLabel;
    if (healthScore >= 80) {
      healthLabel = 'Excellent';
    } else if (healthScore >= 60) {
      healthLabel = 'Good';
    } else if (healthScore >= 40) {
      healthLabel = 'Fair';
    } else {
      healthLabel = 'Needs Work';
    }

    return HealthScoreResult(
      score: healthScore,
      label: healthLabel,
      factors: factors,
    );
  }

  /// Get color for health score
  static T getHealthColor<T>(int score, {required T success, required T warning, required T error}) {
    if (score >= 60) return success;
    if (score >= 40) return warning;
    return error;
  }
}

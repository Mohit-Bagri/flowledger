import 'package:flutter/material.dart';

/// FlowLedger Color System
/// Theme: Soft Dark + Light Adaptive (Default: Dark)
class AppColors {
  AppColors._();

  // Primary Brand Color
  static const Color primary = Color(0xFF5B7CFA);
  static const Color primaryLight = Color(0xFF7B96FB);
  static const Color primaryDark = Color(0xFF3B5CD9);

  // Semantic Colors
  static const Color success = Color(0xFF3CCF91);
  static const Color warning = Color(0xFFF5A524);
  static const Color error = Color(0xFFF97066);
  static const Color info = Color(0xFF5B7CFA);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF161A22);
  static const Color darkCard = Color(0xFF1C2128);
  static const Color darkBorder = Color(0xFF2D333B);
  static const Color darkTextPrimary = Color(0xFFE6E8EB);
  static const Color darkTextSecondary = Color(0xFF9BA1A6);
  static const Color darkTextTertiary = Color(0xFF6E7681);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE1E4E8);
  static const Color lightTextPrimary = Color(0xFF1F2328);
  static const Color lightTextSecondary = Color(0xFF57606A);
  static const Color lightTextTertiary = Color(0xFF8B949E);

  // Income Category Colors
  static const Color incomeSalary = Color(0xFF3CCF91);
  static const Color incomeFreelance = Color(0xFF5B7CFA);
  static const Color incomeBusiness = Color(0xFFF5A524);
  static const Color incomePassive = Color(0xFF8B5CF6);
  static const Color incomeRental = Color(0xFF14B8A6);
  static const Color incomeInvestment = Color(0xFFEC4899);
  static const Color incomeGift = Color(0xFFF43F5E);
  static const Color incomeOther = Color(0xFF71717A);

  // Expense Category Colors
  static const Color expenseFood = Color(0xFFF97316);
  static const Color expenseTransport = Color(0xFF3B82F6);
  static const Color expenseShopping = Color(0xFFEC4899);
  static const Color expenseEntertainment = Color(0xFF8B5CF6);
  static const Color expenseBills = Color(0xFFF59E0B);
  static const Color expenseRent = Color(0xFF10B981);
  static const Color expenseHealth = Color(0xFFEF4444);
  static const Color expenseSubscriptions = Color(0xFF6366F1);
  static const Color expenseTravel = Color(0xFF14B8A6);
  static const Color expenseEducation = Color(0xFFF472B6);
  static const Color expensePersonalCare = Color(0xFFA855F7);
  static const Color expenseGifts = Color(0xFFF43F5E);
  static const Color expenseInsurance = Color(0xFF0EA5E9);
  static const Color expenseTaxes = Color(0xFF64748B);
  static const Color expenseOther = Color(0xFF71717A);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF5B7CFA),
    Color(0xFF3CCF91),
    Color(0xFFF5A524),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF3B82F6),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B7CFA), Color(0xFF8B5CF6)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3CCF91), Color(0xFF14B8A6)],
  );
}

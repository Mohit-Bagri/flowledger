import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Bank Account Type
enum BankAccountType {
  savings('Savings'),
  current('Current'),
  salary('Salary'),
  fixedDeposit('Fixed Deposit'),
  nri('NRI'),
  other('Other');

  final String label;
  const BankAccountType(this.label);
}

/// Bank Account Model
class BankAccount {
  final String id;
  final String bankName;
  final String accountName;
  final String? accountNumber; // Last 4 digits only stored
  final String? ifscCode;
  final BankAccountType accountType;
  final String? customAccountTypeLabel; // For "Other" account type
  final Color color;
  final bool isActive;
  final DateTime createdAt;

  const BankAccount({
    required this.id,
    required this.bankName,
    required this.accountName,
    this.accountNumber,
    this.ifscCode,
    required this.accountType,
    this.customAccountTypeLabel,
    required this.color,
    this.isActive = true,
    required this.createdAt,
  });

  /// Get the display label for account type
  String get accountTypeLabel {
    if (accountType == BankAccountType.other && customAccountTypeLabel != null && customAccountTypeLabel!.isNotEmpty) {
      return customAccountTypeLabel!;
    }
    return accountType.label;
  }

  String get displayAccountNumber {
    if (accountNumber == null || accountNumber!.isEmpty) return '';
    return '****${accountNumber!.length > 4 ? accountNumber!.substring(accountNumber!.length - 4) : accountNumber}';
  }

  BankAccount copyWith({
    String? id,
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? ifscCode,
    BankAccountType? accountType,
    String? customAccountTypeLabel,
    Color? color,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      accountType: accountType ?? this.accountType,
      customAccountTypeLabel: customAccountTypeLabel ?? this.customAccountTypeLabel,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountType': accountType.index,
      'customAccountTypeLabel': customAccountTypeLabel,
      'color': color.value,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      bankName: json['bankName'] as String,
      accountName: json['accountName'] as String,
      accountNumber: json['accountNumber'] as String?,
      ifscCode: json['ifscCode'] as String?,
      accountType: BankAccountType.values[json['accountType'] as int],
      customAccountTypeLabel: json['customAccountTypeLabel'] as String?,
      color: Color(json['color'] as int),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Pre-defined Indian Banks
class Banks {
  Banks._();

  static const List<String> indian = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Yes Bank',
    'Punjab National Bank',
    'Bank of Baroda',
    'Canara Bank',
    'IndusInd Bank',
    'IDFC First Bank',
    'Federal Bank',
    'Bank of India',
    'Union Bank of India',
    'Indian Bank',
    'Central Bank of India',
    'IDBI Bank',
    'Indian Overseas Bank',
    'UCO Bank',
    'Bank of Maharashtra',
    'Punjab & Sind Bank',
    'Bandhan Bank',
    'RBL Bank',
    'South Indian Bank',
    'Karnataka Bank',
    'Karur Vysya Bank',
    'City Union Bank',
    'Tamilnad Mercantile Bank',
    'DCB Bank',
    'Dhanlaxmi Bank',
    'Jammu & Kashmir Bank',
    'AU Small Finance Bank',
    'Equitas Small Finance Bank',
    'Ujjivan Small Finance Bank',
    'Jana Small Finance Bank',
    'Paytm Payments Bank',
    'Airtel Payments Bank',
    'India Post Payments Bank',
    'Fino Payments Bank',
  ];

  static const List<String> international = [
    'Chase',
    'Bank of America',
    'Wells Fargo',
    'Citibank',
    'HSBC',
    'Barclays',
    'Standard Chartered',
    'Deutsche Bank',
    'BNP Paribas',
    'Credit Suisse',
    'UBS',
    'Goldman Sachs',
    'Morgan Stanley',
    'JP Morgan',
  ];

  static List<String> get all => [...indian, ...international];
}

/// Account Colors for visual distinction
class AccountColors {
  AccountColors._();

  static const List<Color> options = [
    AppColors.primary,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
  ];
}

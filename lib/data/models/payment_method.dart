import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';

/// Payment Method Type
enum PaymentMethodType {
  cash('Cash', LucideIcons.banknote),
  bankTransfer('Bank Transfer', LucideIcons.building2),
  upi('UPI', LucideIcons.smartphone),
  debitCard('Debit Card', LucideIcons.creditCard),
  creditCard('Credit Card', LucideIcons.creditCard),
  wallet('Wallet', LucideIcons.wallet),
  cheque('Cheque', LucideIcons.fileText),
  other('Other', LucideIcons.moreHorizontal);

  final String label;
  final IconData icon;
  const PaymentMethodType(this.label, this.icon);
}

/// Payment Method Model
class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String name;
  final String? bankAccountId; // Links to bank account (optional)
  final String? lastFourDigits; // For cards
  final String? upiId; // For UPI
  final Color color;
  final bool isActive;
  final DateTime createdAt;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    this.bankAccountId,
    this.lastFourDigits,
    this.upiId,
    required this.color,
    this.isActive = true,
    required this.createdAt,
  });

  String get displayName {
    if (lastFourDigits != null && lastFourDigits!.isNotEmpty) {
      return '$name ****$lastFourDigits';
    }
    if (upiId != null && upiId!.isNotEmpty) {
      return '$name ($upiId)';
    }
    return name;
  }

  IconData get icon => type.icon;

  PaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? name,
    String? bankAccountId,
    String? lastFourDigits,
    String? upiId,
    Color? color,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      upiId: upiId ?? this.upiId,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'name': name,
      'bankAccountId': bankAccountId,
      'lastFourDigits': lastFourDigits,
      'upiId': upiId,
      'color': color.value,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      type: PaymentMethodType.values[json['type'] as int],
      name: json['name'] as String,
      bankAccountId: json['bankAccountId'] as String?,
      lastFourDigits: json['lastFourDigits'] as String?,
      upiId: json['upiId'] as String?,
      color: Color(json['color'] as int),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Default Cash payment method
  static PaymentMethod get cash => PaymentMethod(
        id: 'cash',
        type: PaymentMethodType.cash,
        name: 'Cash',
        color: AppColors.success,
        createdAt: DateTime.now(),
      );
}

/// Pre-defined UPI Apps
class UpiApps {
  UpiApps._();

  static const List<String> popular = [
    'Google Pay',
    'PhonePe',
    'Paytm',
    'Amazon Pay',
    'BHIM',
    'WhatsApp Pay',
    'CRED',
    'MobiKwik',
    'Freecharge',
  ];
}

/// Pre-defined Digital Wallets
class DigitalWallets {
  DigitalWallets._();

  static const List<String> popular = [
    'Paytm Wallet',
    'Amazon Pay Balance',
    'PhonePe Wallet',
    'MobiKwik Wallet',
    'Freecharge Wallet',
    'Ola Money',
    'PayPal',
    'Apple Pay',
    'Google Wallet',
  ];
}

import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Represents a single item extracted from a receipt
class ReceiptItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final bool isSelected;

  const ReceiptItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.isSelected = true,
  });

  double get total => price * quantity;

  ReceiptItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    bool? isSelected,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'isSelected': isSelected,
    };
  }

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      isSelected: json['isSelected'] as bool? ?? true,
    );
  }

  /// Create a new item with generated ID
  factory ReceiptItem.create({
    required String name,
    required double price,
    int quantity = 1,
  }) {
    return ReceiptItem(
      id: const Uuid().v4(),
      name: name,
      price: price,
      quantity: quantity,
      isSelected: true,
    );
  }
}

/// Represents a scanned receipt with extracted data
class Receipt {
  final String id;
  final String? localImagePath;
  final String? driveFileId;
  final String? merchantName;
  final DateTime? extractedDate;
  final List<ReceiptItem> items;
  final double? extractedTotal;
  final String? rawText;
  final DateTime createdAt;

  const Receipt({
    required this.id,
    this.localImagePath,
    this.driveFileId,
    this.merchantName,
    this.extractedDate,
    required this.items,
    this.extractedTotal,
    this.rawText,
    required this.createdAt,
  });

  /// Get total of all selected items
  double get selectedTotal {
    return items
        .where((item) => item.isSelected)
        .fold(0.0, (sum, item) => sum + item.total);
  }

  /// Get count of selected items
  int get selectedCount {
    return items.where((item) => item.isSelected).length;
  }

  /// Check if receipt has an image (local or cloud)
  bool get hasImage => localImagePath != null || driveFileId != null;

  Receipt copyWith({
    String? id,
    String? localImagePath,
    String? driveFileId,
    String? merchantName,
    DateTime? extractedDate,
    List<ReceiptItem>? items,
    double? extractedTotal,
    String? rawText,
    DateTime? createdAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      localImagePath: localImagePath ?? this.localImagePath,
      driveFileId: driveFileId ?? this.driveFileId,
      merchantName: merchantName ?? this.merchantName,
      extractedDate: extractedDate ?? this.extractedDate,
      items: items ?? this.items,
      extractedTotal: extractedTotal ?? this.extractedTotal,
      rawText: rawText ?? this.rawText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localImagePath': localImagePath,
      'driveFileId': driveFileId,
      'merchantName': merchantName,
      'extractedDate': extractedDate?.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
      'extractedTotal': extractedTotal,
      'rawText': rawText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      localImagePath: json['localImagePath'] as String?,
      driveFileId: json['driveFileId'] as String?,
      merchantName: json['merchantName'] as String?,
      extractedDate: json['extractedDate'] != null
          ? DateTime.parse(json['extractedDate'] as String)
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      extractedTotal: (json['extractedTotal'] as num?)?.toDouble(),
      rawText: json['rawText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Create a new receipt with generated ID
  factory Receipt.create({
    String? localImagePath,
    String? driveFileId,
    String? merchantName,
    DateTime? extractedDate,
    List<ReceiptItem>? items,
    double? extractedTotal,
    String? rawText,
  }) {
    return Receipt(
      id: const Uuid().v4(),
      localImagePath: localImagePath,
      driveFileId: driveFileId,
      merchantName: merchantName,
      extractedDate: extractedDate,
      items: items ?? [],
      extractedTotal: extractedTotal,
      rawText: rawText,
      createdAt: DateTime.now(),
    );
  }

  /// Convert items list to JSON string for storage in expense
  String itemsToJsonString() {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  /// Parse items from JSON string stored in expense
  static List<ReceiptItem> itemsFromJsonString(String jsonString) {
    final List<dynamic> list = jsonDecode(jsonString);
    return list.map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

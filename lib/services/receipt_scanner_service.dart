import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:uuid/uuid.dart';
import '../data/models/receipt.dart';

/// Optimized Receipt Scanner Service with improved ML algorithms
class ReceiptScannerService {
  ReceiptScannerService._();
  static final ReceiptScannerService instance = ReceiptScannerService._();

  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Confidence thresholds
  static const double _minPriceConfidence = 0.6;
  static const double _minTotalConfidence = 0.7;

  /// Pick image from camera or gallery
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90, // Higher quality for better OCR
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick PDF file from device
  Future<File?> pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          return File(path);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error picking PDF: $e');
      return null;
    }
  }

  /// Extract text from PDF file with optimized multi-page processing
  /// Returns a tuple of (extractedText, firstPageImageFile)
  Future<(String, File?)?> extractTextFromPdf(File pdfFile) async {
    try {
      debugPrint('=== OPTIMIZED PDF EXTRACTION STARTING ===');
      debugPrint('Opening PDF document: ${pdfFile.path}');

      final document = await PdfDocument.openFile(pdfFile.path);
      final totalPages = document.pagesCount;
      debugPrint('PDF has $totalPages pages');

      final StringBuffer allText = StringBuffer();
      File? firstPageImage;
      final List<_PageExtractionResult> pageResults = [];

      // Determine optimal pages to process
      // For receipts: usually 1-3 pages contain relevant info
      // For bank statements: first and last few pages are important
      final pagesToProcess = _determineOptimalPages(totalPages);
      debugPrint('Processing pages: $pagesToProcess');

      for (final pageNum in pagesToProcess) {
        if (pageNum < 1 || pageNum > totalPages) continue;

        debugPrint('Processing page $pageNum of $totalPages');
        final result = await _extractTextFromPage(document, pageNum);

        if (result != null) {
          pageResults.add(result);

          // Save first page image for preview
          if (pageNum == 1 && result.imageFile != null) {
            firstPageImage = result.imageFile;
          } else if (result.imageFile != null && pageNum != 1) {
            // Clean up non-first page images
            try {
              await result.imageFile!.delete();
            } catch (_) {}
          }
        }
      }

      await document.close();

      // Merge and deduplicate text from all pages
      final mergedText = _mergePageResults(pageResults);
      debugPrint('Extracted ${mergedText.length} characters from PDF');

      if (mergedText.isEmpty) {
        if (firstPageImage != null) {
          try {
            await firstPageImage.delete();
          } catch (_) {}
        }
        return null;
      }

      return (mergedText, firstPageImage);
    } catch (e) {
      debugPrint('Error extracting text from PDF: $e');
      return null;
    }
  }

  /// Determine which pages to process based on document length
  List<int> _determineOptimalPages(int totalPages) {
    if (totalPages <= 3) {
      // Process all pages for short documents
      return List.generate(totalPages, (i) => i + 1);
    } else if (totalPages <= 10) {
      // Process first 3 and last 2 pages for medium documents
      return [1, 2, 3, totalPages - 1, totalPages];
    } else {
      // For long documents (likely bank statements)
      // Process first 3, middle, and last 2 pages
      final middle = totalPages ~/ 2;
      return [1, 2, 3, middle, totalPages - 1, totalPages];
    }
  }

  /// Extract text from a single PDF page with optimized settings
  Future<_PageExtractionResult?> _extractTextFromPage(
    PdfDocument document,
    int pageNum,
  ) async {
    try {
      final page = await document.getPage(pageNum);

      // Calculate optimal render scale based on page size
      // Larger pages need lower scale, smaller pages need higher scale
      final scaleFactor = _calculateOptimalScale(page.width, page.height);

      final pageImage = await page.render(
        width: page.width * scaleFactor,
        height: page.height * scaleFactor,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );

      await page.close();

      if (pageImage == null) {
        debugPrint('Failed to render page $pageNum');
        return null;
      }

      // Save page image to temp file for ML Kit
      final tempDir = await getTemporaryDirectory();
      final tempImagePath = '${tempDir.path}/pdf_page_$pageNum.png';
      final tempImageFile = File(tempImagePath);
      await tempImageFile.writeAsBytes(pageImage.bytes);

      // Extract text with block-level analysis
      final extractionResult = await _extractTextWithBlocks(tempImageFile);

      return _PageExtractionResult(
        pageNumber: pageNum,
        text: extractionResult.text,
        blocks: extractionResult.blocks,
        imageFile: tempImageFile,
      );
    } catch (e) {
      debugPrint('Error extracting text from page $pageNum: $e');
      return null;
    }
  }

  /// Calculate optimal render scale based on page dimensions
  double _calculateOptimalScale(double width, double height) {
    const targetPixels = 2048 * 2048; // ~4MP target
    final currentPixels = width * height;

    if (currentPixels < targetPixels / 4) {
      return 3.0; // Small page, scale up significantly
    } else if (currentPixels < targetPixels) {
      return 2.0; // Medium page, scale up moderately
    } else {
      return 1.5; // Large page, minimal scaling
    }
  }

  /// Extract text with block-level information for better parsing
  Future<_TextExtractionResult> _extractTextWithBlocks(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final blocks = <_TextBlock>[];

      for (final block in recognizedText.blocks) {
        blocks.add(_TextBlock(
          text: block.text,
          boundingBox: block.boundingBox,
          lines: block.lines.map((line) => _TextLine(
            text: line.text,
            boundingBox: line.boundingBox,
            confidence: line.confidence ?? 0.0,
          )).toList(),
        ));
      }

      return _TextExtractionResult(
        text: recognizedText.text,
        blocks: blocks,
      );
    } catch (e) {
      debugPrint('Error extracting text: $e');
      return _TextExtractionResult(text: '', blocks: []);
    }
  }

  /// Extract text from image using ML Kit (legacy method for compatibility)
  Future<String> extractText(File imageFile) async {
    final result = await _extractTextWithBlocks(imageFile);
    return result.text;
  }

  /// Merge text from multiple pages, removing duplicates
  String _mergePageResults(List<_PageExtractionResult> results) {
    if (results.isEmpty) return '';
    if (results.length == 1) return results.first.text;

    // Sort by page number
    results.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    final StringBuffer merged = StringBuffer();
    final seenLines = <String>{};

    for (final result in results) {
      final lines = result.text.split('\n');

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        // Normalize line for comparison (remove extra spaces, lowercase)
        final normalizedLine = trimmedLine.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

        // Only add if not seen before (avoid duplicate headers/footers)
        if (!seenLines.contains(normalizedLine)) {
          seenLines.add(normalizedLine);
          merged.writeln(trimmedLine);
        }
      }

      merged.writeln(''); // Page separator
    }

    return merged.toString().trim();
  }

  /// Parse extracted text to create a Receipt object with improved algorithms
  Receipt parseReceiptText(String rawText, {String? imagePath}) {
    final lines = rawText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    String? merchantName;
    DateTime? extractedDate;
    ({int hour, int minute})? extractedTime;
    final List<ReceiptItem> items = [];
    double? extractedTotal;
    double? extractedSubtotal;
    double? extractedTax;

    // Enhanced patterns for better parsing
    final pricePatterns = [
      RegExp(r'[₹Rs\.]*\s*([\d,]+\.?\d{0,2})\s*$'), // Indian format
      RegExp(r'\$\s*([\d,]+\.?\d{0,2})\s*$'), // USD format
      RegExp(r'([\d,]+\.?\d{0,2})\s*[₹$€£]?\s*$'), // Generic with optional currency
    ];

    final totalPatterns = [
      RegExp(r'(total|grand\s*total|net\s*amount|amount\s*due|amount\s*payable|bill\s*amount|final\s*amount)\s*:?\s*[₹Rs\.$]*\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'[₹Rs\.$]*\s*([\d,]+\.?\d{0,2})\s*(total|grand\s*total)', caseSensitive: false),
    ];

    final subtotalPatterns = [
      RegExp(r'(sub\s*total|subtotal|sub-total|item\s*total)\s*:?\s*[₹Rs\.$]*\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
    ];

    final taxPatterns = [
      RegExp(r'(tax|gst|cgst|sgst|igst|vat|service\s*charge)\s*:?\s*[₹Rs\.$]*\s*([\d,]+\.?\d{0,2})', caseSensitive: false),
    ];

    final datePatterns = [
      RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})'), // DD/MM/YYYY or MM/DD/YYYY
      RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2})'), // DD/MM/YY
      RegExp(r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})'), // YYYY/MM/DD
      RegExp(r"(\d{1,2})\s*(?:st|nd|rd|th)?\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*[,']?\s*(\d{2,4})", caseSensitive: false),
    ];

    final timePatterns = [
      // 12-hour format: 7:30 PM, 7:30PM, 7:30 pm, 07:30 PM
      RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm|A\.M\.|P\.M\.|a\.m\.|p\.m\.)', caseSensitive: false),
      // Time with "Time:" prefix
      RegExp(r'[Tt]ime[:\s]+(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?', caseSensitive: false),
      // 24-hour format: 19:30, 07:30 (only match if followed by whitespace or end)
      RegExp(r'(?:^|[^\d])(\d{1,2}):(\d{2})(?:\s|$)'),
    ];

    // Words to skip when looking for items
    final skipWords = {
      'tax', 'gst', 'cgst', 'sgst', 'igst', 'vat', 'service', 'charge',
      'discount', 'cash', 'card', 'upi', 'change', 'balance', 'paid',
      'invoice', 'bill', 'receipt', 'thank', 'visit', 'again', 'tel',
      'phone', 'address', 'gstin', 'fssai', 'tin', 'pan', 'total',
      'subtotal', 'sub-total', 'amount', 'payment', 'received', 'date',
      'time', 'cashier', 'counter', 'order', 'token', 'no.', 'number',
      'customer', 'member', 'loyalty', 'points', 'save', 'saved',
    };

    // Extract merchant name from first few lines
    merchantName = _extractMerchantName(lines);

    // Process each line
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();

      // Extract date
      if (extractedDate == null) {
        for (final pattern in datePatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            extractedDate = _parseDate(match.group(0) ?? '');
            if (extractedDate != null) break;
          }
        }
      }

      // Extract time
      if (extractedTime == null) {
        for (final pattern in timePatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            var hour = int.tryParse(match.group(1) ?? '') ?? 0;
            final minute = int.tryParse(match.group(2) ?? '') ?? 0;

            // Check for AM/PM indicator
            String? ampm;
            if (match.groupCount >= 3) {
              ampm = match.group(3)?.toUpperCase().replaceAll('.', '');
            }

            // Convert to 24-hour format
            if (ampm != null && ampm.isNotEmpty) {
              if (ampm == 'PM' && hour < 12) {
                hour += 12;
              } else if (ampm == 'AM' && hour == 12) {
                hour = 0;
              }
            }

            // Validate
            if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
              extractedTime = (hour: hour, minute: minute);
              break;
            }
          }
        }
      }

      // Extract total
      if (extractedTotal == null) {
        for (final pattern in totalPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final totalStr = match.group(2)?.replaceAll(',', '') ?? '';
            final parsedTotal = double.tryParse(totalStr);
            if (parsedTotal != null && parsedTotal > 0) {
              extractedTotal = parsedTotal;
              break;
            }
          }
        }
      }

      // Extract subtotal
      if (extractedSubtotal == null) {
        for (final pattern in subtotalPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final str = match.group(2)?.replaceAll(',', '') ?? '';
            extractedSubtotal = double.tryParse(str);
            if (extractedSubtotal != null) break;
          }
        }
      }

      // Extract tax
      for (final pattern in taxPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final str = match.group(2)?.replaceAll(',', '') ?? '';
          final tax = double.tryParse(str);
          if (tax != null && tax > 0) {
            extractedTax = (extractedTax ?? 0) + tax;
          }
        }
      }

      // Skip lines with skip words (but we've already extracted totals/taxes above)
      if (skipWords.any((word) => lowerLine.contains(word))) {
        continue;
      }

      // Try to extract item with price
      final item = _parseItemLine(line, pricePatterns);
      if (item != null && _isValidItem(item)) {
        items.add(item);
      }
    }

    // Validate and adjust total if needed
    extractedTotal = _validateTotal(extractedTotal, extractedSubtotal, extractedTax, items);

    // If no items found but we have a total, create a single item
    if (items.isEmpty && extractedTotal != null && extractedTotal > 0) {
      items.add(ReceiptItem.create(
        name: merchantName ?? 'Purchase',
        price: extractedTotal,
      ));
    }

    // Combine date and time if both were extracted
    if (extractedDate != null && extractedTime != null) {
      extractedDate = DateTime(
        extractedDate.year,
        extractedDate.month,
        extractedDate.day,
        extractedTime.hour,
        extractedTime.minute,
      );
    }

    debugPrint('=== RECEIPT PARSING COMPLETE ===');
    debugPrint('Merchant: $merchantName');
    debugPrint('Date: $extractedDate');
    debugPrint('Time: ${extractedTime != null ? "${extractedTime.hour}:${extractedTime.minute}" : "not found"}');
    debugPrint('Items: ${items.length}');
    debugPrint('Total: $extractedTotal');

    return Receipt.create(
      localImagePath: imagePath,
      merchantName: merchantName,
      extractedDate: extractedDate,
      items: items,
      extractedTotal: extractedTotal,
      rawText: rawText,
    );
  }

  /// Extract merchant name from first few lines
  String? _extractMerchantName(List<String> lines) {
    // Look at first 5 lines for merchant name
    final candidateLines = lines.take(5).toList();

    for (final line in candidateLines) {
      // Skip if line is too short or too long
      if (line.length < 3 || line.length > 60) continue;

      // Skip if line looks like a date or address
      if (RegExp(r'\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{2,4}').hasMatch(line)) continue;
      if (RegExp(r'\d{5,}').hasMatch(line)) continue; // Postal code or phone

      // Skip if line is mostly numbers
      final nonDigits = line.replaceAll(RegExp(r'\d'), '').length;
      if (nonDigits < line.length * 0.5) continue;

      // Skip common non-merchant lines
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('invoice') ||
          lowerLine.contains('receipt') ||
          lowerLine.contains('bill') ||
          lowerLine.contains('tax') ||
          lowerLine.contains('gstin')) continue;

      return _cleanMerchantName(line);
    }

    return null;
  }

  /// Clean merchant name from extracted text
  String _cleanMerchantName(String name) {
    var cleaned = name
        .replaceAll(RegExp(r'(pvt\.?\s*ltd\.?|limited|inc\.?|corp\.?|llc)', caseSensitive: false), '')
        .replaceAll(RegExp(r'[*#@\[\]{}]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Title case if all uppercase
    if (cleaned.toUpperCase() == cleaned && cleaned.length > 3) {
      cleaned = cleaned.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }

    return cleaned;
  }

  /// Parse a line to extract item name and price
  ReceiptItem? _parseItemLine(String line, List<RegExp> pricePatterns) {
    // Remove currency symbols for parsing
    var cleanLine = line.replaceAll(RegExp(r'[₹$€£]'), '').trim();

    // Pattern 1: Quantity x Item @ Price = Total
    final qtyPattern = RegExp(r'^(\d+)\s*[xX×]\s*(.+?)\s*[@=]\s*([\d,]+\.?\d{0,2})');
    final qtyMatch = qtyPattern.firstMatch(cleanLine);
    if (qtyMatch != null) {
      final qty = int.tryParse(qtyMatch.group(1) ?? '1') ?? 1;
      final name = qtyMatch.group(2)?.trim() ?? '';
      final priceStr = qtyMatch.group(3)?.replaceAll(',', '') ?? '';
      final price = double.tryParse(priceStr);

      if (name.isNotEmpty && price != null && price > 0) {
        return ReceiptItem.create(
          name: _cleanItemName(name),
          price: price / qty,
          quantity: qty,
        );
      }
    }

    // Pattern 2: Item name followed by quantity and price
    final itemQtyPattern = RegExp(r'^(.+?)\s+(\d+)\s*[xX×]?\s*([\d,]+\.?\d{0,2})$');
    final itemQtyMatch = itemQtyPattern.firstMatch(cleanLine);
    if (itemQtyMatch != null) {
      final name = itemQtyMatch.group(1)?.trim() ?? '';
      final qty = int.tryParse(itemQtyMatch.group(2) ?? '1') ?? 1;
      final priceStr = itemQtyMatch.group(3)?.replaceAll(',', '') ?? '';
      final price = double.tryParse(priceStr);

      if (name.isNotEmpty && price != null && price > 0 && qty > 0 && qty < 100) {
        return ReceiptItem.create(
          name: _cleanItemName(name),
          price: price / qty,
          quantity: qty,
        );
      }
    }

    // Pattern 3: Simple name followed by price
    for (final pattern in pricePatterns) {
      final match = pattern.firstMatch(cleanLine);
      if (match != null) {
        final priceStr = match.group(1)?.replaceAll(',', '') ?? '';
        final price = double.tryParse(priceStr);

        if (price != null && price > 0 && price < 100000) {
          // Extract name by removing the price part
          var name = cleanLine.replaceFirst(pattern, '').trim();
          name = _cleanItemName(name);

          if (name.isNotEmpty && name.length >= 2) {
            return ReceiptItem.create(name: name, price: price);
          }
        }
      }
    }

    return null;
  }

  /// Check if item is valid
  bool _isValidItem(ReceiptItem item) {
    // Check name validity
    if (item.name.isEmpty || item.name.length < 2) return false;

    // Check price validity
    if (item.price <= 0 || item.price > 100000) return false;

    // Check if name is mostly alphanumeric
    final alphaNumeric = item.name.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
    if (alphaNumeric.length < item.name.length * 0.5) return false;

    return true;
  }

  /// Clean item name
  String _cleanItemName(String name) {
    return name
        .replaceAll(RegExp(r'^\d+\s*[xX×]?\s*'), '') // Remove leading quantity
        .replaceAll(RegExp(r'\s*[@=]\s*[\d,\.]+$'), '') // Remove trailing price indicator
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  /// Validate and adjust total
  double? _validateTotal(
    double? total,
    double? subtotal,
    double? tax,
    List<ReceiptItem> items,
  ) {
    // Calculate items total
    final itemsTotal = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

    // If we have a total, validate it
    if (total != null && total > 0) {
      // Check if total is reasonable compared to items
      if (itemsTotal > 0) {
        final ratio = total / itemsTotal;
        // Total should be within 50% of items total (accounting for tax, discounts)
        if (ratio >= 0.5 && ratio <= 2.0) {
          return total;
        }
      }
      return total;
    }

    // If no total but we have subtotal and tax
    if (subtotal != null && subtotal > 0) {
      return subtotal + (tax ?? 0);
    }

    // If no total but we have items
    if (itemsTotal > 0) {
      return itemsTotal;
    }

    return null;
  }

  /// Parse date string to DateTime
  static final DateTime minSupportedDate = DateTime(2020, 1, 1);

  DateTime? _parseDate(String dateStr) {
    try {
      int? hour;
      int? minute;

      // Try month name format first
      final monthNamePattern = RegExp(
        r"(\d{1,2})\s*(?:st|nd|rd|th)?\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*[,']?\s*(\d{2,4})",
        caseSensitive: false,
      );

      final monthMatch = monthNamePattern.firstMatch(dateStr);
      if (monthMatch != null) {
        final day = int.tryParse(monthMatch.group(1) ?? '') ?? 1;
        final monthStr = monthMatch.group(2)?.toLowerCase() ?? '';
        var year = int.tryParse(monthMatch.group(3) ?? '') ?? 2024;

        if (year < 100) year += 2000;

        final months = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
        };

        final month = months[monthStr] ?? 1;
        return _clampDate(DateTime(year, month, day));
      }

      // Try numeric formats
      final formats = [
        RegExp(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})'), // DD/MM/YYYY
        RegExp(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2})'), // DD/MM/YY
        RegExp(r'(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})'), // YYYY/MM/DD
      ];

      for (final format in formats) {
        final match = format.firstMatch(dateStr);
        if (match != null) {
          var g1 = int.tryParse(match.group(1) ?? '') ?? 0;
          var g2 = int.tryParse(match.group(2) ?? '') ?? 0;
          var g3 = int.tryParse(match.group(3) ?? '') ?? 0;

          int year, month, day;

          // Determine format based on values
          if (g1 > 31) {
            // YYYY/MM/DD
            year = g1;
            month = g2;
            day = g3;
          } else if (g3 > 31 || g3 < 100) {
            // DD/MM/YYYY or DD/MM/YY
            day = g1;
            month = g2;
            year = g3 < 100 ? g3 + 2000 : g3;
          } else {
            // Ambiguous, assume DD/MM/YYYY
            day = g1;
            month = g2;
            year = g3;
          }

          // Validate
          if (year >= 2000 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            return _clampDate(DateTime(year, month, day, hour ?? 0, minute ?? 0));
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clamp date to valid range
  DateTime _clampDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (date.isBefore(minSupportedDate)) {
      return today;
    } else if (date.isAfter(today)) {
      return today;
    }
    return date;
  }

  /// Save receipt image to app documents directory
  Future<String> saveReceiptImage(File imageFile, String expenseId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${appDir.path}/receipts');

      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = 'receipt_${expenseId}_${const Uuid().v4().substring(0, 8)}.jpg';
      final savedFile = await imageFile.copy('${receiptsDir.path}/$fileName');

      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving receipt image: $e');
      rethrow;
    }
  }

  /// Delete receipt image
  Future<void> deleteReceiptImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting receipt image: $e');
    }
  }

  /// Get receipts directory
  Future<Directory> getReceiptsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${appDir.path}/receipts');

    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    return receiptsDir;
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}

// Helper classes for block-level text extraction

class _TextBlock {
  final String text;
  final Rect? boundingBox;
  final List<_TextLine> lines;

  _TextBlock({
    required this.text,
    this.boundingBox,
    required this.lines,
  });
}

class _TextLine {
  final String text;
  final Rect? boundingBox;
  final double confidence;

  _TextLine({
    required this.text,
    this.boundingBox,
    required this.confidence,
  });
}

class _TextExtractionResult {
  final String text;
  final List<_TextBlock> blocks;

  _TextExtractionResult({
    required this.text,
    required this.blocks,
  });
}

class _PageExtractionResult {
  final int pageNumber;
  final String text;
  final List<_TextBlock> blocks;
  final File? imageFile;

  _PageExtractionResult({
    required this.pageNumber,
    required this.text,
    required this.blocks,
    this.imageFile,
  });
}

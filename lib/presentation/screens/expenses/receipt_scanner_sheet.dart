import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/premium_features.dart';
import '../../../core/services/permission_service.dart';
import '../../../data/models/receipt.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/receipt_scanner_service.dart';
import '../../../services/usage_tracking_service.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common/bottom_sheet_handle.dart';
import '../../widgets/common/upgrade_dialog.dart';
import 'receipt_review_sheet.dart';

/// Receipt Scanner Sheet - Pick image source and scan receipt
class ReceiptScannerSheet extends ConsumerStatefulWidget {
  const ReceiptScannerSheet({super.key});

  static Future<Receipt?> show(BuildContext context) {
    return showModalBottomSheet<Receipt>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReceiptScannerSheet(),
    );
  }

  @override
  ConsumerState<ReceiptScannerSheet> createState() => _ReceiptScannerSheetState();
}

class _ReceiptScannerSheetState extends ConsumerState<ReceiptScannerSheet> {
  bool _isScanning = false;
  String? _errorMessage;
  String? _scanningMessage;

  /// Check if user can scan (premium or under free limit)
  Future<bool> _checkScanLimit() async {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) return true;

    final currentCount = await UsageTrackingService.instance.getReceiptScanCount();
    final limit = FreeTierLimits.receiptScansPerMonth;

    if (currentCount >= limit) {
      if (mounted) {
        UpgradeDialog.show(
          context,
          feature: PremiumFeature.unlimitedReceiptScanning,
          currentCount: currentCount,
          limit: limit,
        );
      }
      return false;
    }

    return true;
  }

  /// Increment scan count after successful scan
  Future<void> _incrementScanCount() async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      await UsageTrackingService.instance.incrementReceiptScanCount();
    }
  }

  /// Scan a PDF receipt
  Future<void> _scanPdf() async {
    // Check premium limit
    final canScan = await _checkScanLimit();
    if (!canScan) return;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _scanningMessage = 'openingPdf';
    });

    try {
      // Pick PDF file
      final pdfFile = await ReceiptScannerService.instance.pickPdf();

      if (pdfFile == null) {
        setState(() => _isScanning = false);
        return;
      }

      setState(() => _scanningMessage = 'processingPdf');

      // Extract text from PDF
      final result = await ReceiptScannerService.instance.extractTextFromPdf(pdfFile);

      if (result == null) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Could not extract text from PDF. The PDF may be image-only or corrupted.';
        });
        return;
      }

      final (extractedText, firstPageImage) = result;

      if (extractedText.isEmpty || firstPageImage == null) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Could not extract text from PDF. Please try with a different file.';
        });
        return;
      }

      // Parse the extracted text
      final receipt = ReceiptScannerService.instance.parseReceiptText(
        extractedText,
        imagePath: firstPageImage.path,
      );

      if (!mounted) return;

      setState(() => _isScanning = false);

      // Show review sheet
      final reviewedReceipt = await ReceiptReviewSheet.show(
        context,
        receipt: receipt,
        imageFile: firstPageImage,
      );

      if (!mounted) return;

      if (reviewedReceipt != null) {
        // Increment scan count on successful scan
        await _incrementScanCount();
        Navigator.pop(context, reviewedReceipt);
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Error scanning PDF: $e';
      });
    }
  }

  Future<void> _scanReceipt(ImageSource source) async {
    final l10n = AppLocalizations.of(context);

    // Check premium limit
    final canScan = await _checkScanLimit();
    if (!canScan) return;

    // Request permission first
    bool hasPermission = false;

    if (source == ImageSource.camera) {
      // Show custom permission dialog for camera
      final shouldRequest = await PermissionService.instance.showPermissionRequestDialog(
        context,
        title: l10n?.cameraAccess ?? 'Camera Access',
        message: l10n?.cameraPermissionMessage ?? 'FlowLedger needs camera access to scan receipts and automatically extract expense details.',
        permissionType: 'camera',
        icon: LucideIcons.camera,
      );

      if (!mounted) return;
      if (shouldRequest) {
        hasPermission = await PermissionService.instance.requestCameraPermission(context);
      }
    } else {
      // Show custom permission dialog for gallery
      final shouldRequest = await PermissionService.instance.showPermissionRequestDialog(
        context,
        title: l10n?.photoLibraryAccess ?? 'Photo Library Access',
        message: l10n?.photoLibraryPermissionMessage ?? 'FlowLedger needs access to your photo library to select receipt images for expense tracking.',
        permissionType: 'photos',
        icon: LucideIcons.image,
      );

      if (!mounted) return;
      if (shouldRequest) {
        hasPermission = await PermissionService.instance.requestPhotoLibraryPermission(context);
      }
    }

    if (!hasPermission || !mounted) {
      return;
    }

    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _scanningMessage = 'scanning';
    });

    try {
      // Pick image
      final imageFile = await ReceiptScannerService.instance.pickImage(source: source);

      if (imageFile == null) {
        setState(() => _isScanning = false);
        return;
      }

      // Extract text using ML Kit
      final extractedText = await ReceiptScannerService.instance.extractText(imageFile);

      if (extractedText.isEmpty) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'Could not extract text from image. Please try again with a clearer image.';
        });
        return;
      }

      // Parse the extracted text
      final receipt = ReceiptScannerService.instance.parseReceiptText(
        extractedText,
        imagePath: imageFile.path,
      );

      if (!mounted) return;

      setState(() => _isScanning = false);

      // Show review sheet while keeping scanner sheet open
      final reviewedReceipt = await ReceiptReviewSheet.show(
        context,
        receipt: receipt,
        imageFile: imageFile,
      );

      if (!mounted) return;

      if (reviewedReceipt != null) {
        // Increment scan count after successful scan
        await _incrementScanCount();
        // Return the reviewed receipt to the parent and close scanner
        if (mounted) Navigator.pop(context, reviewedReceipt);
      }
      // If user cancelled review, they stay on scanner sheet to try again
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Error scanning receipt: $e';
      });
    }
  }

  String _getScanningMessage(AppLocalizations? l10n) {
    switch (_scanningMessage) {
      case 'openingPdf':
        return 'Opening PDF...';
      case 'processingPdf':
        return 'Processing PDF pages...';
      case 'scanning':
      default:
        return l10n?.scanning ?? 'Scanning...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.bottomSheetRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingHorizontal,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    LucideIcons.x,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  l10n?.scanReceipt ?? 'Scan Receipt',
                  style: AppTypography.h4.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(width: 48), // Balance the row
              ],
            ),
          ),

          const Divider(),

          Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPaddingHorizontal),
            child: Column(
              children: [
                // Info text
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacing16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.sparkles,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: AppDimensions.spacing12),
                      Expanded(
                        child: Text(
                          'Take a photo or select an image of your receipt. We\'ll automatically extract items and prices.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.spacing24),

                // Scanning indicator
                if (_isScanning)
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacing32),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing16),
                        Text(
                          _getScanningMessage(l10n),
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n?.analyzingReceipt ?? 'Extracting items and prices',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppDimensions.spacing16),
                      padding: const EdgeInsets.all(AppDimensions.spacing12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.alertCircle,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppDimensions.spacing8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Source options - Camera and Gallery
                  Row(
                    children: [
                      Expanded(
                        child: _SourceOption(
                          icon: LucideIcons.camera,
                          label: l10n?.takePhoto ?? 'Take Photo',
                          description: l10n?.camera ?? 'Camera',
                          isDark: isDark,
                          onTap: () => _scanReceipt(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacing16),
                      Expanded(
                        child: _SourceOption(
                          icon: LucideIcons.image,
                          label: l10n?.gallery ?? 'Gallery',
                          description: l10n?.chooseImage ?? 'Choose image',
                          isDark: isDark,
                          onTap: () => _scanReceipt(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.spacing16),

                  // PDF option
                  _SourceOption(
                    icon: LucideIcons.fileText,
                    label: l10n?.pdfDocument ?? 'PDF Document',
                    description: l10n?.selectPdfReceiptOrBill ?? 'Select a PDF receipt or bill',
                    isDark: isDark,
                    onTap: _scanPdf,
                    isFullWidth: true,
                  ),
                ],

                const SizedBox(height: AppDimensions.spacing24),

                // Tips
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacing12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.tipsForBestResults ?? 'Tips for best results:',
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      _TipItem(
                        text: l10n?.ensureGoodLighting ?? 'Ensure good lighting',
                        isDark: isDark,
                      ),
                      _TipItem(
                        text: l10n?.keepReceiptFlat ?? 'Keep the receipt flat',
                        isDark: isDark,
                      ),
                      _TipItem(
                        text: l10n?.includeEntireReceipt ?? 'Include the entire receipt in frame',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + AppDimensions.spacing16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isDark;
  final VoidCallback onTap;
  final bool isFullWidth;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isDark,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = isFullWidth
        ? Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
                size: 20,
              ),
            ],
          )
        : Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing12),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
            ],
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isFullWidth ? AppDimensions.spacing16 : AppDimensions.spacing20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: content,
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  final bool isDark;

  const _TipItem({
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            LucideIcons.check,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

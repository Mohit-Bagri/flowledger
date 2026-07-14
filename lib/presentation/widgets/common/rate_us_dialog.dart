import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/rating_service.dart';

/// Shows a "Rate Us" prompt dialog.
///
/// Triggered automatically from HomeScreen after [RatingService] conditions are met.
class RateUsDialog extends StatelessWidget {
  const RateUsDialog._();

  /// Display the dialog. Handles all button actions internally.
  static Future<void> show(BuildContext context) async {
    await RatingService.instance.markPromptShown();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RateUsDialog._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF5A524).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.star,
                color: Color(0xFFF5A524),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Enjoying FlowLedger?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Your feedback helps us improve and reach more people. Rate us 5 stars on Google Play!',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Leave feedback button (primary)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _onLeaveFeedback(context),
                icon: const Icon(LucideIcons.heart, size: 16),
                label: const Text('Thanks for using FlowLedger! ⭐'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Ask me later / Don't ask row
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _onAskLater(context),
                    child: Text(
                      'Ask me later',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _onDontAsk(context),
                    child: Text(
                      "Don't ask again",
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onLeaveFeedback(BuildContext context) async {
    Navigator.of(context).pop();
    // Mark as declined so we don't keep asking
    await RatingService.instance.markDeclined();
  }

  void _onAskLater(BuildContext context) {
    // markPromptShown() was already called when dialog was shown,
    // so the 2-day timer resets from now.
    Navigator.of(context).pop();
  }

  Future<void> _onDontAsk(BuildContext context) async {
    Navigator.of(context).pop();
    await RatingService.instance.markDeclined();
  }
}

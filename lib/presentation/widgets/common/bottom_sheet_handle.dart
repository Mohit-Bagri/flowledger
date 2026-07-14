import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Bottom Sheet Handle Widget
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        width: AppDimensions.bottomSheetHandleWidth,
        height: AppDimensions.bottomSheetHandleHeight,
        margin: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        ),
      ),
    );
  }
}

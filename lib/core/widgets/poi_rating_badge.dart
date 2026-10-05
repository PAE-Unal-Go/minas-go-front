import 'package:flutter/material.dart';

import '../theme/app_design_system.dart';

class PoiRatingBadge extends StatelessWidget {
  final double? rating;
  final Color? textColor;

  const PoiRatingBadge({
    super.key,
    required this.rating,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final value = rating;
    if (value == null || value <= 0) {
      return Text(
        'Sin calificar',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: AppTypography.weightMedium,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: AppColors.warning, size: 15),
        const SizedBox(width: 3),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: textColor ?? AppColors.textPrimary,
            fontSize: 12,
            fontWeight: AppTypography.weightSemiBold,
          ),
        ),
      ],
    );
  }
}

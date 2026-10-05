import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_system.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Explora las diferentes categorías',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppTypography.fontSizeLg,
              fontWeight: AppTypography.weightBold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Cada una tiene una ruta con puntos por descubrir',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppTypography.fontSizeXs,
              fontWeight: AppTypography.weightMedium,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

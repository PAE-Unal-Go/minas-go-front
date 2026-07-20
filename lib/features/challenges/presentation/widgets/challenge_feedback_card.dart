import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design_system.dart';

class ChallengeFeedbackCard extends StatelessWidget {
  final bool success;
  final String message;

  const ChallengeFeedbackCard({
    super.key,
    required this.success,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: success
            ? AppColors.secondaryLight.withValues(alpha: 0.22)
            : AppColors.accentLight.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: success ? AppColors.secondaryMain : AppColors.error,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.info_rounded,
            color: success ? AppColors.secondaryDark : AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  success ? '¡Correcto!' : 'Respuesta incorrecta',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.fontSizeSm,
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.fontSizeSm,
                    fontWeight: AppTypography.weightMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

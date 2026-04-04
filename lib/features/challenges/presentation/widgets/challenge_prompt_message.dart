import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design_system.dart';

class ChallengePromptMessage extends StatelessWidget {
  const ChallengePromptMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryMain.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Text(
        'Selecciona una respuesta para ver si es correcta.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppTypography.fontSizeSm,
          fontWeight: AppTypography.weightMedium,
        ),
      ),
    );
  }
}

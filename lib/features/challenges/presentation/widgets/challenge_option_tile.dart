import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design_system.dart';

class ChallengeOptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool selected;
  final bool answered;
  final bool isCorrect;
  final VoidCallback onTap;

  const ChallengeOptionTile({
    super.key,
    required this.label,
    required this.text,
    required this.selected,
    required this.answered,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showCorrect = answered && isCorrect;
    final showIncorrect = answered && selected && !isCorrect;

    final borderColor = showCorrect
        ? AppColors.secondaryMain
        : showIncorrect
            ? AppColors.error
            : AppColors.border;

    final backgroundColor = showCorrect
        ? AppColors.secondaryLight.withValues(alpha: 0.18)
        : showIncorrect
            ? AppColors.accentLight.withValues(alpha: 0.2)
            : AppColors.surface;

    final rightIcon = showCorrect
        ? Icons.check_circle_rounded
        : showIncorrect
            ? Icons.cancel_rounded
            : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
          boxShadow: const [AppShadows.shadowSm],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryMain : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryMain),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.primaryMain,
                  fontWeight: AppTypography.weightBold,
                  fontSize: AppTypography.fontSizeSm,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppTypography.fontSizeSm,
                  fontWeight: AppTypography.weightMedium,
                ),
              ),
            ),
            if (rightIcon != null) ...[
              const SizedBox(width: 10),
              Icon(
                rightIcon,
                color: showCorrect ? AppColors.secondaryDark : AppColors.error,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

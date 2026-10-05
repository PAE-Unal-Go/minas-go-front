import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design_system.dart';
import '../models/challenge_question.dart';

class ChallengeQuestionCard extends StatelessWidget {
  final ChallengeQuestion question;

  const ChallengeQuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryMain.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppTypography.fontSizeLg,
              fontWeight: AppTypography.weightBold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '+${question.rewardPoints} puntos',
                style: const TextStyle(
                  color: AppColors.primaryMain,
                  fontSize: AppTypography.fontSizeSm,
                  fontWeight: AppTypography.weightSemiBold,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.star_rounded,
                color: AppColors.secondaryDark,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

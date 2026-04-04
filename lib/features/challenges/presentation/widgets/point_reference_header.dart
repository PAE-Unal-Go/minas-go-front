import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design_system.dart';
import '../models/challenge_question.dart';

class PointReferenceHeader extends StatelessWidget {
  final ChallengeQuestion question;

  const PointReferenceHeader({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.pointLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppTypography.fontSizeXs,
                    fontWeight: AppTypography.weightMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.pointName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.fontSizeLg,
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipOval(
            child: Image.asset(
              question.pointImage,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

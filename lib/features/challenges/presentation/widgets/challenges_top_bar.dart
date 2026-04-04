import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design_system.dart';
import '../../../home/presentation/widgets/sparkle_star_badge.dart';

class ChallengesTopBar extends StatelessWidget {
  final int points;

  const ChallengesTopBar({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.primaryMain),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Retos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppTypography.fontSizeXl,
                        fontWeight: AppTypography.weightBold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Tus puntos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppTypography.fontSizeMd,
                            fontWeight: AppTypography.weightMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SparkleStarBadge(),
                        const SizedBox(width: 8),
                        Text(
                          '$points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppTypography.fontSizeMd,
                            fontWeight: AppTypography.weightMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

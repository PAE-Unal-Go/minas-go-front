import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design_system.dart';
import '../models/challenge_question.dart';

class PointReferenceHeader extends StatelessWidget {
  final ChallengeQuestion question;

  const PointReferenceHeader({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final imageUrl = question.pointImage;

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
            child: SizedBox(
              width: 56,
              height: 56,
              child: _buildImage(imageUrl),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 26,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

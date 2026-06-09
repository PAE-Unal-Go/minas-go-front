import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design_system.dart';

class UnlockProgressCard extends StatelessWidget {
  final int visitCount;
  final int unlockedCount;

  const UnlockProgressCard({
    super.key,
    required this.visitCount,
    required this.unlockedCount,
  });

  static const int _poisPerMilestone = 5;

  int get _progressInCycle => visitCount % _poisPerMilestone;
  int get _poisUntilNext => _poisPerMilestone - _progressInCycle;
  bool get _isAtMilestone => _progressInCycle == 0 && visitCount > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [AppShadows.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryMain.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  color: AppColors.secondaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  _isAtMilestone
                      ? '¡Desbloquea el siguiente dato!'
                      : 'Próximo dato en $_poisUntilNext ${_poisUntilNext == 1 ? 'POI' : 'POIs'} más',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.fontSizeSm,
                    fontWeight: AppTypography.weightSemiBold,
                  ),
                ),
              ),
              Text(
                '$_progressInCycle/$_poisPerMilestone',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppTypography.fontSizeXs,
                  fontWeight: AppTypography.weightMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: _isAtMilestone
                    ? 1.0
                    : _progressInCycle / _poisPerMilestone,
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.secondaryDark,
                ),
              ),
            ),
          ),
          if (unlockedCount > 0) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              '$unlockedCount ${unlockedCount == 1 ? 'dato desbloqueado' : 'datos desbloqueados'}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppTypography.fontSizeXs,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

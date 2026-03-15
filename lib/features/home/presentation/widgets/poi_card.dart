import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_system.dart';

class PoiCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final int unlockedPoints;
  final int totalPoints;
  final Color surfaceColor;
  final Color borderColor;
  final Color progressColor;
  final Color textColor;
  final VoidCallback? onTap;

  const PoiCard({
    super.key,
    required this.name,
    this.imageUrl,
    required this.unlockedPoints,
    required this.totalPoints,
    required this.surfaceColor,
    required this.borderColor,
    required this.progressColor,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double progress =
        totalPoints == 0 ? 0 : (unlockedPoints / totalPoints).clamp(0, 1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
            boxShadow: [
              AppShadows.shadowSm,
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Keep visual proportions while adapting to tight grid heights.
                final double imageHeight = (constraints.maxHeight * 0.72).clamp(
                  120.0,
                  180.0,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: _buildBackground(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s3,
                          10,
                          AppSpacing.s3,
                          10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: AppTypography.fontSizeMd,
                                fontWeight: AppTypography.weightBold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s2),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.s1),
                              child: SizedBox(
                                height: 7,
                                child: Stack(
                                  children: [
                                    Container(color: borderColor),
                                    FractionallySizedBox(
                                      widthFactor: progress,
                                      child: Container(color: progressColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.startsWith('http')) {
        return Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }

      return Image.asset(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
      ),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 42,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

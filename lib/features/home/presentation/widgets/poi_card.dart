import 'package:cached_network_image/cached_network_image.dart';
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
                          8,
                          AppSpacing.s3,
                          8,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.s1),
                              child: const SizedBox(
                                height: 7,
                              ),
                            ),
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
        return CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildShimmer(),
          errorWidget: (_, __, ___) => _buildPlaceholder(),
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

  Widget _buildShimmer() {
    return const _ShimmerPlaceholder();
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

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder();
  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              Color(0xFFDDE0E8),
              Color(0xFFF0F3FA),
              Color(0xFFDDE0E8),
            ],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

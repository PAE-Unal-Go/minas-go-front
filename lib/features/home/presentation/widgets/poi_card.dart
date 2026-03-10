import 'package:flutter/material.dart';

class PoiCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final int unlockedPoints;
  final int totalPoints;
  final Color surfaceColor;
  final Color borderColor;
  final Color progressColor;
  final Color textColor;
  final Color subtitleColor;
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
    required this.subtitleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalPoints == 0
        ? 0
        : (unlockedPoints / totalPoints).clamp(0, 1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F1430).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Keep visual proportions while adapting to tight grid heights.
                final double imageHeight = (constraints.maxHeight * 0.58).clamp(
                  90.0,
                  120.0,
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
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$unlockedPoints/$totalPoints puntos desbloqueados',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A34D6), Color(0xFF171C8F)],
        ),
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

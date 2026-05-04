import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_design_system.dart';
import 'sparkle_star_badge.dart';

class HomeHeader extends StatelessWidget {
  final String firstName;
  final String userName;
  final String? userAvatar;
  final int burnedPoints;
  final VoidCallback onLogout;

  const HomeHeader({
    super.key,
    required this.firstName,
    required this.userName,
    required this.userAvatar,
    required this.burnedPoints,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 14, 26, 26),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryLight,
              boxShadow: [
                AppShadows.shadowSm,
              ],
            ),
            child: ClipOval(
              child: userAvatar != null
                  ? CachedNetworkImage(
                      imageUrl: userAvatar!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _buildAvatarFallback(),
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  : _buildAvatarFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $firstName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.fontSizeLg,
                    fontWeight: AppTypography.weightBold,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SparkleStarBadge(),
                    const SizedBox(width: 8),
                    Text(
                      '$burnedPoints puntos',
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
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: AppColors.secondaryLight,
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTypography.fontSizeLg,
            fontWeight: AppTypography.weightBold,
          ),
        ),
      ),
    );
  }
}

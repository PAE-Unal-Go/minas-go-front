import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_system.dart';
import '../widgets/explore_fab.dart';
import '../../../map/domain/entities/punto_de_interes.dart';
import 'poi_detail_view.dart';

class CategoryPointsView extends StatelessWidget {
  final String categoryName;
  final String categoryDescription;
  final String? categoryImageUrl;
  final List<PuntoDeInteres> puntos;

  const CategoryPointsView({
    super.key,
    required this.categoryName,
    required this.categoryDescription,
    required this.puntos,
    this.categoryImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final discoveredCount = puntos.where((p) => p.visitado).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: const BoxDecoration(gradient: AppGradients.primary),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      categoryName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: AppTypography.weightBold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.secondaryMain.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryDescription,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: AppTypography.weightMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Descubiertos: $discoveredCount/${puntos.length}',
                      style: const TextStyle(
                        color: AppColors.secondaryDark,
                        fontSize: 13,
                        fontWeight: AppTypography.weightBold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: puntos.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay puntos configurados para esta categoría.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: AppTypography.weightSemiBold,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
                      itemCount: puntos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final punto = puntos[index];
                        return _PointTile(
                          punto: punto,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PoiDetailView(
                                  categoryName: categoryName,
                                  pointName: punto.nombre,
                                  pointDescription: punto.descripcion ?? '',
                                  imageUrl: punto.mainImageUrl,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const ExploreFab(),
    );
  }
}

class _PointTile extends StatelessWidget {
  final PuntoDeInteres punto;
  final VoidCallback onTap;

  const _PointTile({required this.punto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: 1.4),
            boxShadow: const [AppShadows.shadowSm],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: _PointImage(url: punto.mainImageUrl),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      punto.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppTypography.fontSizeMd,
                        fontWeight: AppTypography.weightBold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      punto.campus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppTypography.fontSizeXs,
                        fontWeight: AppTypography.weightMedium,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          punto.visitado
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: punto.visitado
                              ? AppColors.stateAvailable
                              : AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          punto.visitado ? 'Descubierto' : 'No descubierto',
                          style: TextStyle(
                            color: punto.visitado
                                ? AppColors.stateAvailable
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: AppTypography.weightBold,
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

class _PointImage extends StatelessWidget {
  final String? url;
  const _PointImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
        child: url!.startsWith('http')
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : Image.asset(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
      ),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.white),
      ),
    );
  }
}

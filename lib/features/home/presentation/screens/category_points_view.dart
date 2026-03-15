import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_system.dart';
import '../widgets/explore_fab.dart';
import '../../../map/domain/entities/punto_de_interes.dart';
import 'poi_detail_view.dart';

class CategoryPointsView extends StatefulWidget {
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
  State<CategoryPointsView> createState() => _CategoryPointsViewState();
}

class _CategoryPointsViewState extends State<CategoryPointsView> {
  static const double _collapseThreshold = 16;
  bool _isSummaryCollapsed = false;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final shouldCollapse = notification.metrics.pixels > _collapseThreshold;
    if (shouldCollapse != _isSummaryCollapsed) {
      setState(() {
        _isSummaryCollapsed = shouldCollapse;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final discoveredCount = widget.puntos.where((p) => p.visitado).length;
    final progress =
        widget.puntos.isEmpty ? 0.0 : discoveredCount / widget.puntos.length;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.primaryMain,
      body: Column(
        children: [
          _buildHeader(context, progress, topInset),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: _isSummaryCollapsed ? 4 : 44,
          ),
          Expanded(
            child: widget.puntos.isEmpty
                ? Center(
                    child: Text(
                      'No hay puntos configurados para esta categoría.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTypography.fontSizeSm,
                        fontWeight: AppTypography.weightSemiBold,
                      ),
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: _onScrollNotification,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.86,
                      ),
                      itemCount: widget.puntos.length,
                      itemBuilder: (context, index) {
                        final punto = widget.puntos[index];
                        return _PointGridTile(
                          punto: punto,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PoiDetailView(
                                  categoryName: widget.categoryName,
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
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const ExploreFab(),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double progress,
    double topInset,
  ) {
    return SizedBox(
      height: 320 + topInset,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _buildHeaderBackground()),
          Positioned(
            top: topInset + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    widget.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: AppTypography.weightBold,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            left: 12,
            right: 12,
            bottom: _isSummaryCollapsed ? 78 : -28,
            child: _buildSummaryCard(progress, _isSummaryCollapsed),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: Transform.scale(
            scale: 1.02,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: _buildHeaderImage(),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.20),
                Colors.black.withValues(alpha: 0.35),
                AppColors.primaryMain,
                AppColors.primaryMain,
              ],
              stops: const [0.0, 0.55, 0.9, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderImage() {
    if (widget.categoryImageUrl != null &&
        widget.categoryImageUrl!.isNotEmpty) {
      if (widget.categoryImageUrl!.startsWith('http')) {
        return Image.network(
          widget.categoryImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildHeaderPlaceholder(),
        );
      }
      return Image.asset(
        widget.categoryImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildHeaderPlaceholder(),
      );
    }
    return _buildHeaderPlaceholder();
  }

  Widget _buildHeaderPlaceholder() {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.exploration),
    );
  }

  Widget _buildSummaryCard(double progress, bool isCollapsed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(20, isCollapsed ? 12 : 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1F0F172A),
            blurRadius: 22,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isCollapsed
                ? const SizedBox.shrink()
                : Text(
                    widget.categoryDescription,
                    key: const ValueKey('summary-description'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppTypography.fontSizeXs,
                      fontWeight: AppTypography.weightMedium,
                      height: 1.35,
                    ),
                  ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isCollapsed
                ? const SizedBox.shrink()
                : const SizedBox(
                    key: ValueKey('summary-spacing'),
                    height: 8,
                  ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: AppTypography.weightMedium,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 14,
              child: Stack(
                children: [
                  Container(color: AppColors.stateLocked),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(color: AppColors.stateAvailable),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isCollapsed ? 10 : 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendDot(color: AppColors.stateAvailable, label: 'Descubierto'),
              SizedBox(width: 36),
              _LegendDot(color: AppColors.stateLocked, label: 'Bloqueado'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [AppShadows.shadowSm],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTypography.fontSizeXs,
            fontWeight: AppTypography.weightMedium,
          ),
        ),
      ],
    );
  }
}

class _PointGridTile extends StatelessWidget {
  final PuntoDeInteres punto;
  final VoidCallback onTap;

  const _PointGridTile({required this.punto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: const [AppShadows.shadowSm],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
                child: SizedBox(
                  height: 88,
                  width: double.infinity,
                  child: _PointImage(url: punto.mainImageUrl),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Text(
                    punto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: AppTypography.weightMedium,
                      height: 1.2,
                    ),
                  ),
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
      return url!.startsWith('http')
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : Image.asset(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
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

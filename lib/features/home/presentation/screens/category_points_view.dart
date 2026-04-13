import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_system.dart';
import '../../../../core/widgets/poi_image_gallery.dart';
import '../../../../core/utils/poi_rarity.dart';
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
                        childAspectRatio: 0.80,
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
                                  punto: punto,
                                  categoryName: widget.categoryName,
                                  pointName: punto.nombre,
                                  pointDescription: punto.descripcion ?? '',
                                  imagesUrls: punto.imagesUrls,
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
            left: 4,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 22,
                  tooltip: 'Volver',
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
            child: _buildSummaryCard(
              progress,
              _isSummaryCollapsed,
              '${widget.puntos.where((p) => p.visitado).length}/${widget.puntos.length}',
            ),
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
        return CachedNetworkImage(
          imageUrl: widget.categoryImageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildHeaderPlaceholder(),
          errorWidget: (_, __, ___) => _buildHeaderPlaceholder(),
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

  Widget _buildSummaryCard(
    double progress,
    bool isCollapsed,
    String progressLabel,
  ) {
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
              progressLabel,
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

// ─── Grid tile with static rarity distinction ────────────────────────────────

class _PointGridTile extends StatelessWidget {
  final PuntoDeInteres punto;
  final VoidCallback onTap;

  const _PointGridTile({required this.punto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rarity = punto.visitado ? punto.rarity : null;
    return _wrapBorder(
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _imageSection(rarity),
                _nameSection(rarity),
              ],
            ),
          ),
        ),
      ),
      rarity,
    );
  }

  // ── Border wrapper ───────────────────────────────────────────────────────

  Widget _wrapBorder(Widget child, String? rarity) {
    return switch (rarity?.toLowerCase()) {
      PoiRarity.basic => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md + 1.5),
            color: const Color(0xFF2DD4BF),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2DD4BF).withValues(alpha: 0.40),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          child: child,
        ),
      PoiRarity.important => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md + 1.5),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF92400E),
                Color(0xFFF59E0B),
                Color(0xFFFEF08A),
                Color(0xFFF59E0B),
                Color(0xFF92400E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          child: child,
        ),
      PoiRarity.legendary => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF6B6B),
                Color(0xFFE879F9),
                Color(0xFF4D96FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE879F9).withValues(alpha: 0.40),
                blurRadius: 12,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0xFF4D96FF).withValues(alpha: 0.20),
                blurRadius: 18,
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: child,
        ),
      _ => Container(
          decoration: const BoxDecoration(
            borderRadius:
                BorderRadius.all(Radius.circular(AppRadius.md)),
            boxShadow: [AppShadows.shadowSm],
          ),
          child: child,
        ),
    };
  }

  // ── Image section ─────────────────────────────────────────────────────────

  Widget _imageSection(String? rarity) {
    return SizedBox(
      height: 78,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PointImage(urls: punto.imagesUrls),
          if (rarity != null)
            Positioned(
              left: 5,
              bottom: 5,
              child: _rarityBadge(rarity),
            ),
        ],
      ),
    );
  }

  Widget _rarityBadge(String rarity) {
    final color = PoiRarity.primaryColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.85), width: 1),
      ),
      child: Text(
        PoiRarity.symbol(rarity),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Name section ──────────────────────────────────────────────────────────

  Widget _nameSection(String? rarity) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
        child: Text(
          punto.nombre,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: rarity != null
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: rarity != null
                ? AppTypography.weightSemiBold
                : AppTypography.weightMedium,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

// ─── Point image helper ───────────────────────────────────────────────────────

class _PointImage extends StatelessWidget {
  final List<String> urls;
  const _PointImage({required this.urls});

  @override
  Widget build(BuildContext context) {
    return PoiImageGallery(
      imagesUrls: urls,
      height: 78,
      showIndicators: false,
      enableCarousel: false,
      borderRadius: BorderRadius.zero,
    );
  }
}

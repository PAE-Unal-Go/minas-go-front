import 'package:flutter/material.dart';

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

  static const Color _neutralBackground = Color(0xFFE7E8EE);
  static const Color _neutralSurface = Color(0xFFF7F8FB);
  static const Color _primaryMain = Color(0xFF171C8F);
  static const Color _primaryDark = Color(0xFF10156D);
  static const Color _secondaryMain = Color(0xFF37C8BE);
  static const Color _secondaryDark = Color(0xFF25B7AB);
  static const Color _neutralTextSecondary = Color(0xFF6A7587);

  @override
  Widget build(BuildContext context) {
    final discoveredCount = puntos.where((p) => p.visitado).length;

    return Scaffold(
      backgroundColor: _neutralBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primaryMain, _primaryDark],
                ),
              ),
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
                        fontWeight: FontWeight.w700,
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
                  color: _neutralSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _secondaryMain.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryDescription,
                      style: const TextStyle(
                        color: _neutralTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Descubiertos: $discoveredCount/${puntos.length}',
                      style: const TextStyle(
                        color: _secondaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
                          color: _neutralTextSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

  static const Color _secondaryMain = Color(0xFF37C8BE);
  static const Color _neutralSurface = Color(0xFFF7F8FB);
  static const Color _neutralBorder = Color(0xFF091436);
  static const Color _neutralTextPrimary = Color(0xFF091436);
  static const Color _neutralTextSecondary = Color(0xFF6A7587);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _neutralSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _neutralBorder, width: 1.4),
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
                        color: _neutralTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      punto.campus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _neutralTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
                          color: punto.visitado ? _secondaryMain : _neutralTextSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          punto.visitado ? 'Descubierto' : 'No descubierto',
                          style: TextStyle(
                            color: punto.visitado ? _secondaryMain : _neutralTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A34D6), Color(0xFF171C8F)],
        ),
      ),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.white),
      ),
    );
  }
}

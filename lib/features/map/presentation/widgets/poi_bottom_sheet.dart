import 'package:flutter/material.dart';
import '../../../../core/widgets/poi_image_gallery.dart';
import '../../domain/entities/punto_de_interes.dart';
import '../../domain/entities/categoria.dart';
import '../../../../core/theme/app_design_system.dart';
import '../../../home/presentation/screens/poi_detail_view.dart';

const double proximityThresholdMeters = 8.0;

class PoiBottomSheet extends StatefulWidget {
  final PuntoDeInteres punto;
  final double distanceMeters;
  final Future<void> Function() onUnlock;

  const PoiBottomSheet({
    super.key,
    required this.punto,
    required this.distanceMeters,
    required this.onUnlock,
  });

  @override
  State<PoiBottomSheet> createState() => _PoiBottomSheetState();
}

class _PoiBottomSheetState extends State<PoiBottomSheet> {
  bool _isUnlocking = false;

  bool get _inRange => widget.distanceMeters <= proximityThresholdMeters;

  String _formatDistance(double meters) {
    if (meters == double.infinity) return '— m';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _triggerUnlock() async {
    if (_isUnlocking) return;
    setState(() => _isUnlocking = true);
    await widget.onUnlock();
    if (mounted) setState(() => _isUnlocking = false);
  }

  @override
  Widget build(BuildContext context) {
    final punto = widget.punto;
    final isVisitado = punto.visitado;
    final locked = !isVisitado && !_inRange;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          if (!locked) ...[
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
          ],

          // ── Image ──
          _PoiImageSection(
            punto: punto,
            isVisitado: isVisitado,
            locked: locked,
          ),

          // ── Info ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PoiMetaRow(
                  punto: punto,
                  isVisitado: isVisitado,
                  inRange: _inRange,
                  distanceLabel: _formatDistance(widget.distanceMeters),
                ),
                const SizedBox(height: 8),

                // Name
                Text(
                  punto.nombre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                // Description – only if visited
                if (isVisitado &&
                    punto.descripcion != null &&
                    punto.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    punto.descripcion!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Action button ──
                if (!isVisitado)
                  _UnlockButton(
                    inRange: _inRange,
                    isUnlocking: _isUnlocking,
                    onUnlock: _triggerUnlock,
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Import correct file in headers if not present
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PoiDetailView(
                              punto: punto,
                              categoryName: Categoria.humanNombre(punto.categoria),
                              pointName: punto.nombre,
                              pointDescription: punto.descripcion ?? '',
                              imagesUrls: punto.imagesUrls,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryLight,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Ver detalles', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PoiImageSection extends StatelessWidget {
  final PuntoDeInteres punto;
  final bool isVisitado;
  final bool locked;

  const _PoiImageSection({
    required this.punto,
    required this.isVisitado,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    const blockedGrayMatrix = [
      0.2126,
      0.7152,
      0.0722,
      0.0,
      0.0,
      0.2126,
      0.7152,
      0.0722,
      0.0,
      0.0,
      0.2126,
      0.7152,
      0.0722,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
    ];

    return Stack(
      children: [
        SizedBox(
          height: 190,
          width: double.infinity,
          child: ColorFiltered(
            colorFilter: isVisitado
                ? const ColorFilter.matrix(<double>[
                    1, 0, 0, 0, 0,
                    0, 1, 0, 0, 0,
                    0, 0, 1, 0, 0,
                    0, 0, 0, 1, 0,
                  ])
                : const ColorFilter.matrix(blockedGrayMatrix),
            child: PoiImageGallery(
              imagesUrls: punto.imagesUrls,
              height: 190,
              borderRadius: locked
                  ? const BorderRadius.vertical(top: Radius.circular(28))
                  : BorderRadius.zero,
              locked: locked,
            ),
          ),
        ),
        if (locked)
          const Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, color: Colors.white70, size: 42),
                  SizedBox(height: 6),
                  Text(
                    'Acércate al lugar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isVisitado)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.secondaryMain,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Visitado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PoiMetaRow extends StatelessWidget {
  final PuntoDeInteres punto;
  final bool isVisitado;
  final bool inRange;
  final String distanceLabel;

  const _PoiMetaRow({
    required this.punto,
    required this.isVisitado,
    required this.inRange,
    required this.distanceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.secondaryMain.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            Categoria.humanNombre(punto.categoria),
            style: const TextStyle(
              color: AppColors.secondaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        if (!isVisitado)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                inRange ? Icons.sensors_rounded : Icons.near_me_rounded,
                size: 13,
                color: inRange ? AppColors.success : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                inRange ? '¡En rango!' : distanceLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: inRange ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _UnlockButton extends StatelessWidget {
  final bool inRange;
  final bool isUnlocking;
  final VoidCallback onUnlock;

  const _UnlockButton({
    required this.inRange,
    required this.isUnlocking,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    if (inRange) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isUnlocking ? null : onUnlock,
          icon: isUnlocking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.lock_open_rounded, size: 18),
          label: Text(isUnlocking ? 'Desbloqueando...' : 'Desbloquear'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMain,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            elevation: 0,
          ),
        ),
      );
    }

    // Out of range – locked state
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.disabled.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.disabled),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_rounded,
              size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            'Debes estar más cerca',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/usecases/get_user_location.dart';
import '../../domain/usecases/get_puntos_con_visita.dart';
import '../../domain/usecases/get_categorias.dart';
import '../../domain/usecases/unlock_poi.dart';
import '../../domain/entities/punto_de_interes.dart';
import '../../domain/entities/categoria.dart';
import 'package:minasgo_frontend/features/map/domain/entities/location_point.dart';
import 'package:minasgo_frontend/features/map/data/repositories/map_repository_impl.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:minasgo_frontend/core/services/proximity_service.dart';
import '../widgets/poi_unlock_card.dart';
import '../../../../core/theme/app_design_system.dart';

/// Proximity threshold in meters. Adjust for testing.
const double _proximityThresholdMeters = 40.0;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  LocationPoint? userLocation;
  bool isLoading = true;

  String? _selectedCategoria;
  List<Categoria> _categorias = [];
  List<PuntoDeInteres> get _puntos {
    final all = ProximityService().allPuntos;
    if (_selectedCategoria == null) return all;
    return all.where((p) => p.categoria == _selectedCategoria).toList();
  }

  final _repo = MapRepositoryImpl();
  late final UnlockPoi _unlockPoi;

  late final AudioPlayer _audioPlayer;
  AnimationController? _pulseController;
  Timer? _vibrationTimer;
  bool _isNearAnyUnvisited = false;

  @override
  void initState() {
    super.initState();
    _unlockPoi = UnlockPoi(_repo);
    _initData();
    _audioPlayer = AudioPlayer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
        if (_isNearAnyUnvisited) _updatePulseLayer();
      });
    _pulseController!.repeat(reverse: true);

    // Listen to global proximity service
    ProximityService().addListener(_onProximityUpdate);
  }

  void _onProximityUpdate() {
    final pos = ProximityService().currentPosition;
    if (pos != null && mounted) {
      setState(() {
        userLocation = LocationPoint(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        
        bool isNear = _puntos.any((p) => !p.visitado && _distanceTo(p) <= _proximityThresholdMeters);
        if (isNear != _isNearAnyUnvisited) {
          _isNearAnyUnvisited = isNear;
          if (_isNearAnyUnvisited) {
            _startProximityVibration();
          } else {
            _vibrationTimer?.cancel();
            _resetPulseLayer();
          }
        }
      });
      
      // If the number of points changed (e.g. after refresh), reload markers
      // Actually we just reload to be safe and reactive
      if (_mapboxMap != null) _loadCircleLayer();
    }
  }

  void _updatePulseLayer() async {
    if (_mapboxMap == null || !_isNearAnyUnvisited) return;
    try {
      // Create a breathing effect by oscillating the stroke width and radius slightly.
      // We use the AnimationController value (0.0 to 1.0)
      final pulse = _pulseController!.value;
      final radius = 14.0 + (pulse * 4.0); // 14 to 18
      final stroke = 2.5 + (pulse * 1.5); // 2.5 to 4.0

      await _mapboxMap?.style.setStyleLayerProperty(
        'puntos-circles',
        'circle-radius',
        json.encode(radius),
      );
      await _mapboxMap?.style.setStyleLayerProperty(
        'puntos-circles',
        'circle-stroke-width',
        json.encode(stroke),
      );
    } catch (_) {}
  }

  void _startProximityVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
      if (!_isNearAnyUnvisited) {
        timer.cancel();
        return;
      }
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 100, 200, 100]); // Soft intermittent pulse
      }
    });
  }

  @override
  void dispose() {
    ProximityService().removeListener(_onProximityUpdate);
    _vibrationTimer?.cancel();
    _audioPlayer.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final cats = await _repo.getCategorias(userId);

      if (mounted) {
        setState(() {
          _categorias = cats;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// No longer needed here as it's handled by ProximityService
  void _startLocationStream() {}

  void _resetPulseLayer() async {
    try {
      await _mapboxMap?.style.setStyleLayerProperty('puntos-circles', 'circle-radius', json.encode(14.0));
      await _mapboxMap?.style.setStyleLayerProperty('puntos-circles', 'circle-stroke-width', json.encode(2.5));
    } catch (_) {}
  }

  /// Returns the distance in meters between the user and [punto].
  /// Returns `double.infinity` if user location is unknown.
  double _distanceTo(PuntoDeInteres punto) {
    if (userLocation == null) return double.infinity;
    return geo.Geolocator.distanceBetween(
      userLocation!.latitude,
      userLocation!.longitude,
      punto.latitud,
      punto.longitud,
    );
  }

  // ──────────────────────────── Map events ────────────────────────────

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    mapboxMap.location.updateSettings(LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
    ));
    _centerMap();
  }

  void _onStyleLoaded(StyleLoadedEventData _) => _loadCircleLayer();

  List<PuntoDeInteres> get _filteredPuntos {
    if (_selectedCategoria == null) return _puntos;
    return _puntos.where((p) => p.categoria == _selectedCategoria).toList();
  }

  Future<void> _loadCircleLayer() async {
    if (_mapboxMap == null) return;
    try {
      try { await _mapboxMap!.style.removeStyleLayer('puntos-circles'); } catch (_) {}
      try { await _mapboxMap!.style.removeStyleSource('puntos'); } catch (_) {}

      final features = _filteredPuntos.map((p) => {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [p.longitud, p.latitud],
        },
        "properties": {
          "id": p.id,
          "nombre": p.nombre,
          "categoria": p.categoria,
          "mainImageUrl": p.mainImageUrl ?? '',
          "visitado": p.visitado,
        }
      }).toList();

      final geojson = json.encode({
        "type": "FeatureCollection",
        "features": features,
      });

      await _mapboxMap!.style.addSource(
        GeoJsonSource(id: "puntos", data: geojson),
      );

      final circleLayer = {
        "id": "puntos-circles",
        "type": "circle",
        "source": "puntos",
        "paint": {
          "circle-radius": 14,
          "circle-color": [
            "case",
            ["get", "visitado"],
            "#2DD4BF",   // visited = teal (AppColors.secondaryMain)
            "#1C2AD8",   // not visited = blue
          ],
          "circle-stroke-color": "#FFFFFF",
          "circle-stroke-width": 2.5,
          "circle-opacity": 0.95,
        }
      };
      await _mapboxMap!.style.addStyleLayer(json.encode(circleLayer), null);
    } catch (e) {
      debugPrint('Error loading circle layer: $e');
    }
  }

  void _onMapTap(MapContentGestureContext context) async {
    if (_mapboxMap == null) return;
    try {
      final features = await _mapboxMap!.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(context.touchPosition),
        RenderedQueryOptions(layerIds: ['puntos-circles']),
      );

      if (features.isNotEmpty) {
        final propsRaw = features.first?.queriedFeature.feature['properties'];
        if (propsRaw == null) return;
        final props = propsRaw as Map<Object?, Object?>;
        final id = (props['id'] as num?)?.toInt();
        if (id == null || _puntos.isEmpty) return;

        final punto = _puntos.firstWhere(
          (p) => p.id == id,
          orElse: () => _puntos.first,
        );
        _showPoiBottomSheet(punto);
      }
    } catch (e) {
      debugPrint('Error on map tap: $e');
    }
  }

  void _showPoiBottomSheet(PuntoDeInteres punto) {
    final distance = _distanceTo(punto);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PoiBottomSheet(
        punto: punto,
        distanceMeters: distance,
        onUnlock: () => _handleUnlock(punto),
      ),
    );
  }

  Future<void> _handleUnlock(PuntoDeInteres punto) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Dismiss bottom sheet
    if (mounted) Navigator.of(context).pop();

    try {
      // 1. Play "ping" and vibrate strong
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500);
      }
      await _unlockPoi(userId, punto.id);
      
      // Refresh global proximity service to notify other screens (like Home)
      await ProximityService().refreshPuntos();

      // Markers will update automatically thanks to the listener to ProximityService


      // Show unlock card overlay
      if (mounted) {
        await Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => PoiUnlockCard(
              punto: _puntos.firstWhere((p) => p.id == punto.id),
              onClose: () => Navigator.of(context).pop(),
            ),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al desbloquear: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _centerMap() {
    if (_mapboxMap != null && userLocation != null) {
      _mapboxMap!.setCamera(CameraOptions(
        center: Point(
          coordinates: Position(userLocation!.longitude, userLocation!.latitude),
        ),
        zoom: 15.5,
      ));
    }
  }

  Future<void> _onCategoryChanged(String? key) async {
    setState(() => _selectedCategoria = key);
    if (_mapboxMap != null) await _loadCircleLayer();
  }

  // ──────────────────────────── Build ────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Explorar'),
        backgroundColor: AppColors.primaryMain.withValues(alpha: 0.9),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isLoading) _buildCategoryDropdown(),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : MapWidget(
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: _onStyleLoaded,
              onTapListener: _onMapTap,
              cameraOptions: CameraOptions(
                center: userLocation != null
                    ? Point(
                        coordinates: Position(
                          userLocation!.longitude,
                          userLocation!.latitude,
                        ),
                      )
                    : Point(coordinates: Position(-75.589, 6.273)),
                zoom: 15.0,
              ),
              styleUri: MapboxStyles.MAPBOX_STREETS,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerMap,
        backgroundColor: AppColors.primaryMain,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem(value: null, child: Text('Todas')),
      ..._categorias.map((c) =>
          DropdownMenuItem(value: c.key, child: Text(c.nombre))),
    ];

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedCategoria,
          dropdownColor: AppColors.primaryMain,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          iconEnabledColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: _onCategoryChanged,
        ),
      ),
    );
  }
}

// ──────────────────────────── Bottom Sheet ────────────────────────────

class _PoiBottomSheet extends StatefulWidget {
  final PuntoDeInteres punto;
  final double distanceMeters;
  final Future<void> Function() onUnlock;

  const _PoiBottomSheet({
    required this.punto,
    required this.distanceMeters,
    required this.onUnlock,
  });

  @override
  State<_PoiBottomSheet> createState() => _PoiBottomSheetState();
}

class _PoiBottomSheetState extends State<_PoiBottomSheet> {
  bool _isUnlocking = false;

  bool get _inRange =>
      widget.distanceMeters <= _proximityThresholdMeters;

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
    final hasImage = punto.mainImageUrl != null && punto.mainImageUrl!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
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

          // ── Image ──
          Stack(
            children: [
              SizedBox(
                height: 190,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: hasImage
                      ? Image.network(
                          punto.mainImageUrl!,
                          fit: BoxFit.cover,
                          color: (!isVisitado && !_inRange)
                              ? Colors.black.withValues(alpha: 0.55)
                              : null,
                          colorBlendMode: BlendMode.darken,
                          errorBuilder: (_, __, ___) => _placeholder(locked: !isVisitado && !_inRange),
                        )
                      : _placeholder(locked: !isVisitado && !_inRange),
                ),
              ),
              // Locked overlay icon
              if (!isVisitado && !_inRange)
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
              // Visited badge
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
          ),

          // ── Info ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + distance row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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
                    // Distance indicator
                    if (!isVisitado)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _inRange
                                ? Icons.sensors_rounded
                                : Icons.near_me_rounded,
                            size: 13,
                            color: _inRange
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _inRange
                                ? '¡En rango!'
                                : _formatDistance(widget.distanceMeters),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _inRange
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
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
                const SizedBox(height: 3),
                Text(
                  '${punto.campus} · ${punto.universidad}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),

                // Description (only if visited or in range)
                if ((isVisitado || _inRange) &&
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
                if (!isVisitado) ...[
                  _inRange
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isUnlocking ? null : _triggerUnlock,
                            icon: _isUnlocking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.lock_open_rounded,
                                    size: 18),
                            label: Text(
                              _isUnlocking ? 'Desbloqueando...' : 'Desbloquear',
                            ),
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
                        )
                      : Container(
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
                                'Debes estar a ${_proximityThresholdMeters.toInt()} m',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder({bool locked = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: locked
              ? [const Color(0xFF64748B), const Color(0xFF334155)]
              : [AppColors.primaryMain, AppColors.secondaryMain],
        ),
      ),
      child: Center(
        child: Icon(
          locked ? Icons.lock_rounded : Icons.place_rounded,
          color: Colors.white54,
          size: 48,
        ),
      ),
    );
  }
}

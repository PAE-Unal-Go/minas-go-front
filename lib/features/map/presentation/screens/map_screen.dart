import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../domain/usecases/unlock_poi.dart';
import '../../domain/entities/punto_de_interes.dart';
import '../../domain/entities/categoria.dart';
import 'package:minasgo_frontend/features/map/domain/entities/location_point.dart';
import 'package:minasgo_frontend/features/map/data/repositories/map_repository_impl.dart';
import 'package:minasgo_frontend/core/services/proximity_service.dart';
import '../widgets/poi_bottom_sheet.dart';
import '../widgets/poi_unlock_card.dart';
import '../widgets/category_dropdown.dart';
import '../widgets/map_icon_loader.dart';
import '../widgets/map_layer_helper.dart';
import '../../../../core/theme/app_design_system.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ── Map ──
  MapboxMap? _mapboxMap;
  LocationPoint? _userLocation;
  bool _isLoading = true;

  // ── Data ──
  String? _selectedCategoria;
  List<Categoria> _categorias = [];

  List<PuntoDeInteres> get _puntos {
    final all = ProximityService().allPuntos;
    if (_selectedCategoria == null) return all;
    return all.where((p) => p.categoria == _selectedCategoria).toList();
  }

  // ── Services ──
  final _repo = MapRepositoryImpl();
  late final UnlockPoi _unlockPoi;

  // ── Proximity feedback ──
  late final AudioPlayer _audioPlayer;
  AnimationController? _pulseController;
  Timer? _vibrationTimer;
  bool _isNearAnyUnvisited = false;
  bool _hasCenteredOnUser = false;

  // ─────────────────────────────── Lifecycle ───────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unlockPoi = UnlockPoi(_repo);
    _audioPlayer = AudioPlayer();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
        if (_isNearAnyUnvisited) _updatePulseLayer();
      });
    _pulseController!.repeat(reverse: true);

    ProximityService().addListener(_onProximityUpdate);
    _initData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ProximityService().removeListener(_onProximityUpdate);
    _vibrationTimer?.cancel();
    _audioPlayer.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _vibrationTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_isNearAnyUnvisited) {
        _startProximityVibration();
      }
    }
  }

  // ─────────────────────────────── Data ────────────────────────────────────

  Future<void> _initData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final cats = await _repo.getCategorias(userId);
      if (mounted) {
        setState(() {
          _categorias = cats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────── Proximity ───────────────────────────────

  void _onProximityUpdate() {
    final pos = ProximityService().currentPosition;
    if (pos == null || !mounted) return;

    setState(() {
      _userLocation = LocationPoint(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      final isNear = _puntos.any((p) =>
          !p.visitado && _distanceTo(p) <= 8.0); // 8m: same as unlock threshold
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

    if (!_hasCenteredOnUser && _mapboxMap != null && _userLocation != null) {
      _hasCenteredOnUser = true;
      unawaited(
        _centerMap(requestLocationIfMissing: false, showError: false),
      );
    }
  }

  void _startProximityVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer =
        Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
      if (!_isNearAnyUnvisited) {
        timer.cancel();
        return;
      }
      if ((await Vibration.hasVibrator()) == true) {
        Vibration.vibrate(pattern: [0, 100, 200, 100]);
      }

      if (mounted) {
        final nearPoi = ProximityService().nearPOI;
        final name = nearPoi?.nombre ?? 'un punto';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                  '¡Estás muy cerca de $name! 📍 Tócalo en el mapa para desbloquearlo y obtener tu recompensa.'),
              duration: const Duration(milliseconds: 1900),
              backgroundColor: AppColors.secondaryMain,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
      }
    });
  }

  void _updatePulseLayer() async {
    if (_mapboxMap == null || !_isNearAnyUnvisited) return;
    try {
      final pulse = _pulseController!.value;
      await _mapboxMap?.style.setStyleLayerProperty(
          'puntos-circles', 'circle-radius', (5.0 + pulse * 1.6).toString());
      await _mapboxMap?.style.setStyleLayerProperty('puntos-circles',
          'circle-stroke-width', (1.1 + pulse * 0.7).toString());
    } catch (_) {}
  }

  void _resetPulseLayer() async {
    try {
      await _mapboxMap?.style
          .setStyleLayerProperty('puntos-circles', 'circle-radius', '5.0');
      await _mapboxMap?.style.setStyleLayerProperty(
          'puntos-circles', 'circle-stroke-width', '1.1');
    } catch (_) {}
  }

  double _distanceTo(PuntoDeInteres p) {
    if (_userLocation == null) return double.infinity;
    return geo.Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      p.latitud,
      p.longitud,
    );
  }

  // ─────────────────────────────── Map ─────────────────────────────────────

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
      ),
    );
    unawaited(_centerMap(requestLocationIfMissing: false, showError: false));
  }

  void _onStyleLoaded(StyleLoadedEventData _) {
    _prepareMapStyle();
  }

  Future<void> _prepareMapStyle() async {
    if (_mapboxMap == null) return;
    try {
      await registerMapIcons(_mapboxMap!);
      await _loadCircleLayer();
    } catch (_) {}
  }

  Future<void> _loadCircleLayer() async {
    if (_mapboxMap == null) return;
    try {
      try {
        await _mapboxMap!.style.removeStyleLayer('puntos-symbols');
      } catch (_) {}
      try {
        await _mapboxMap!.style.removeStyleLayer('puntos-circles');
      } catch (_) {}
      try {
        await _mapboxMap!.style.removeStyleSource('puntos');
      } catch (_) {}

      final features = _puntos
          .map((p) => {
                'type': 'Feature',
                'geometry': {
                  'type': 'Point',
                  'coordinates': [p.longitud, p.latitud]
                },
                'properties': {
                  'id': p.id,
                  'nombre': p.nombre,
                  'categoria': p.categoria,
                  'imagesUrls': p.imagesUrls,
                  'visitado': p.visitado,
                },
              } as Map<String, dynamic>)
          .toList();

      await _mapboxMap!.style.addSource(
        GeoJsonSource(id: 'puntos', data: buildGeoJson(features)),
      );
      await _mapboxMap!.style.addStyleLayer(buildCircleLayerJson(), null);
      await _mapboxMap!.style.addStyleLayer(buildSymbolLayerJson(), null);
    } catch (_) {}
  }

  Future<void> _centerMap({
    bool requestLocationIfMissing = true,
    bool showError = true,
  }) async {
    final map = _mapboxMap;
    if (map == null) return;

    LocationPoint? target = _userLocation;
    final streamPosition = ProximityService().currentPosition;
    if (target == null && streamPosition != null) {
      target = LocationPoint(
        latitude: streamPosition.latitude,
        longitude: streamPosition.longitude,
      );
      if (mounted) setState(() => _userLocation = target);
    }

    if (target == null && requestLocationIfMissing) {
      try {
        final current = await _repo.getCurrentLocation();
        if (!mounted) return;
        setState(() => _userLocation = current);
        target = current;
      } catch (_) {
        if (showError && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo centrar. Verifica permiso de ubicación y GPS.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    if (target == null) return;

    final camera = CameraOptions(
      center: Point(
        coordinates: Position(target.longitude, target.latitude),
      ),
      zoom: 18.5,
      bearing: 0,
      pitch: 0,
    );

    try {
      await map.flyTo(
        camera,
        MapAnimationOptions(duration: 1100, startDelay: 0),
      );
    } catch (_) {
      map.setCamera(camera);
    }
  }

  // ─────────────────────────────── Tap / Unlock ────────────────────────────

  void _onMapTap(MapContentGestureContext context) async {
    if (_mapboxMap == null) return;
    try {
      final features = await _mapboxMap!.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(context.touchPosition),
        RenderedQueryOptions(layerIds: ['puntos-symbols', 'puntos-circles']),
      );
      if (features.isEmpty) return;

      final propsRaw = features.first?.queriedFeature.feature['properties'];
      if (propsRaw == null) return;
      final props = propsRaw as Map<Object?, Object?>;
      final id = (props['id'] as num?)?.toInt();
      if (id == null || _puntos.isEmpty) return;

      final punto =
          _puntos.firstWhere((p) => p.id == id, orElse: () => _puntos.first);
      _showPoiBottomSheet(punto);
    } catch (_) {}
  }

  void _showPoiBottomSheet(PuntoDeInteres punto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PoiBottomSheet(
        punto: punto,
        distanceMeters: _distanceTo(punto),
        onUnlock: () => _handleUnlock(punto),
      ),
    );
  }

  Future<void> _handleUnlock(PuntoDeInteres punto) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    if (mounted) Navigator.of(context).pop();

    try {
      if ((await Vibration.hasVibrator()) == true) {
        Vibration.vibrate(duration: 500);
      }
      final pointsEarned = await _unlockPoi(userId, punto.id);
      await ProximityService().refreshPuntos();
      if (mounted && _mapboxMap != null) {
        await _loadCircleLayer();
      }

      if (mounted) {
        await Navigator.of(context).push(PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => PoiUnlockCard(
            punto: _puntos.firstWhere((p) => p.id == punto.id),
            pointsEarned: pointsEarned,
            onClose: () => Navigator.of(context).pop(),
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al desbloquear: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  // ─────────────────────────────── Build ───────────────────────────────────

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
          if (!_isLoading)
            CategoryDropdown(
              selectedKey: _selectedCategoria,
              categorias: _categorias,
              onChanged: _onCategoryChanged,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : MapWidget(
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: _onStyleLoaded,
              onTapListener: _onMapTap,
              cameraOptions: CameraOptions(
                center: _userLocation != null
                    ? Point(
                        coordinates: Position(
                          _userLocation!.longitude,
                          _userLocation!.latitude,
                        ),
                      )
                    : Point(coordinates: Position(-75.589, 6.273)),
                zoom: 15.0,
              ),
              styleUri: MapboxStyles.MAPBOX_STREETS,
            ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: 72 + MediaQuery.paddingOf(context).bottom,
        ),
        child: FloatingActionButton(
          onPressed: () => _centerMap(),
          backgroundColor: AppColors.primaryMain,
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _onCategoryChanged(String? key) async {
    setState(() => _selectedCategoria = key);
    if (_mapboxMap != null) await _loadCircleLayer();
  }
}

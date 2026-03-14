import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/usecases/get_user_location.dart';
import '../../domain/entities/punto_de_interes.dart';
import '../../domain/entities/categoria.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../domain/entities/location_point.dart';
import '../../domain/usecases/get_puntos_con_visita.dart';
import '../../domain/usecases/get_categorias.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _mapboxMap;
  LocationPoint? userLocation;
  bool isLoading = true;

  List<PuntoDeInteres> _puntos = [];
  List<Categoria> _categorias = [];
  String? _selectedCategoria; // null = all

  final _repo = MapRepositoryImpl();
  late final GetUserLocation _getUserLocation;
  late final GetPuntosConVisita _getPuntosConVisita;
  late final GetCategorias _getCategorias;

  static const Color _primaryMain = Color(0xFF171C8F);

  @override
  void initState() {
    super.initState();
    _getUserLocation = GetUserLocation(_repo);
    _getPuntosConVisita = GetPuntosConVisita(_repo);
    _getCategorias = GetCategorias(_repo);
    _initData();
  }

  Future<void> _initData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final [location, puntos, categorias] = await Future.wait([
        _getUserLocation(),
        _getPuntosConVisita(userId),
        _getCategorias(userId),
      ]);

      if (mounted) {
        setState(() {
          userLocation = location as LocationPoint?;
          _puntos = puntos as List<PuntoDeInteres>;
          _categorias = categorias as List<Categoria>;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    mapboxMap.location.updateSettings(LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
    ));
    _centerMap();
  }

  void _onStyleLoaded(StyleLoadedEventData _) {
    _loadCircleLayer();
  }

  List<PuntoDeInteres> get _filteredPuntos {
    if (_selectedCategoria == null) return _puntos;
    return _puntos.where((p) => p.categoria == _selectedCategoria).toList();
  }

  Future<void> _loadCircleLayer() async {
    if (_mapboxMap == null) return;
    try {
      // Remove old layers/sources if they exist (after category filter change)
      try {
        await _mapboxMap!.style.removeStyleLayer('puntos-circles');
      } catch (_) {}
      try {
        await _mapboxMap!.style.removeStyleSource('puntos');
      } catch (_) {}

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
          "circle-radius": 12,
          "circle-color": [
            "case",
            ["get", "visitado"],
            "#37C8BE",  // visited = teal
            "#1E3A8A",  // not visited = navy
          ],
          "circle-stroke-color": "#FFFFFF",
          "circle-stroke-width": 2,
          "circle-opacity": 0.9,
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
      final screenCoord = context.touchPosition;
      // Query for features near the tap
      final features = await _mapboxMap!.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(screenCoord),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => _PoiBottomSheet(punto: punto),
    );
  }

  void _centerMap() {
    if (_mapboxMap != null && userLocation != null) {
      _mapboxMap!.setCamera(CameraOptions(
        center: Point(
            coordinates: Position(userLocation!.longitude, userLocation!.latitude)),
        zoom: 15.0,
      ));
    }
  }

  Future<void> _onCategoryChanged(String? key) async {
    setState(() => _selectedCategoria = key);
    if (_mapboxMap != null) {
      await _loadCircleLayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Explorar'),
        backgroundColor: _primaryMain.withValues(alpha: 0.9),
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
                            userLocation!.longitude, userLocation!.latitude))
                    : Point(coordinates: Position(-75.589, 6.273)),
                zoom: 14.0,
              ),
              styleUri: MapboxStyles.MAPBOX_STREETS,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerMap,
        backgroundColor: _primaryMain,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem(value: null, child: Text('Todas')),
      ..._categorias.map((c) => DropdownMenuItem(value: c.key, child: Text(c.nombre))),
    ];

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedCategoria,
          dropdownColor: _primaryMain,
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

class _PoiBottomSheet extends StatelessWidget {
  final PuntoDeInteres punto;
  const _PoiBottomSheet({required this.punto});

  static const Color _primaryMain = Color(0xFF171C8F);
  static const Color _secondaryMain = Color(0xFF37C8BE);
  static const Color _textPrimary = Color(0xFF091436);
  static const Color _textSecondary = Color(0xFF6A7587);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header image
          if (punto.mainImageUrl != null && punto.mainImageUrl!.isNotEmpty)
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                punto.mainImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
            )
          else
            SizedBox(height: 180, child: _placeholder()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _secondaryMain.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        Categoria.humanNombre(punto.categoria),
                        style: const TextStyle(
                          color: Color(0xFF25B7AB),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (punto.visitado)
                      Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF37C8BE), size: 14),
                          SizedBox(width: 4),
                          Text('Visitado', style: TextStyle(color: Color(0xFF37C8BE), fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  punto.nombre,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${punto.campus} · ${punto.universidad}',
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (punto.descripcion != null && punto.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    punto.descripcion!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                      height: 1.45,
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

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171C8F), Color(0xFF37C8BE)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.place_rounded, color: Colors.white, size: 48),
      ),
    );
  }
}

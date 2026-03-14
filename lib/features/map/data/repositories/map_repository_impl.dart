import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/location_point.dart';
import '../../domain/entities/punto_de_interes.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<LocationPoint> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final position = await Geolocator.getCurrentPosition();
    return LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  Future<String> getPoisGeoJson() async {
    try {
      final response = await _supabase.rpc('get_puntos_geojson');
      if (response is String) {
        return response;
      }
      return jsonEncode(response);
    } catch (e) {
      return Future.error('Error fetching POIs GeoJSON: $e');
    }
  }

  @override
  Future<List<PuntoDeInteres>> getPuntosConVisita(String? userId) async {
    try {
      if (userId != null) {
        // For each row, visitado reflects if this specific user visited.
        // We need to filter by usuario_id for correct visitado value.
        // We use a subquery-style: get all puntos joined for this user.
        // The view has puntos * usuario_id from visitas join, so if we filter
        // by usuario_id we get only rows where they visited (visitado=true).
        // To get ALL puntos with correct visitado flag for a user, we need
        // a different approach: call the raw table instead.
        //
        // Workaround: fetch all puntos, fetch visitas for this user,
        // then combine client-side.
        final [puntosRes, visitasRes] = await Future.wait([
          _supabase.from('puntos_de_interes').select(),
          _supabase
              .from('visitas')
              .select('punto_id')
              .eq('usuario_id', userId),
        ]);

        final visitadosIds = (visitasRes as List)
            .map((v) => (v['punto_id'] as num).toInt())
            .toSet();

        return (puntosRes as List).map((row) {
          final map = Map<String, dynamic>.from(row as Map);
          map['visitado'] = visitadosIds.contains((map['id'] as num).toInt());
          return PuntoDeInteres.fromMap(map);
        }).toList();
      }

      // No user: return all puntos without visita info
      final res = await _supabase.from('puntos_de_interes').select();
      return (res as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        map['visitado'] = false;
        return PuntoDeInteres.fromMap(map);
      }).toList();
    } catch (e) {
      return Future.error('Error fetching puntos: $e');
    }
  }

  @override
  Future<List<Categoria>> getCategorias(String? userId) async {
    try {
      final puntos = await getPuntosConVisita(userId);

      // Group by category key
      final Map<String, List<PuntoDeInteres>> grouped = {};
      for (final p in puntos) {
        grouped.putIfAbsent(p.categoria, () => []).add(p);
      }

      return grouped.entries.map((entry) {
        final key = entry.key;
        final list = entry.value;
        final visitados = list.where((p) => p.visitado).length;
        final imageUrl = list.firstWhere(
          (p) => p.mainImageUrl != null,
          orElse: () => list.first,
        ).mainImageUrl;

        return Categoria(
          key: key,
          nombre: Categoria.humanNombre(key),
          imageUrl: imageUrl,
          totalPuntos: list.length,
          visitados: visitados,
        );
      }).toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
    } catch (e) {
      return Future.error('Error fetching categories: $e');
    }
  }
}

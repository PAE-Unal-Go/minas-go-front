import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/answer_validation_result.dart';
import '../../domain/entities/location_point.dart';
import '../../domain/entities/punto_de_interes.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  final _supabase = Supabase.instance.client;

  int _parseIntScalar(dynamic res, {required String rpcName}) {
    if (res == null) return 0;
    if (res is int) return res;
    if (res is num) return res.toInt();
    if (res is String) return int.tryParse(res.trim()) ?? 0;
    if (res is List) {
      if (res.isEmpty) return 0;
      return _parseIntScalar(res.first, rpcName: rpcName);
    }
    if (res is Map) {
      final map = Map<String, dynamic>.from(res);

      for (final key in [
        'value',
        'result',
        rpcName,
        'puntos_totales',
        'total',
        'puntos',
        'total_points',
        'totalPoints',
        'sum',
      ]) {
        if (map.containsKey(key)) {
          return _parseIntScalar(map[key], rpcName: rpcName);
        }
      }

      // If it's a single-entry map, use its only value.
      if (map.length == 1) {
        return _parseIntScalar(map.values.first, rpcName: rpcName);
      }

      // Otherwise, try the first parseable scalar value.
      for (final value in map.values) {
        try {
          return _parseIntScalar(value, rpcName: rpcName);
        } catch (_) {
          // ignore
        }
      }
    }
    throw FormatException('Respuesta inesperada de RPC $rpcName: ${res.runtimeType}');
  }

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
  Future<PuntoDeInteres> getPuntoById(int id) async {
    try {
      final res = await _supabase
          .from('puntos_de_interes')
          .select()
          .eq('id', id)
          .single();
      final map = Map<String, dynamic>.from(res);
      map['visitado'] = true;
      return PuntoDeInteres.fromMap(map);
    } catch (e) {
      return Future.error('Error fetching punto by id: $e');
    }
  }

  @override
  Future<List<Categoria>> getCategorias(String? userId) async {
    try {
      final puntos = await getPuntosConVisita(userId);

      final Map<String, List<PuntoDeInteres>> grouped = {};
      for (final p in puntos) {
        grouped.putIfAbsent(p.categoria, () => []).add(p);
      }

      return grouped.entries.map((entry) {
        final key = entry.key;
        final list = entry.value;
        final visitados = list.where((p) => p.visitado).length;
        final imageUrl = list
            .expand((p) => p.imagesUrls)
            .map((url) => url.trim())
            .firstWhere((url) => url.isNotEmpty, orElse: () => '');

        return Categoria(
          key: key,
          nombre: Categoria.humanNombre(key),
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          totalPuntos: list.length,
          visitados: visitados,
        );
      }).toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
    } catch (e) {
      return Future.error('Error fetching categories: $e');
    }
  }

  @override
  Future<int> unlockPoi(String userId, int puntoId) async {
    try {
      final res = await _supabase.rpc(
        'registrar_visita',
        params: {
          'p_usuario': userId,
          'p_punto': puntoId,
        },
      );
      if (res == null) return 0;
      final map = res is Map
          ? Map<String, dynamic>.from(res)
          : (res is List && res.isNotEmpty && res.first is Map)
              ? Map<String, dynamic>.from(res.first as Map)
              : null;
      if (map == null) return 0;
      for (final key in ['puntos_ganados', 'puntos', 'points_earned', 'points']) {
        if (map.containsKey(key)) {
          final v = map[key];
          if (v is int) return v;
          if (v is num) return v.toInt();
          if (v is String) return int.tryParse(v) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      return Future.error('Error al desbloquear punto: $e');
    }
  }

  @override
  Future<QuizQuestion?> getQuestionForVisitedPoints(String userId) async {
    try {
      final res = await _supabase.rpc(
        'get_question_for_visited_points',
        params: {
          'p_usuario_id': userId,
        },
      );

      if (res == null) return null;

      if (res is List) {
        if (res.isEmpty) return null;
        final row = Map<String, dynamic>.from(res.first as Map);
        return QuizQuestion.fromMap(row);
      }

      if (res is Map) {
        return QuizQuestion.fromMap(Map<String, dynamic>.from(res));
      }

      return Future.error('Respuesta inesperada de RPC get_question_for_visited_points: ${res.runtimeType}');
    } catch (e) {
      return Future.error('Error fetching quiz question: $e');
    }
  }

  @override
  Future<AnswerValidationResult> validateAnswer({
    required String userId,
    required int preguntaId,
    required int selectedIndex,
  }) async {
    try {
      final res = await _supabase.rpc(
        'validate_answer',
        params: {
          'p_usuario_id': userId,
          'p_pregunta_id': preguntaId,
          'p_index_elegido': selectedIndex,
        },
      );

      if (res is List) {
        if (res.isEmpty) {
          return const AnswerValidationResult(correct: false, pointsEarned: 0);
        }
        return AnswerValidationResult.fromMap(
          Map<String, dynamic>.from(res.first as Map),
        );
      }

      if (res is Map) {
        return AnswerValidationResult.fromMap(Map<String, dynamic>.from(res));
      }

      return Future.error('Respuesta inesperada de RPC validate_answer: ${res.runtimeType}');
    } catch (e) {
      return Future.error('Error validating answer: $e');
    }
  }

  @override
  Future<int> getUserTotalPoints(String userId) async {
    const rpcName = 'get_user_total_points';
    try {
      final res = await _supabase.rpc(
        rpcName,
        params: {
          'p_usuario': userId,
        },
      );

      final rpcPoints = _parseIntScalar(res, rpcName: rpcName);
      if (rpcPoints != 0) return rpcPoints;

      // Fallback to the user profile total points if the RPC returns 0.
      // This covers the common case where the backend points source differs
      try {
        final profileRes = await _supabase
            .from('usuarios')
            .select('puntos_totales')
            .eq('id', userId)
            .limit(1);

        if (profileRes.isNotEmpty) {
          final row = Map<String, dynamic>.from(profileRes.first as Map);
          final value = row['puntos_totales'];
          return _parseIntScalar(value, rpcName: 'usuarios.puntos_totales');
        }
      } catch (_) {
      }

      return rpcPoints;
    } catch (e) {
      return Future.error('Error fetching user total points: $e');
    }
  }
}

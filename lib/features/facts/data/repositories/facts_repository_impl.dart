import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/university_fact.dart';
import '../../domain/repositories/facts_repository.dart';

class FactsRepositoryImpl implements FactsRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<UniversityFact>> getUnlockedFacts(String userId) async {
    try {
      final res = await _supabase.rpc(
        'get_datos_desbloqueados_usuario',
        params: {'p_usuario_id': userId},
      );
      if (res == null) return [];
      final list = res is List ? res : [res];
      if (list.isEmpty) return [];
      return list
          .map((row) =>
              UniversityFact.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      return Future.error('Error al cargar datos: $e');
    }
  }

  @override
  Future<UniversityFact?> tryUnlockFact(String userId) async {
    try {
      final res = await _supabase.rpc(
        'desbloquear_dato_random',
        params: {'p_usuario_id': userId},
      );
      if (res == null) return null;

      final map = switch (res) {
        Map() => Map<String, dynamic>.from(res),
        List(isNotEmpty: true) when res.first is Map =>
          Map<String, dynamic>.from(res.first as Map),
        _ => null,
      };

      if (map == null || map['desbloqueado'] == false) return null;
      if (!map.containsKey('titulo')) return null;

      return UniversityFact.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> getVisitCount(String userId) async {
    try {
      final res = await _supabase
          .from('visitas')
          .select('punto_id')
          .eq('usuario_id', userId);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }
}

import '../entities/location_point.dart';
import '../entities/punto_de_interes.dart';
import '../entities/categoria.dart';
import '../entities/answer_validation_result.dart';
import '../entities/quiz_question.dart';

abstract class MapRepository {
  Future<LocationPoint> getCurrentLocation();
  Future<String> getPoisGeoJson();
  Future<List<PuntoDeInteres>> getPuntosConVisita(String? userId);
  Future<List<Categoria>> getCategorias(String? userId);
  /// RPC: registrar_visita(p_usuario, p_punto)
  /// Registers the visit and returns points earned from the unlock.
  Future<int> unlockPoi(String userId, int puntoId);

  /// RPC: get_question_for_visited_points(p_usuario_id)
  /// Returns a random quiz question related to points visited by the user
  /// and not yet answered correctly (puntos_ganados > 0).
  Future<QuizQuestion?> getQuestionForVisitedPoints(String userId);

  /// RPC: validate_answer(p_usuario_id, p_pregunta_id, p_index_elegido)
  /// Validates and persists an answer; may throw if the user already earned points.
  Future<AnswerValidationResult> validateAnswer({
    required String userId,
    required int preguntaId,
    required int selectedIndex,
  });

  /// RPC: get_user_total_points(p_usuario)
  /// Returns the total points earned by the user.
  Future<int> getUserTotalPoints(String userId);
}

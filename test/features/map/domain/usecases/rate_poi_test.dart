import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/features/map/domain/entities/answer_validation_result.dart';
import 'package:minasgo_frontend/features/map/domain/entities/categoria.dart';
import 'package:minasgo_frontend/features/map/domain/entities/location_point.dart';
import 'package:minasgo_frontend/features/map/domain/entities/punto_de_interes.dart';
import 'package:minasgo_frontend/features/map/domain/entities/quiz_question.dart';
import 'package:minasgo_frontend/features/map/domain/repositories/map_repository.dart';
import 'package:minasgo_frontend/features/map/domain/usecases/rate_poi.dart';

class _Repo implements MapRepository {
  (String, int, int)? captured;

  @override
  Future<void> ratePoi(String userId, int puntoId, int calificacion) async {
    captured = (userId, puntoId, calificacion);
  }

  @override
  Future<int> unlockPoi(String userId, int puntoId, {int? calificacion}) =>
      throw UnimplementedError();
  @override
  Future<PuntoDeInteres> getPuntoById(int id) => throw UnimplementedError();
  @override
  Future<LocationPoint> getCurrentLocation() => throw UnimplementedError();
  @override
  Future<String> getPoisGeoJson() => throw UnimplementedError();
  @override
  Future<List<PuntoDeInteres>> getPuntosConVisita(String? userId) =>
      throw UnimplementedError();
  @override
  Future<List<Categoria>> getCategorias(String? userId) =>
      throw UnimplementedError();
  @override
  Future<QuizQuestion?> getQuestionForVisitedPoints(String userId) =>
      throw UnimplementedError();
  @override
  Future<AnswerValidationResult> validateAnswer({
    required String userId,
    required int preguntaId,
    required int selectedIndex,
  }) =>
      throw UnimplementedError();
  @override
  Future<int> getUserTotalPoints(String userId) => throw UnimplementedError();
}

void main() {
  group('RatePoi', () {
    test('forwards the rating to the repository', () async {
      final repo = _Repo();
      await RatePoi(repo)('user-1', 7, 5);
      expect(repo.captured, ('user-1', 7, 5));
    });

    test('rejects ratings outside 1-5', () {
      final rate = RatePoi(_Repo());
      expect(() => rate('u', 1, 0), throwsArgumentError);
      expect(() => rate('u', 1, 6), throwsArgumentError);
    });
  });
}

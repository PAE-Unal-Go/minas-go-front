import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/features/map/domain/entities/answer_validation_result.dart';
import 'package:minasgo_frontend/features/map/domain/entities/categoria.dart';
import 'package:minasgo_frontend/features/map/domain/entities/location_point.dart';
import 'package:minasgo_frontend/features/map/domain/entities/punto_de_interes.dart';
import 'package:minasgo_frontend/features/map/domain/entities/quiz_question.dart';
import 'package:minasgo_frontend/features/map/domain/repositories/map_repository.dart';
import 'package:minasgo_frontend/features/map/domain/usecases/unlock_poi.dart';

class FakeMapRepository implements MapRepository {
  String? capturedUserId;
  int? capturedPuntoId;
  int? capturedCalificacion;
  final int pointsToReturn;

  FakeMapRepository({this.pointsToReturn = 10});

  @override
  Future<int> unlockPoi(String userId, int puntoId, {int? calificacion}) async {
    capturedUserId = userId;
    capturedPuntoId = puntoId;
    capturedCalificacion = calificacion;
    return pointsToReturn;
  }

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
  group('UnlockPoi', () {
    test('passes the calificacion through to the repository', () async {
      final repo = FakeMapRepository(pointsToReturn: 25);
      final unlockPoi = UnlockPoi(repo);

      final points = await unlockPoi('user-1', 42, calificacion: 4);

      expect(points, 25);
      expect(repo.capturedUserId, 'user-1');
      expect(repo.capturedPuntoId, 42);
      expect(repo.capturedCalificacion, 4);
    });

    test('defaults calificacion to null when not provided', () async {
      final repo = FakeMapRepository();
      final unlockPoi = UnlockPoi(repo);

      await unlockPoi('user-1', 42);

      expect(repo.capturedCalificacion, isNull);
    });
  });
}

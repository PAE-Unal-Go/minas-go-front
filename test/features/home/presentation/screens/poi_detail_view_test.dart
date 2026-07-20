import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minasgo_frontend/features/home/presentation/screens/poi_detail_view.dart';
import 'package:minasgo_frontend/features/map/domain/entities/answer_validation_result.dart';
import 'package:minasgo_frontend/features/map/domain/entities/categoria.dart';
import 'package:minasgo_frontend/features/map/domain/entities/location_point.dart';
import 'package:minasgo_frontend/features/map/domain/entities/punto_de_interes.dart';
import 'package:minasgo_frontend/features/map/domain/entities/quiz_question.dart';
import 'package:minasgo_frontend/features/map/domain/repositories/map_repository.dart';

class FakeMapRepository implements MapRepository {
  final PuntoDeInteres Function(int id) onGetPuntoById;

  FakeMapRepository(this.onGetPuntoById);

  @override
  Future<PuntoDeInteres> getPuntoById(int id) async => onGetPuntoById(id);

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
  Future<int> unlockPoi(String userId, int puntoId) =>
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

PuntoDeInteres _punto({required String rarity, double? calificacion}) =>
    PuntoDeInteres(
      id: 1,
      nombre: 'Plaza Central',
      descripcion: 'Una plaza',
      categoria: 'historico',
      campus: 'El Volador',
      universidad: 'UNAL Medellín',
      latitud: 6.25,
      longitud: -75.57,
      visitado: true,
      rarity: rarity,
      calificacionPromedio: calificacion,
    );

Widget _wrap(PuntoDeInteres punto) => MaterialApp(
      home: PoiDetailView(
        punto: punto,
        categoryName: 'Histórico',
        pointName: punto.nombre,
        pointDescription: punto.descripcion ?? '',
      ),
    );

void main() {
  group('PoiDetailView rating badge', () {
    testWidgets('shows the rating on the basic (singular) card', (tester) async {
      await tester.pumpWidget(_wrap(_punto(rarity: 'singular', calificacion: 4.5)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('4.5'), findsOneWidget);
    });

    testWidgets('shows the rating on the important (epic) card', (tester) async {
      await tester.pumpWidget(_wrap(_punto(rarity: 'epic', calificacion: 3.2)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3.2'), findsOneWidget);

      // Flush the 3s shimmer fade-out delay scheduled in initState.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('shows the rating on the legendary card', (tester) async {
      await tester.pumpWidget(_wrap(_punto(rarity: 'legendary', calificacion: 5.0)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('5.0'), findsOneWidget);

      // Flush the 3s shimmer fade-out delay scheduled in initState.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('shows "Sin calificar" when there is no rating yet',
        (tester) async {
      await tester.pumpWidget(_wrap(_punto(rarity: 'singular', calificacion: null)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sin calificar'), findsOneWidget);
    });

    testWidgets('does not show a rating badge on the locked card',
        (tester) async {
      const locked = PuntoDeInteres(
        id: 2,
        nombre: 'Zona Oculta',
        categoria: 'historico',
        campus: 'El Volador',
        universidad: 'UNAL Medellín',
        latitud: 6.25,
        longitud: -75.57,
        visitado: false,
        calificacionPromedio: 4.9,
      );

      await tester.pumpWidget(_wrap(locked));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('4.9'), findsNothing);
      expect(find.text('Sin calificar'), findsNothing);
    });
  });

  group('PoiDetailView pull-to-refresh', () {
    testWidgets('refreshing re-fetches the punto and shows the new rating',
        (tester) async {
      final original = _punto(rarity: 'singular', calificacion: 3.0);
      final refreshed = PuntoDeInteres(
        id: original.id,
        nombre: original.nombre,
        descripcion: original.descripcion,
        categoria: original.categoria,
        campus: original.campus,
        universidad: original.universidad,
        latitud: original.latitud,
        longitud: original.longitud,
        visitado: true,
        rarity: original.rarity,
        calificacionPromedio: 4.8,
      );

      final fakeRepo = FakeMapRepository((id) => refreshed);

      await tester.pumpWidget(
        MaterialApp(
          home: PoiDetailView(
            punto: original,
            categoryName: 'Histórico',
            pointName: original.nombre,
            pointDescription: original.descripcion ?? '',
            repository: fakeRepo,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3.0'), findsOneWidget);

      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('keeps showing old data when the refresh fails',
        (tester) async {
      final original = _punto(rarity: 'singular', calificacion: 3.0);
      final fakeRepo = FakeMapRepository((id) => throw Exception('network'));

      await tester.pumpWidget(
        MaterialApp(
          home: PoiDetailView(
            punto: original,
            categoryName: 'Histórico',
            pointName: original.nombre,
            pointDescription: original.descripcion ?? '',
            repository: fakeRepo,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('3.0'), findsOneWidget);
    });
  });
}
